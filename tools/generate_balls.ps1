# Generate all billiard ball SVGs

$balls = @(
    @{num=2; color='#1E90FF'; name='blue'; type='solid'},
    @{num=3; color='#DC143C'; name='red'; type='solid'},
    @{num=4; color='#8B008B'; name='purple'; type='solid'},
    @{num=5; color='#FF8C00'; name='orange'; type='solid'},
    @{num=6; color='#228B22'; name='green'; type='solid'},
    @{num=7; color='#8B4513'; name='brown'; type='solid'},
    @{num=9; color='#FFD700'; name='yellow'; type='striped'},
    @{num=10; color='#1E90FF'; name='blue'; type='striped'},
    @{num=11; color='#DC143C'; name='red'; type='striped'},
    @{num=12; color='#8B008B'; name='purple'; type='striped'},
    @{num=13; color='#FF8C00'; name='orange'; type='striped'},
    @{num=14; color='#228B22'; name='green'; type='striped'},
    @{num=15; color='#8B4513'; name='brown'; type='striped'}
)

foreach ($ball in $balls) {
    $num = $ball.num
    $color = $ball.color
    $name = $ball.name
    $type = $ball.type
    
    if ($type -eq 'solid') {
        $svg = @"
<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="grad$num" cx="40%" cy="40%">
      <stop offset="0%" style="stop-color:$color;stop-opacity:1" />
      <stop offset="70%" style="stop-color:$color;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$color;stop-opacity:0.7" />
    </radialGradient>
  </defs>
  <circle cx="50" cy="50" r="50" fill="url(#grad$num)" stroke="#000" stroke-width="0.5"/>
  <circle cx="50" cy="50" r="16" fill="white"/>
  <text x="50" y="50" font-family="Arial, sans-serif" font-size="28" font-weight="bold" fill="black" text-anchor="middle" dominant-baseline="central">$num</text>
  <defs>
    <radialGradient id="highlight$num">
      <stop offset="0%" style="stop-color:white;stop-opacity:0.9" />
      <stop offset="100%" style="stop-color:white;stop-opacity:0" />
    </radialGradient>
  </defs>
  <ellipse cx="38" cy="32" rx="12" ry="16" fill="url(#highlight$num)" opacity="0.8"/>
</svg>
"@
    } else {
        $svg = @"
<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="whiteGrad$num" cx="40%" cy="40%">
      <stop offset="0%" style="stop-color:#FFFFFF;stop-opacity:1" />
      <stop offset="70%" style="stop-color:#F5F5F5;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#D3D3D3;stop-opacity:1" />
    </radialGradient>
    <radialGradient id="colorGrad$num" cx="40%" cy="60%">
      <stop offset="0%" style="stop-color:$color;stop-opacity:1" />
      <stop offset="70%" style="stop-color:$color;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$color;stop-opacity:0.7" />
    </radialGradient>
    <clipPath id="clipTop$num">
      <rect x="0" y="0" width="100" height="50"/>
    </clipPath>
    <clipPath id="clipBottom$num">
      <rect x="0" y="50" width="100" height="50"/>
    </clipPath>
  </defs>
  
  <!-- Bottom half: colored -->
  <circle cx="50" cy="50" r="50" fill="url(#colorGrad$num)" clip-path="url(#clipBottom$num)"/>
  
  <!-- Top half: white -->
  <circle cx="50" cy="50" r="50" fill="url(#whiteGrad$num)" clip-path="url(#clipTop$num)" stroke="#CCC" stroke-width="0.5"/>
  
  <!-- Stroke for full circle -->
  <circle cx="50" cy="50" r="50" fill="none" stroke="#999" stroke-width="0.5"/>
  
  <!-- White number circle -->
  <circle cx="50" cy="50" r="16" fill="white"/>
  <text x="50" y="50" font-family="Arial, sans-serif" font-size="26" font-weight="bold" fill="black" text-anchor="middle" dominant-baseline="central">$num</text>
  
  <!-- Specular highlight -->
  <defs>
    <radialGradient id="highlight$num">
      <stop offset="0%" style="stop-color:white;stop-opacity:0.95" />
      <stop offset="100%" style="stop-color:white;stop-opacity:0" />
    </radialGradient>
  </defs>
  <ellipse cx="38" cy="32" rx="14" ry="18" fill="url(#highlight$num)" opacity="0.7"/>
</svg>
"@
    }
    
    $svg | Out-File -FilePath "assets\svg\ball_${num}_${name}.svg" -Encoding UTF8
}

Write-Host "Generated all billiard ball SVGs!"
