import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exam_config.dart';

class GeminiProvider with ChangeNotifier {
  final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-3-flash-preview');

  Future<Map<String, dynamic>?> genAIOnPDF({required String fileName, required Function(String) onStatusUpdate}) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return null;
    final bytes = await supabase.storage.from('exam-assets').download('library/$userId/$fileName');
    try {
      // Detect language
      onStatusUpdate('detecting_language');
      // notifyListeners();
      final language = await languageDetection(bytes: bytes);
      supabase.from('library_items').upsert({'language': language});
      /*// Translate if needed
      String processedText = rawText;
      if (!language.toLowerCase().contains('english')) {
        if (onStatusUpdate != null) onStatusUpdate('translating');
        processedText = await translateToEnglish(rawText);
      }*/

      // Analyze chapters
      onStatusUpdate('analyzing_chapters');
      final chapters = await chapterAnalysis(bytes: bytes, onStatusUpdate: onStatusUpdate);
      if (kDebugMode) {
        print("Chapters: $chapters");
      }
      final rows = chapters
          .map(
            (c) => {'file_name': fileName, 'title': c.title, 'concepts': c.concepts.map((concept) => concept.toJson()).toList(), 'user_id': userId},
          )
          .toList();
      supabase.from('chapters').upsert(rows);
      /*// Generate title
      onStatusUpdate('generating_title');
      final title = await examTitleSuggestion(bytes: bytes);*/
      onStatusUpdate('completed');
      supabase.from('library_items').upsert({'is_gemini_processed': rows.isNotEmpty});
      return {'chapters': chapters, 'language': language, 'is_gemini_processed': rows.isNotEmpty};
    } catch (e) {
      if (kDebugMode) print('Document processing error: $e');
      rethrow;
    }
  }

  Future<String?> languageDetection({required Uint8List bytes}) async {
    // Create InlineDataPart
    final docPart = InlineDataPart('application/pdf', bytes);

    // Prompt
    final prompt = TextPart("Identify the primary language of this file. Return ONLY the language name (e.g., English, Bengali, Hindi, Spanish).");

    // Gemini call
    final response = await model.generateContent([
      Content.multi([prompt, docPart]),
    ]);

    if (kDebugMode) {
      print(response.text);
    }

    return response.text;
  }

  Future<List<AnalyzedChapter>> chapterAnalysis({required Uint8List bytes, required Function(String) onStatusUpdate}) async {
    final responseSchema = Schema.array(
      items: Schema.object(
        properties: {
          'title': Schema.string(description: 'Chapter name'),
          'concepts': Schema.array(
            items: Schema.object(
              properties: {
                'name': Schema.string(description: 'Concept name'),
                'description': Schema.string(description: 'Brief description of the concept'),
                'type': Schema.enumString(enumValues: ['definition', 'process', 'cause-effect', 'misconception']),
              },
              optionalProperties: ['name', 'description', 'type'],
            ),
          ),
        },
        optionalProperties: ['title', 'concepts'],
      ),
    );
    // Create InlineDataPart
    final docPart = InlineDataPart('application/pdf', bytes);

    // Prompt
    final prompt = TextPart("Analyze this educational text and identify distinct chapters or major topics.");

    // Gemini call
    try {
      onStatusUpdate('analyzing');
      final response = await model.generateContent([
        Content.multi([prompt, docPart]),
      ], generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: responseSchema));

      if (kDebugMode) {
        print(response.text);
      }
      if (response.text == null || response.text!.isEmpty) return [];

      final parsed = _cleanAndParseJson(response.text ?? "");
      if (parsed == null) return [];

      List<AnalyzedChapter> chapters = [];
      if (parsed is List) {
        for (var item in parsed) {
          chapters.add(AnalyzedChapter.fromJson(item));
        }
      }

      return chapters;
    } catch (e) {
      if (kDebugMode) print('Chapter analysis error: $e');
      rethrow;
    }
  }

  Future<String?> examTitleSuggestion({required Uint8List bytes}) async {
    try {
      // Create InlineDataPart
      final docPart = InlineDataPart('application/pdf', bytes);

      // Prompt
      final prompt = TextPart("Based on this educational content, suggest a professional exam title. Return ONLY the title, nothing else.");

      // Gemini call
      final response = await model.generateContent([
        Content.multi([prompt, docPart]),
      ]);

      if (kDebugMode) {
        print(response.text);
      }

      return response.text;
    } catch (e) {
      if (kDebugMode) print('Title suggestion error: $e');
      return 'Exam';
    }
  }

  dynamic _cleanAndParseJson(String text) {
    try {
      // Remove markdown code blocks
      String cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();

      // Find JSON boundaries
      int firstBrace = cleaned.indexOf('{');
      int firstBracket = cleaned.indexOf('[');

      int start = -1;
      if (firstBrace != -1 && firstBracket != -1) {
        start = firstBrace < firstBracket ? firstBrace : firstBracket;
      } else if (firstBrace != -1) {
        start = firstBrace;
      } else if (firstBracket != -1) {
        start = firstBracket;
      }

      if (start == -1) return null;

      String jsonStr = cleaned.substring(start);

      // Try to parse
      return jsonDecode(jsonStr);
    } catch (e) {
      if (kDebugMode) {
        print('JSON parse error: $e');
        print('Raw text: ${text.substring(0, 200)}...');
      }
      return null;
    }
  }
}
