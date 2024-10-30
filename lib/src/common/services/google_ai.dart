import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ispect/src/core/env/env.dart';

class ISpectGoogleAi {
  // ignore: prefer_const_constructor_declarations
  ISpectGoogleAi._internal();

  static final ISpectGoogleAi instance = ISpectGoogleAi._internal(); // Static instance for global access

  final GenerativeModel model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: Env.googleAiKey,
    systemInstruction: Content.system('Your name is ISpect. You are a monitoring system.'),
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );
}
