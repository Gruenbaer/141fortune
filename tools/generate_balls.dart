import 'dart:io';

void main() {
  // Solid balls 2-8
  final solidBalls = {
    2: {'color': '#1E90FF', 'name': 'blue'},
    3: {'color': '#DC143C', 'name': 'red'},
    4: {'color': '#8B008B', 'name': 'purple'},
    5: {'color': '#FF8C00', 'name': 'orange'},
    6: {'color': '#228B22', 'name': 'green'},
    7: {'color': '#8B4513', 'name': 'brown'},
    8: {'color': '#000000', 'name': 'black'},
  };

  for (var entry in solidBalls.entries) {
    final num = entry.key;
    final color = entry.value['color']!;
    final name = entry.value['name']!;
    
    final svg = generateSolidBall(num, color);
    File('assets/svg/ball_${num}_$name.svg').writeAsStringSync(svg);
  }

  // Striped balls 9-15
  final stripedBalls = {
    9: {'color': '#FFD700', 'name': 'yellow'},
    10: {'color': '#1E90FF', 'name': 'blue'},
    11: {'color': '#DC143C', 'name': 'red'},
    12: {'color': '#8B008B', 'name': 'purple'},
    13: {'color': '#FF8C00', 'name': 'orange'},
    14: {'color': '#228B22', 'name': 'green'},
    15: {'color': '#8B4513', 'name': 'brown'},
  };

  for (var entry in stripedBalls.entries) {
    final num = entry.key;
    final color = entry.value['color']!;
    final name = entry.value['name']!;
    
    final svg = generateStripedBall(num, color);
    File('assets/svg/ball_${num}_$name.svg').writeAsStringSync(svg);
  }
}

String generateSolidBall(int number, String color) {
  final lighter = adjustColor(color, 0.2);
  final darker = adjustColor(color, -0.3);
  
  return '''<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="50" cy="92" rx="35" ry="8" fill="rgba(0,0,0,0.3)" filter="blur(4px)"/>
  <defs>
    <radialGradient id="grad$number" cx="40%" cy="40%">
      <stop offset="0%" style="stop-color:$lighter;stop-opacity:1" />
      <stop offset="70%" style="stop-color:$color;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$darker;stop-opacity:1" />
    </radialGradient>
  </defs>
  <circle cx="50" cy="50" r="40" fill="url(#grad$number)" stroke="#000" stroke-width="0.5"/>
  <circle cx="50" cy="50" r="16" fill="white" opacity="1"/>
  <text x="50" y="50" font-family="Arial, sans-serif" font-size="${number == 8 ? 26 : 28}" font-weight="bold" fill="${number == 8 ? 'white' : 'black'}" text-anchor="middle" dominant-baseline="central">$number</text>
  <defs>
    <radialGradient id="highlight$number">
      <stop offset="0%" style="stop-color:white;stop-opacity:0.9" />
      <stop offset="100%" style="stop-color:white;stop-opacity:0" />
    </radialGradient>
  </defs>
  <ellipse cx="38" cy="32" rx="12" ry="16" fill="url(#highlight$number)" opacity="0.8"/>
</svg>''';
}

String generateStripedBall(int number, String stripeColor) {
  return '''<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="50" cy="92" rx="35" ry="8" fill="rgba(0,0,0,0.3)" filter="blur(4px)"/>
  <defs>
    <radialGradient id="whiteGrad$number" cx="40%" cy="40%">
      <stop offset="0%" style="stop-color:#FFFFFF;stop-opacity:1" />
      <stop offset="70%" style="stop-color:#F5F5F5;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#D3D3D3;stop-opacity:1" />
    </radialGradient>
  </defs>
  <circle cx="50" cy="50" r="40" fill="url(#whiteGrad$number)" stroke="#CCC" stroke-width="0.5"/>
  <defs>
    <clipPath id="clip$number">
      <circle cx="50" cy="50" r="40"/>
    </clipPath>
  </defs>
  <g clip-path="url(#clip$number)">
    <rect x="10" y="30" width="80" height="40" fill="$stripeColor"/>
  </g>
  <circle cx="50" cy="50" r="16" fill="white"/>
  <text x="50" y="50" font-family="Arial, sans-serif" font-size="26" font-weight="bold" fill="black" text-anchor="middle" dominant-baseline="central">$number</text>
  <defs>
    <radialGradient id="highlight$number">
      <stop offset="0%" style="stop-color:white;stop-opacity:0.95" />
      <stop offset="100%" style="stop-color:white;stop-opacity:0" />
    </radialGradient>
  </defs>
  <ellipse cx="38" cy="32" rx="14" ry="18" fill="url(#highlight$number)" opacity="0.7"/>
</svg>''';
}

String adjustColor(String hex, double factor) {
  // Simple color adjustment
  return hex;
}
