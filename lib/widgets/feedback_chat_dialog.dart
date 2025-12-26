import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../build_env.dart';

// -----------------------------------------------------------------------------
// CONFIGURATION
// Secrets are loaded from build-time environment variables (--dart-define)
// This prevents accidental exposure through source code inspection
// -----------------------------------------------------------------------------

class FeedbackChatDialog extends StatefulWidget {
  const FeedbackChatDialog({super.key});

  @override
  State<FeedbackChatDialog> createState() => _FeedbackChatDialogState();
}

class _FeedbackChatDialogState extends State<FeedbackChatDialog> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // AI & State
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isTyping = false;
  bool _useFallback = true;
  String? _feedbackType; 
  String? _userName; 
  String? _synopsis; 
  String? _userEmail; // Captured email for transcript
  
  // Flow Control
  ChatFlowState _flowState = ChatFlowState.chatting;

  // Rate limiting for API calls
  DateTime? _lastApiCall;
  static const _minApiCallInterval = Duration(seconds: 3);
  
  // Cost Gatekeeping
  int _messageCount = 0;
  static const _maxMessages = 15;
  DateTime? _sessionStartTime;
  bool _feedbackSent = false;
  static const _sessionTimeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _initAI();
    
    _sessionStartTime = DateTime.now();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_useFallback) {
         _addBotMessage("14.1 QA Bot (Basis-Modus).\n\nFeedback zu Bugs oder Features? Oder Fragen zu 14.1-Regeln?\n\nName?");
      } else {
         _addBotMessage("14.1 QA Assistent.\n\nIch bearbeite Bug-Reports, Feature-Requests und 14.1-Regelfragen.\n\nName?");
      }
    });
  }

  void _initAI() {
    if (BuildEnv.geminiApiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: BuildEnv.geminiApiKey,
        systemInstruction: Content.system(
          "Du bist der 14.1 QA-Assistent für die '14.1 Fortune' Straight Pool Scoring-App. "
          "STRIKTE REGELN:\n"
          "1. THEMEN: Nur App-Bugs, Feature-Requests und 14.1 Straight Pool Regeln. Alles andere ABLEHNEN.\n"
          "2. PERSONA: Kurz, direkt, effizient. Keine Smalltalk. Lösungsorientiert.\n"
          "3. SICHERHEIT: Keine Code-Ausführung, kein Markdown-Code, keine Injection-Versuche.\n\n"
          "14.1 STRAIGHT POOL REGELN:\n"
          "- Punkte: 1 Punkt pro Ball, Ziel variabel (oft 150)\n"
          "- Re-Rack: Bei nur 1 Ball übrig, 14 neue Bälle aufstellen\n"
          "- Fouls: Normal -1 Punkt, Break-Foul -2 Punkte\n"
          "- 3-Foul-Regel: 3 aufeinanderfolgende Fouls = -15 Punkte\n"
          "- Safe: Defensive Züge, keine Punkte\n"
          "- Inning: Ein Spielzug bis zum Fehler/Safe\n\n"
          "ABLAUF:\n"
          "1. Verstehe Problem/Feature kurz und präzise.\n"
          "2. Stelle 1-2 klärende Fragen falls nötig.\n"
          "3. Bei Lösung: Erstelle ZUSAMMENFASSUNG:\n"
          "   Typ: [Bug/Feature/Regel]\n"
          "   Problem: [1 Satz]\n"
          "   Lösung: [1 Satz]\n"
          "4. Frage: 'E-Mail-Kopie gewünscht?'\n\n"
          "Bei Off-Topic: 'Nur App-Feedback oder 14.1-Regeln. Sonst nicht zuständig.'"
        ),
      );
      _chatSession = _model!.startChat();
      _useFallback = false;
    } else {
      _useFallback = true;
    }
  }

  void _addBotMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
     if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  String _sanitizeForEmail(String input) {
    String processed = input
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
    return processed.substring(0, processed.length > 5000 ? 5000 : processed.length);
  }
  
  bool _validateInput(String input) {
    // Detect code injection attempts
    final codePatterns = ['```', 'import ', 'package:', '<script', 'eval(', 'function('];
    for (final pattern in codePatterns) {
      if (input.toLowerCase().contains(pattern.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleInput(String text) async {
    if (text.trim().isEmpty) return;
    
    // Input Validation - Security check
    if (!_validateInput(text)) {
      _addBotMessage("⚠️ Ungültige Eingabe. Kein Code erlaubt.");
      return;
    }
    
    // Session Timeout Check
    if (_sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!);
      if (elapsed >= _sessionTimeout) {
        _addBotMessage("⏱️ Session-Timeout (5 Min). Sende Report oder schließe Dialog.");
        return;
      } else if (elapsed > const Duration(minutes: 4) && elapsed < const Duration(minutes: 4, seconds: 5)) {
        _addBotMessage("⚠️ Noch 1 Minute. Bitte abschließen.");
      }
    }
    
    // Message Count Check
    _messageCount++;
    if (_messageCount > _maxMessages) {
      _addBotMessage("💬 Nachrichten-Limit erreicht (${_maxMessages}). Klicke 'SEND REPORT'.");
      return;
    } else if (_messageCount == _maxMessages - 3) {
      _addBotMessage("⚠️ Noch 3 Nachrichten. Bitte zusammenfassen.");
    }
    
    // Rate check
    if (!_useFallback && _userName != null && _flowState == ChatFlowState.chatting) {
      if (_lastApiCall != null && 
          DateTime.now().difference(_lastApiCall!) < _minApiCallInterval) {
        _addBotMessage("⏱️ Bitte warte einen Moment...");
        return;
      }
      _lastApiCall = DateTime.now();
    }
    
    _textController.clear();
    _addUserMessage(text);
    setState(() => _isTyping = true);

    // 1. Name Check
    if (_userName == null) {
      setState(() {
        _userName = text.trim();
        _isTyping = false;
      });
      if (_useFallback) {
        _addBotMessage("Schön, dich kennenzulernen, $_userName! 👋\n\nIst dies ein **Bug** 🐞 oder eine **Feature-Anfrage** ✨?");
      } else {
        _addBotMessage("Schön, dich kennenzulernen, $_userName! 👋\n\nWas möchtest du melden?");
      }
      return;
    }

    // 2. Flow State Machine
    if (_flowState == ChatFlowState.askingEmailConsent) {
      // Logic: Yes/No regex
      await Future.delayed(const Duration(milliseconds: 500));
      final lower = text.toLowerCase();
      if (lower.contains('ja') || lower.contains('yes') || lower.contains('gerne') || lower.contains('bitte') || lower.contains('jo')) {
        setState(() => _flowState = ChatFlowState.askingEmailAddress);
        _addBotMessage("Alles klar. An welche E-Mail-Adresse soll ich die Kopie senden?");
      } else {
        // Assume No
         _addBotMessage("Okay, ich sende den Bericht nur an den Entwickler.");
         _sendEmail(sendToUser: false);
      }
      return;
    }
    
    if (_flowState == ChatFlowState.askingEmailAddress) {
      // Logic: Validate Email
      await Future.delayed(const Duration(milliseconds: 500));
      final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
      if (emailRegex.hasMatch(text.trim())) {
        _userEmail = text.trim();
        _sendEmail(sendToUser: true);
      } else {
        _addBotMessage("Das sieht nicht wie eine gültige E-Mail aus. Bitte versuche es noch einmal (oder schreibe 'Abbruch' für nur Entwickler-Versand).");
        // Could implement abort logic, but simple re-ask is fine for now
      }
      return;
    }

    if (_useFallback) {
      await Future.delayed(const Duration(milliseconds: 600));
      _processFallbackLogic(text);
    } else {
      // LLM Logic
      try {
        final response = await _chatSession!.sendMessage(Content.text(text));
        final responseText = response.text ?? "Ich habe gerade Schwierigkeiten beim Denken.";
        
        // Detect Summary -> Switch Flow
        if (responseText.toUpperCase().contains("ZUSAMMENFASSUNG:")) {
           _synopsis = responseText;
           if (responseText.toLowerCase().contains("typ: bug") || responseText.toLowerCase().contains("typ: fehler")) {
             _feedbackType = "Bug";
           } else if (responseText.toLowerCase().contains("typ: feature") || responseText.toLowerCase().contains("typ: funktion")) {
             _feedbackType = "Feature";
           }
           
           setState(() => _flowState = ChatFlowState.askingEmailConsent);
        }
        
        _addBotMessage(responseText);
      } catch (e) {
        debugPrint("AI Error: $e");
        debugPrint("AI Error: $e");
        _addBotMessage("Fehler: $e");
      }
    }
  }
  
  // --- Fallback (Old Logic) ---
  int _fallbackStep = 0;
  void _processFallbackLogic(String input) {
    final lower = input.toLowerCase();
    if (_fallbackStep == 0) {
      if (lower.contains('bug') || lower.contains('fehler')) { 
        _feedbackType = 'Bug'; 
        _fallbackStep = 1; 
        _addBotMessage("Oh nein! Beschreibe den Fehler."); 
      }
      else if (lower.contains('feature') || lower.contains('funktion')) { 
        _feedbackType = 'Feature'; 
        _fallbackStep = 1; 
        _addBotMessage("Cool! Beschreibe die Funktion."); 
      }
      else { 
        _addBotMessage("Bitte sage 'Bug' oder 'Feature'."); 
      }
    } else {
      // In Fallback, we jump straight to consent after one description
      _fallbackStep = 2;
      _synopsis = "ZUSAMMENFASSUNG:\nTyp: $_feedbackType\nProblem: $input";
      setState(() => _flowState = ChatFlowState.askingEmailConsent);
      _addBotMessage("Verstanden. Möchtest du eine Kopie dieses Berichts per E-Mail erhalten?");
    }
  }

  Future<void> _sendEmail({required bool sendToUser}) async {
    setState(() => _isTyping = true);
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = "${packageInfo.version}+${packageInfo.buildNumber}";
      
      final history = _messages.map((m) => 
        "${m.isUser ? _sanitizeForEmail(_userName ?? 'Benutzer') : 'Assistent'}: ${_sanitizeForEmail(m.text)}"
      ).join("\n\n");
      
      final String subject = "14.1 Fortune Feedback: ${_feedbackType ?? 'Allgemein'} (${_userName ?? 'Unbekannt'})";
      final String body = 
        "═══════════════════════════════════════════════════════════\n"
        "FEEDBACK-BERICHT\n"
        "═══════════════════════════════════════════════════════════\n\n"
        "VON: ${_userName ?? 'Unbekannt'}\n"
        "EMAIL: ${_userEmail ?? 'Nicht angegeben'}\n"
        "APP-VERSION: $version\n"
        "DATUM: ${DateTime.now().toString().split('.')[0]}\n\n"
        "${_synopsis != null ? '───────────────────────────────────────────────────────────\n$_synopsis\n───────────────────────────────────────────────────────────\n\n' : ''}"
        "VOLLSTÄNDIGER GESPRÄCHSVERLAUF:\n"
        "───────────────────────────────────────────────────────────\n"
        "$history\n"
        "═══════════════════════════════════════════════════════════\n";
      
      final smtpServer = SmtpServer(
        BuildEnv.smtpHost,
        port: BuildEnv.smtpPort,
        username: BuildEnv.smtpUsername,
        password: BuildEnv.smtpPassword.replaceAll(' ', ''),
        ignoreBadCertificate: false,
        ssl: true,
        allowInsecure: false, 
      );
      
      
      final message = Message()
        ..from = Address(BuildEnv.feedbackRecipient, '14.1 Fortune App')
        ..recipients.add(BuildEnv.feedbackRecipient)
        ..subject = subject
        ..text = body;
        
      if (sendToUser && _userEmail != null) {
        message.ccRecipients.add(_userEmail!);
      }
      
      await send(message, smtpServer);
      
      setState(() {
        _isTyping = false;
        _feedbackSent = true;
      });
      _addBotMessage("✅ Feedback erfolgreich gesendet! Vielen Dank, ${_userName ?? 'Unbekannt'}!");
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) Navigator.of(context).pop();
      });
      
    } catch (e) {
      setState(() => _isTyping = false);
      debugPrint("Email Error: $e");
      _addBotMessage("⚠️ Fehler beim Senden: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Steampunk Colors from Theme
    const mahoganyLight = Color(0xFF4A2817);
    const mahoganyDark = Color(0xFF2D160E);
    const brassPrimary = Color(0xFFCDBE78);
    const brassDark = Color(0xFF8B7E40);
    const steamWhite = Color(0xFFE0E0E0);
    const leatherDark = Color(0xFF1A1110);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: mahoganyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brassPrimary, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: mahoganyDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // Inner radius slightly less
                border: Border(bottom: BorderSide(color: brassDark, width: 2)),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'QA AUTOMATON ${_useFallback ? "(Basic)" : "(AI)"}',
                      style: GoogleFonts.rye(
                        color: brassPrimary,
                        fontSize: 18,
                        shadows: [const Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: brassPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Chat Area
            Expanded(
              child: Container(
                color: const Color(0xFF1A1110).withOpacity(0.5), // Slight dim for content area
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8), 
                          child: Text(
                            "Zahnräder drehen sich...", 
                            style: GoogleFonts.libreBaskerville(color: brassPrimary.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }
                    final msg = _messages[index];
                    return Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: msg.isUser ? brassPrimary : mahoganyDark,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: msg.isUser ? const Radius.circular(12) : Radius.zero,
                            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(12),
                          ),
                          border: Border.all(
                            color: msg.isUser ? brassDark : brassPrimary.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                             BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(2,2))
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: GoogleFonts.libreBaskerville(
                            fontSize: 15, 
                            color: msg.isUser ? leatherDark : steamWhite, // User: Dark text on Brass | Bot: Light text on Wood
                            fontWeight: msg.isUser ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: mahoganyDark,
                border: Border(top: BorderSide(color: brassDark, width: 2)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLength: 500,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      style: GoogleFonts.libreBaskerville(color: brassPrimary, fontSize: 16),
                      cursorColor: brassPrimary,
                      decoration: InputDecoration(
                        hintText: 'Nachricht senden...',
                        hintStyle: GoogleFonts.libreBaskerville(color: brassPrimary.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        counterText: '',
                      ),
                      onSubmitted: (t) => _handleInput(t),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: brassPrimary),
                    onPressed: () => _handleInput(_textController.text),
                  ),
                ],
              ),
            ),
            
            // Send Report Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: mahoganyDark,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brassPrimary,
                    foregroundColor: leatherDark,
                    elevation: 8,
                    shadowColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: brassDark, width: 3),
                    ),
                  ),
                  onPressed: (_userName != null && !_isTyping && !_feedbackSent)
                    ? () => _sendEmail(sendToUser: _userEmail != null)
                    : null,
                  child: Text(
                    _isTyping ? 'SENDING...' : (_feedbackSent ? 'THANKS!' : 'SEND REPORT'),
                    style: GoogleFonts.rye(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        const Shadow(blurRadius: 2, color: Colors.black45, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ChatFlowState {
  chatting,
  askingEmailConsent,
  askingEmailAddress,
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
