import 'package:google_generative_ai/google_generative_ai.dart';

class ISpectGoogleAi {
  // Private constructor
  ISpectGoogleAi._internal({required this.apiKey});

  static ISpectGoogleAi? _instance;
  final String apiKey;

  // Singleton instance getter
  static ISpectGoogleAi get instance {
    if (_instance == null) {
      throw StateError('ISpectGoogleAi is not initialized. Call init() first.');
    }
    return _instance!;
  }

  // Initialization method with check to prevent reinitialization
  static void init(String key) {
    if (_instance != null) {
      return;
    }
    _instance = ISpectGoogleAi._internal(apiKey: key);
  }

  bool get isAvailable => apiKey.isNotEmpty;

  // Lazy initialization of model
  late final GenerativeModel model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: apiKey,
    systemInstruction: Content.system('Your name is ISpect. You are a monitoring system.'),
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );
}
