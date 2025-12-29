/// Build-time environment configuration
/// Values are provided via --dart-define flags during build
/// 
/// This prevents secrets from being stored in source code files,
/// eliminating the risk of accidental exposure through tool inspection or commits.
class BuildEnv {
  // Gemini API Configuration
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  // GitHub Integration
  static const String githubToken = String.fromEnvironment('GITHUB_TOKEN');
  static const String githubRepo = String.fromEnvironment('GITHUB_REPO', defaultValue: 'Gruenbaer/141fortune');
  
  // Email Configuration (Feedback)
  static const String smtpHost = String.fromEnvironment(
    'SMTP_HOST',
    defaultValue: 'w0208b4b.kasserver.com',
  );
  
  static const int smtpPort = int.fromEnvironment(
    'SMTP_PORT',
    defaultValue: 465,
  );
  
  static const String smtpUsername = String.fromEnvironment(
    'SMTP_USERNAME',
    defaultValue: '',
  );
  
  static const String smtpPassword = String.fromEnvironment(
    'SMTP_PASSWORD',
    defaultValue: '',
  );
  
  static const String feedbackRecipient = String.fromEnvironment(
    'FEEDBACK_RECIPIENT',
    defaultValue: 'info@knthlz.de',
  );
  
  // Validation helpers
  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;
  static bool get hasSmtpConfig => smtpUsername.isNotEmpty && smtpPassword.isNotEmpty;
}
