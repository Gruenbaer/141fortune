import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../secrets.dart'; // Imports kGeminiApiKey and SMTP config

// -----------------------------------------------------------------------------
// CONFIGURATION
// kGeminiApiKey is now loaded from secrets.dart (gitignored)
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
  static const _minApiCallInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initAI();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_useFallback) {
         _addBotMessage("Hallo! Ich bin der Fortune QA Bot (Basis-Modus). 🤖\n\nBitte füge einen API-Schlüssel hinzu, um mein Gehirn zu aktivieren!\n\nZuerst: Wie heißt du?");
      } else {
         _addBotMessage("Hallo! Ich bin der Fortune QA-Assistent. 🤖\n\nIch kann dir helfen, Fehler zu melden oder neue Funktionen zu beschreiben.\n\nZuerst: Wie heißt du?");
      }
    });
  }

  void _initAI() {
    if (kGeminiApiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: kGeminiApiKey,
        systemInstruction: Content.system(
          "Du bist der QA-Assistent für die '14.1 Fortune' Pool-Scoring-App. "
          "Deine Rolle ist es AUSSCHLIESSLICH, Benutzern zu helfen, Fehler zu melden oder Funktionen vorzuschlagen. "
          "1. DISKUTIERE das Problem oder die Feature-Anfrage gründlich mit dem Benutzer. "
          "2. FINDE GEMEINSAM eine Lösung oder einen klaren Plan. "
          "3. Wenn ihr fertig seid, erstelle eine ZUSAMMENFASSUNG im Format:\n"
          "   ZUSAMMENFASSUNG:\n"
          "   Typ: [Bug/Feature]\n"
          "   Problem: [Kurztext]\n"
          "   Lösung: [Kurztext]\n"
          "   Dann frage: 'Das klingt nach einem Plan. Möchtest du eine Kopie dieses Chats per E-Mail erhalten?'"
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
    return input
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim()
      .substring(0, input.length > 5000 ? 5000 : input.length);
  }

  Future<void> _handleInput(String text) async {
    if (text.trim().isEmpty) return;
    
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
        _addBotMessage("Fehler beim Verbinden mit dem KI-Gehirn. Bitte versuche es erneut.");
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
        kSmtpHost,
        port: kSmtpPort,
        username: kSmtpUsername,
        password: kSmtpPassword,
        ignoreBadCertificate: false,
        ssl: true,
        allowInsecure: false, 
      );
      
      final message = Message()
        ..from = Address(kSmtpUsername, '14.1 Fortune App')
        ..recipients.add(kFeedbackRecipient)
        ..subject = subject
        ..text = body;
        
      if (sendToUser && _userEmail != null) {
        message.ccRecipients.add(_userEmail!);
      }
      
      await send(message, smtpServer);
      
      setState(() => _isTyping = false);
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'QA Assistant ${_useFallback ? "(Basic)" : "(AI)"}',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(padding: EdgeInsets.all(8), child: Text("Denke nach...", style: TextStyle(color: Colors.grey))),
                    );
                  }
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 260),
                      decoration: BoxDecoration(
                        color: msg.isUser ? const Color(0xFFBBDEFB) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: msg.isUser ? const Radius.circular(12) : Radius.zero,
                          bottomRight: msg.isUser ? Radius.zero : const Radius.circular(12),
                        ),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0,1))
                        ],
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(fontSize: 15, color: Colors.black), // Black Text
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLength: 500,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: const InputDecoration(
                        hintText: 'Schreiben...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        counterText: '',
                      ),
                      onSubmitted: (t) => _handleInput(t),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF2196F3)),
                    onPressed: () => _handleInput(_textController.text),
                  ),
                ],
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
