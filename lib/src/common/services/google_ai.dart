import 'package:google_generative_ai/google_generative_ai.dart';

class ISpectGoogleAi {
  // Private constructor
  // ignore: prefer_const_constructor_declarations
  ISpectGoogleAi._internal({required this.apiKey});

  final String apiKey;

  static late final ISpectGoogleAi instance;

  // Initialization method
  static void init(String apiKey) {
    instance = ISpectGoogleAi._internal(apiKey: apiKey);
  }

  bool get isAvailable => instance.apiKey.isNotEmpty;

  // Lazy initialization of model to ensure instance is initialized first
  late final GenerativeModel model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: apiKey,
    systemInstruction: Content.system('Your name is ISpect. You are a monitoring system.'),
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );
}
