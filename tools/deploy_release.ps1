# Deploy Release Script for Fortune 14/2
# Automates: Build APK -> GitHub Release -> WhatsApp Notification

$ErrorActionPreference = "Stop"

# Define Flutter Path (Using Puro first, fallback to standard Flutter)
# First try to use Puro
if (Get-Command "puro" -ErrorAction SilentlyContinue) {
    $flutterBin = "puro"
    $flutterCmd = "flutter"
}
else {
    # Fallback to hardcoded path
    $flutterBin = "C:\Users\Emili\.gemini\flutter\bin\flutter.bat"
    $flutterCmd = ""
    if (-not (Test-Path $flutterBin)) {
        # Final fallback to PATH
        $flutterBin = "flutter"
    }
}

# 1. Extract Version from pubspec.yaml
Write-Host "Checking version in pubspec.yaml..." -ForegroundColor Cyan
$pubspec = Get-Content "pubspec.yaml"
$versionLine = $pubspec | Select-String "version: " | Select-Object -First 1
if (-not $versionLine) {
    Write-Error "Could not find version in pubspec.yaml"
}
$fullVersion = $versionLine.ToString().Split(":")[1].Trim()
$version = $fullVersion.Split("+")[0] # Remove build number if present
Write-Host "   Detected Version: $version" -ForegroundColor Green

# 1b. Ask for Web Deployment
$deployWeb = Read-Host "Deploy Web to knthlz.de? (y/n) [n]"
if ($deployWeb -eq 'y') {
    Write-Host "Building Web Release..." -ForegroundColor Cyan
    if ($flutterCmd) {
        & $flutterBin $flutterCmd build web --release
    }
    else {
        & $flutterBin build web --release
    }
    if ($LASTEXITCODE -ne 0) { throw "Web Build Failed" }

    Write-Host "Uploading to w01cdf36.kasserver.com..." -ForegroundColor Cyan
    # Credentials
    $webUser = "ssh-w0208b4b"
    $webHost = "w01cdf36.kasserver.com"
    $webPw = "6zU3RW!6rmbffb95S#"
    $remotePath = "knthlz.de/" 
    
    # Check for pscp
    if (Get-Command "pscp" -ErrorAction SilentlyContinue) {
        # Upload contents of build/web/* to remote directory
        # -r for recursive, -batch to disable interactive prompts
        # Note: pscp arguments order: [options] source [source...] [user@]host:target
        
        Write-Host "   Using pscp to upload..."
        # We need to upload the CONTENTS of the folder, not the folder itself, or correct the path.
        # pscp build/web/* ... usually works in shell, but PowerShell globbing might need care.
        # Easier to copy the folder and rename or just copy contents.
        # Using -r build/web will create 'web' directory on remote if we are not careful.
        # We want contents of build/web to go to knthlz.de/
        
        # Best way with pscp: upload the directory 'web' to 'knthlz.de' and it might end up as 'knthlz.de/web'
        # To avoid that, we might need to upload * from inside.
        
        # Let's try uploading build/web/ to knthlz.de/ which usually puts 'web' inside.
        # Alternative: Deploy to knthlz.de/ (expecting it to be empty or root).
        
        # Command: pscp -r -pw ... build/web/ user@host:knthlz.de/
        # This will indeed put 'web' folder there typically.
        # Workaround: Upload individual files or use a wildcard if pscp supports it on windows source.
        # pscp build\web\* ... 
        
        $webBuildDir = "build\web\*"
        # Using invoking operator to handle arguments correctly
        & pscp -r -batch -pw $webPw $webBuildDir "${webUser}@${webHost}:${remotePath}"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Web Deployment Successful!" -ForegroundColor Green
        }
        else {
            Write-Error "   Web Deployment Failed (pscp exit code $LASTEXITCODE)"
        }
    }
    else {
        Write-Error "   'pscp' (Putty SCP) not found in PATH. Cannot upload files."
    }
}


# 2. Check if Tag Exists
$tagExists = git tag -l "v$version"
if ($tagExists) {
    Write-Warning "Tag v$version already exists!"
    $confirm = Read-Host "Continue anyway? (y/n)"
    if ($confirm -ne 'y') { exit }
}

# 3. Generate Changelog
Write-Host "Generating Changelog..." -ForegroundColor Cyan
# Get last tag (get the most recent tag by version, not by describe)
$lastTag = git tag --sort=-version:refname | Select-Object -First 1
if (-not $lastTag) { 
    # If no tags exist, use first commit
    $lastTag = git rev-list --max-parents=0 HEAD 
}

$commits = git log --oneline --no-merges "$lastTag..HEAD" | ForEach-Object { "- $_" }
Write-Host "   Changes since $lastTag :"
$commits | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

Write-Host "`nEdit Changelog (Press Enter to keep, type 'skip' to empty):"
$customNotes = Read-Host "   Summary/Highlighted Features"

if ($customNotes -eq "") {
    $releaseNotes = $commits -join "`n"
}
elseif ($customNotes -eq "skip") {
    $releaseNotes = ""
}
else {
    $releaseNotes = "$customNotes`n`nDetails:`n" + ($commits -join "`n")
}

# 4. Build APK
Write-Host "Building APK (Release Mode)..." -ForegroundColor Cyan
# Execute Flutter using Call Operator '&'
if ($flutterCmd) {
    & $flutterBin $flutterCmd build apk --release
}
else {
    & $flutterBin build apk --release
}
if ($LASTEXITCODE -ne 0) { throw "Build Failed" }

$apkPath = "build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $apkPath)) { throw "APK not found at $apkPath" }

# 5. Create GitHub Release
Write-Host "Publishing to GitHub..." -ForegroundColor Cyan
$notesFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $notesFile -Value $releaseNotes

try {
    # GH CLI usually in PATH
    cmd /c "gh release create v$version ""$apkPath"" --title ""v$version"" --notes-file ""$notesFile"""
}
finally {
    Remove-Item $notesFile
}

if ($LASTEXITCODE -ne 0) { throw "GitHub Release Failed" }

Write-Host "Release v$version Published!" -ForegroundColor Green

# 6. Messaging Notifications
Write-Host "Select platforms to announce release:" -ForegroundColor Cyan
Write-Host "1) WhatsApp ONLY (Default)"
Write-Host "2) Telegram"
Write-Host "3) Signal"
Write-Host "4) All of the above"
$platformChoice = Read-Host "Choice [1]"
if ($platformChoice -eq "") { $platformChoice = "1" }

$repoUrl = "https://github.com/Gruenbaer/141fortune"
$downloadUrl = "$repoUrl/releases/download/v$version/app-release.apk"

$notesText = "See GitHub for details"
if ($customNotes) {
    $notesText = $customNotes
}

# --- WhatsApp ---
if ($platformChoice -match "1|4") {
    Write-Host "Preparing WhatsApp..." -ForegroundColor Cyan
    $waMessage = "*Fortune 14/2 Update v$version is live!*`n`n"
    $waMessage += "*Whats New:*`n"
    $waMessage += "$notesText`n`n"
    $waMessage += "*Download:* $downloadUrl"

    $encodedWaMsg = [Uri]::EscapeDataString($waMessage)
    $waUrl = "whatsapp://send?text=$encodedWaMsg"
    Start-Process $waUrl
    Start-Sleep -Seconds 1
}

# --- Telegram ---
if ($platformChoice -match "2|4") {
    Write-Host "Preparing Telegram..." -ForegroundColor Cyan
    $tgMessage = "Fortune 14/2 Update v$version is live!`n`n"
    $tgMessage += "Whats New:`n"
    $tgMessage += "$notesText"
    # Telegram 'text' parameter is the message. 'url' is the preview link.
    
    $encodedTgMsg = [Uri]::EscapeDataString($tgMessage)
    $encodedUrl = [Uri]::EscapeDataString($downloadUrl)
    # https://t.me/share/url?url=<URL>&text=<TEXT>
    $tgUrl = "https://t.me/share/url?url=$encodedUrl&text=$encodedTgMsg"
    
    Start-Process $tgUrl
    Start-Sleep -Seconds 1
}

# --- Signal ---
if ($platformChoice -match "3|4") {
    Write-Host "Preparing Signal..." -ForegroundColor Cyan
    $sigMessage = "Fortune 14/2 Update v$version is live!`n`n"
    $sigMessage += "Whats New:`n"
    $sigMessage += "$notesText`n`n"
    $sigMessage += "Download: $downloadUrl"

    # Signal Desktop has no URI for text. We must use clipboard.
    Set-Clipboard -Value $sigMessage
    Write-Warning "Signal does not support automatic message filling."
    Write-Warning "The release message has been COPIED to your CLIPBOARD."
    Write-Host "1. Opening Signal..."
    Write-Host "2. Select your recipients."
    Write-Host "3. Paste (Ctrl+V) the message."
    
    # Try to open Signal Desktop. It might be in different spots or just 'signal' if in PATH.
    # Fallback to signal.me specific link just to trigger app open if possible, 
    # but strictly opening the app is hard without known path. 
    # We'll try user protocol if registered, or just let user open it.
    # signal.me links are usually for joining/contacting.
    
    # Attempt to launch via Protocol Handler 'signal://' does not usually work for 'open'.
    # We will try valid generic command or just instruct user.
    # But let's try opening the standard install path if it exists, or tell user.
    
    $signalPath = "$env:LOCALAPPDATA\Programs\signal-desktop\Signal.exe"
    if (Test-Path $signalPath) {
        Start-Process $signalPath
    }
    else {
        # Try generic shell open if protocol is registered (unlikely to just open app empty)
        # Just give feedback
        Write-Host "Could not auto-start Signal. Please open it manually." -ForegroundColor Yellow
    }
}

Write-Host "Done! Notifications prepared." -ForegroundColor Green
