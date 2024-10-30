import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'GOOGLE_AI_KEY', useConstantCase: true)
  static const String googleAiKey = _Env.googleAiKey;
}
