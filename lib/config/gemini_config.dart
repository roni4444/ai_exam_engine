import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String modelFast = 'gemini-3-flash-preview';
  static const String modelReasoning = 'gemini-3-flash-preview';
}
