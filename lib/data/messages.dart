import 'dart:math';

class EasterEggs {
  static const List<String> breakFoulMessages = [
    "Dude... the 15!",
    "Not that one.",
    "Try Ball 15.",
    "Seriously? 15!",
    "One job: The 15.",
    "You're testing me.",
    "Wrong ball!",
    "Left? Right? No, 15.",
    "Focus, please.",
    "Honey, no.",
    "Are you blind?",
    "Click the 15.",
    "Nope. Still 15.",
    "Reading is hard?",
    "It's the stripes.",
    "Error 404: 15 Missing.",
    "My grandma knows better.",
    "Just the 15.",
    "Why are you like this?",
    "Last warning: 15."
  ];

  static String getRandomBreakFoulMessage() {
    return breakFoulMessages[Random().nextInt(breakFoulMessages.length)];
  }
}
