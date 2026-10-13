class AppConfig {
  // API Host & Endpoints
  static const String apiHost = 'https://n8n.srv1348343.hstgr.cloud';
  static const String physicalInventoryEndpoint = '$apiHost/webhook/physical_inventory';
  static const String stockOverviewEndpoint = '$apiHost/webhook/stock_overview';
  static const String generateOtpEndpoint = '$apiHost/webhook/generate_otp';
  static const String verifyOtpEndpoint = '$apiHost/webhook/verify_otp';

  // Feature Flags
  static const bool enableVoiceRecognition = true; // Set to false to show "Voice commands under development" overlay
}
