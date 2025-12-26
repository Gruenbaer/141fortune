# Script to build APK and prepare for GitHub Release
# 
# Usage:
#   1. Set your API key: $env:GEMINI_API_KEY = "your_new_key"
#   2. Set SMTP password: $env:SMTP_PASSWORD = "your_password"  
#   3. Run: .\build_scripts\build_and_release.ps1

param(
    [switch]$SkipBuild = $false
)

Write-Host "=== Fortune 14/1 - GitHub Release Builder ===" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
if (-not $env:GEMINI_API_KEY -and -not $SkipBuild) {
    Write-Host "GEMINI_API_KEY not found in environment." -ForegroundColor Yellow
    $env:GEMINI_API_KEY = Read-Host -Prompt "Enter Gemini API Key"
    if (-not $env:GEMINI_API_KEY) {
        Write-Host "ERROR: Key required for build." -ForegroundColor Red
        exit 1
    }
}

if (-not $env:SMTP_PASSWORD -and -not $SkipBuild) {
    Write-Host "SMTP_PASSWORD not found in environment." -ForegroundColor Yellow
    $env:SMTP_PASSWORD = Read-Host -Prompt "Enter SMTP Password"
    if (-not $env:SMTP_PASSWORD) {
        Write-Host "ERROR: Password required for build." -ForegroundColor Red
        exit 1
    }
}

# Build APK
if (-not $SkipBuild) {
    Write-Host "Building release APK..." -ForegroundColor Green
    & "$PSScriptRoot\build.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Check if APK exists
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "ERROR: APK not found at $apkPath" -ForegroundColor Red
    exit 1
}

$apkSize = (Get-Item $apkPath).Length / 1MB
Write-Host ""
Write-Host "✅ APK ready!" -ForegroundColor Green
Write-Host "   Location: $apkPath" -ForegroundColor Cyan
Write-Host "   Size: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Go to: https://github.com/Gruenbaer/141fortune/releases/new" -ForegroundColor White
Write-Host "   (The form should be pre-filled from the browser)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Drag and drop this APK into the 'Attach binaries' area:" -ForegroundColor White
Write-Host "   $apkPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Click 'Publish release'" -ForegroundColor White
Write-Host ""
Write-Host "Download URL will be:" -ForegroundColor Gray
Write-Host "https://github.com/Gruenbaer/141fortune/releases/download/v1.0.0/app-release.apk" -ForegroundColor Cyan
Write-Host ""

# Open the APK folder in Explorer
Write-Host "Opening APK folder..." -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "/select,$apkPath"
