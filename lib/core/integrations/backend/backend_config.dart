/// Configuration for Backend Client.
/// Loaded from environment variables in V2.
class BackendConfig {
  final String baseUrl;
  final String apiKey;
  final Duration timeout;

  const BackendConfig({
    required this.baseUrl,
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
  });

  /// Default configuration placeholders.
  static const empty = BackendConfig(
    baseUrl: 'https://api.mithaq.example',
    apiKey: 'placeholder_v1_key',
  );
}
