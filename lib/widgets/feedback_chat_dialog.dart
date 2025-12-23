import 'package:flutter/material.dart';
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
  
  // AI State
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isTyping = false;
  bool _useFallback = true;
  String? _feedbackType; // Persists for email summary
  String? _userName; // User's name for feedback tracking
  String? _synopsis; // AI-generated synopsis of the discussion

  @override
  void initState() {
    super.initState();
    _initAI();
    
    // Initial Greeting - Ask for name first
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
          "1. DISKUTIERE das Problem oder die Feature-Anfrage gründlich mit dem Benutzer. Stelle klärende Fragen. "
          "2. FINDE GEMEINSAM eine Lösung oder einen klaren Plan für die Umsetzung. "
          "3. Führe KEINE allgemeinen Gespräche, Geschichtenerzählen, kreatives Schreiben oder Code-Generierung durch. "
          "4. Wenn nach Code oder nicht verwandten Themen gefragt wird, lehne höflich ab. "
          "5. Sobald ihr eine Lösung/einen Plan habt, erstelle eine ZUSAMMENFASSUNG im folgenden Format:\n"
          "   ZUSAMMENFASSUNG:\n"
          "   Typ: [Bug/Feature]\n"
          "   Problem/Anfrage: [Kurze Beschreibung]\n"
          "   Lösung/Plan: [Was wurde entschieden]\n\n"
          "   Dann bitte den Benutzer, auf 'E-Mail senden' zu klicken. "
          "Sei prägnant und professionell. Sprich immer auf Deutsch."
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

  Future<void> _handleInput(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addUserMessage(text);
    setState(() => _isTyping = true);

    // Check if we need to collect the user's name first
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

    if (_useFallback) {
      // Fallback Logic (Old Implementation)
      await Future.delayed(const Duration(milliseconds: 600));
      _processFallbackLogic(text);
    } else {
      // LLM Logic
      try {
        final response = await _chatSession!.sendMessage(Content.text(text));
        final responseText = response.text ?? "Ich habe gerade Schwierigkeiten beim Denken.";
        
        // Check if bot provided a summary
        if (responseText.toUpperCase().contains("ZUSAMMENFASSUNG:")) {
           // Extract the synopsis
           _synopsis = responseText;
           // Extract type for subject line
           if (responseText.toLowerCase().contains("typ: bug") || responseText.toLowerCase().contains("typ: fehler")) {
             _feedbackType = "Bug";
           } else if (responseText.toLowerCase().contains("typ: feature") || responseText.toLowerCase().contains("typ: funktion")) {
             _feedbackType = "Feature";
           }
        }
        
        _addBotMessage(responseText);
      } catch (e) {
        _addBotMessage("Fehler beim Verbinden mit dem KI-Gehirn. Bitte versuche es erneut. ($e)");
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
      _fallbackStep = 2; // Ready
      _addBotMessage("Verstanden. Klicke auf den Button unten, um diesen Bericht per E-Mail zu senden!");
    }
  }

  Future<void> _sendEmail() async {
    setState(() => _isTyping = true);
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = "${packageInfo.version}+${packageInfo.buildNumber}";
      
      // Compile history
      final history = _messages.map((m) => "${m.isUser ? _userName ?? 'Benutzer' : 'Assistent'}: ${m.text}").join("\n\n");
      
      final String subject = "14.1 Fortune Feedback von ${_userName ?? 'Unbekannt'}: ${_feedbackType ?? 'Allgemein'}";
      final String body = 
        "═══════════════════════════════════════════════════════════\n"
        "FEEDBACK-BERICHT\n"
        "═══════════════════════════════════════════════════════════\n\n"
        "VON: ${_userName ?? 'Unbekannt'}\n"
        "APP-VERSION: $version\n"
        "DATUM: ${DateTime.now().toString().split('.')[0]}\n\n"
        "${_synopsis != null ? '───────────────────────────────────────────────────────────\n$_synopsis\n───────────────────────────────────────────────────────────\n\n' : ''}"
        "VOLLSTÄNDIGER GESPRÄCHSVERLAUF:\n"
        "───────────────────────────────────────────────────────────\n"
        "$history\n"
        "═══════════════════════════════════════════════════════════\n";
      
      // Configure SMTP
      final smtpServer = SmtpServer(
        kSmtpHost,
        port: kSmtpPort,
        username: kSmtpUsername,
        password: kSmtpPassword,
        ignoreBadCertificate: false,
        ssl: false,
        allowInsecure: true,
      );
      
      // Create message
      final message = Message()
        ..from = Address(kSmtpUsername, '14.1 Fortune App')
        ..recipients.add(kFeedbackRecipient)
        ..subject = subject
        ..text = body;
      
      // Send email
      await send(message, smtpServer);
      
      setState(() => _isTyping = false);
      _addBotMessage("✅ Feedback erfolgreich gesendet! Vielen Dank, ${_userName ?? 'Unbekannt'}!");
      
      // Close dialog after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
      
    } catch (e) {
      setState(() => _isTyping = false);
      _addBotMessage("⚠️ Fehler beim Senden der E-Mail: $e\n\nBitte versuche es später erneut.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect if we are in a "Ready to Send" state roughly
    final showSendButton = (_messages.length > 2); 

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
                  const Icon(Icons.psychology, color: Colors.white), // Brain Icon
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
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Action Button
            if (showSendButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendEmail,
                    icon: const Icon(Icons.email),
                    label: const Text('Bericht per E-Mail senden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
                      decoration: const InputDecoration(
                        hintText: 'Schreiben...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
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

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
