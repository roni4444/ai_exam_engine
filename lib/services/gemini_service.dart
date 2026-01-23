import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/gemini_config.dart';
import '../models/exam_models.dart';

class GeminiService {
  // static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  // final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  static final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-3-flash-preview');

  /*static Future<Map<String, dynamic>?> genAIOnPDF({required String fileName, required Function(String) onStatusUpdate}) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return null;
    final bytes = await supabase.storage.from('exam-assets').download('library/$userId/$fileName');
    try {
      // Detect language
      onStatusUpdate('detecting_language');
      final language = await languageDetection(bytes: bytes);
      supabase.from('library_items').upsert({'language': language});
      // Translate if needed
      String processedText = rawText;
      if (!language.toLowerCase().contains('english')) {
        if (onStatusUpdate != null) onStatusUpdate('translating');
        processedText = await translateToEnglish(rawText);
      }

      // Analyze chapters
      onStatusUpdate('analyzing_chapters');
      final chapters = await chapterAnalysis(bytes: bytes, onStatusUpdate: onStatusUpdate);
      supabase.from('library_items').upsert({'language': language});
      // Generate title
      onStatusUpdate('generating_title');
      final title = await examTitleSuggestion(bytes: bytes);

      return {'chapters': chapters, 'language': language};
    } catch (e) {
      if (kDebugMode) print('Document processing error: $e');
      rethrow;
    }
  }

  static Future<String?> languageDetection({required Uint8List bytes}) async {
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

  static Future<List<AnalyzedChapter>> chapterAnalysis({required Uint8List bytes, required Function(String) onStatusUpdate}) async {
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

  static Future<String?> examTitleSuggestion({required Uint8List bytes}) async {
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
  }*/

  /*static Future<Map<String, dynamic>> _makeRequest({
    required String prompt,
    String model = 'gemini-3-flash-preview',
    bool useJson = false,
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/models/$model:generateContent?key=${GeminiConfig.apiKey}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              if (useJson) 'responseMimeType': 'application/json',
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 8192,
            },
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return {'success': true, 'data': text, 'usage': data['usageMetadata']};
        } else if (response.statusCode == 429 || response.statusCode == 503) {
          // Rate limit or service unavailable - retry with backoff
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        } else {
          throw Exception('API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw Exception('Max retries exceeded');
  }
*/
  static dynamic _cleanAndParseJson(String text) {
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

  /*
  static Future<String> detectLanguage(String text) async {
    try {
      final prompt = '''Identify the primary language of this text.
Return ONLY the language name (e.g., English, Bengali, Hindi, Spanish).
Text: ${text.substring(0, 500)}''';

      final result = await _makeRequest(prompt: prompt, model: 'gemini-3-flash-preview');
      return result['data'].toString().trim();
    } catch (e) {
      if (kDebugMode) print('Language detection error: $e');
      return 'English';
    }
  }
*/
  /*

  static Future<String> translateToEnglish(String text) async {
    try {
      final prompt = '''Translate the following text to English.
Preserve any HTML tags, LaTeX math expressions (keep \$ delimiters), and formatting exactly.
Text: $text''';

      final result = await _makeRequest(prompt: prompt, model: 'gemini-3-flash-preview');
      return result['data'].toString().trim();
    } catch (e) {
      if (kDebugMode) print('Translation error: $e');
      return text;
    }
  }
*/

  /*  static Future<String> suggestExamTitle(String text) async {
    try {
      final prompt = '''Based on this educational content, suggest a professional exam title.
Return ONLY the title, nothing else.
Content: ${text.substring(0, 2000)}''';

      final result = await _makeRequest(prompt: prompt);
      return result['data'].toString().trim();
    } catch (e) {
      if (kDebugMode) print('Title suggestion error: $e');
      return 'Exam';
    }
  }*/

  /*static Future<List<AnalyzedChapter>> analyzeChapterContent(String text, Function(String)? onStatusUpdate) async {
    try {
      if (onStatusUpdate != null) onStatusUpdate('analyzing');

      final prompt = '''Analyze this educational text and identify distinct chapters or major topics.
For each chapter, extract key concepts with the following structure:

Return a JSON array:
[
  {
    "title": "Chapter Name",
    "concepts": [
      {
        "name": "Concept Name",
        "description": "Brief description",
        "type": "definition" | "process" | "cause-effect" | "misconception"
      }
    ]
  }
]

Text (first 50000 characters): ${text.substring(0, text.length > 50000 ? 50000 : text.length)}''';

      final result = await _makeRequest(prompt: prompt, model: 'gemini-3-pro-preview', useJson: true);

      final parsed = _cleanAndParseJson(result['data']);
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
  }*/

  /*  static Future<Map<String, dynamic>> processFullDocument(String rawText, Function(String)? onStatusUpdate) async {
    try {
      // Detect language
      if (onStatusUpdate != null) onStatusUpdate('detecting_language');
      final language = await detectLanguage(rawText);

      // Translate if needed
      String processedText = rawText;
      if (!language.toLowerCase().contains('english')) {
        if (onStatusUpdate != null) onStatusUpdate('translating');
        processedText = await translateToEnglish(rawText);
      }

      // Analyze chapters
      if (onStatusUpdate != null) onStatusUpdate('analyzing_chapters');
      final chapters = await analyzeChapterContent(processedText, onStatusUpdate);

      // Generate title
      if (onStatusUpdate != null) onStatusUpdate('generating_title');
      final title = await suggestExamTitle(processedText);

      return {'processedText': processedText, 'chapters': chapters, 'title': title};
    } catch (e) {
      if (kDebugMode) print('Document processing error: $e');
      rethrow;
    }
  }*/

  /*static Future<List<Question>> generateQuestionsFromConcepts({
    required List<AnalyzedChapter> chapters,
    required Map<String, dynamic> config,
    Function(int, int)? onProgress,
  }) async {
    try {
      List<Question> allQuestions = [];
      int currentProgress = 0;

      // Simple generation for demo - in production, this would be more complex
      final sections = config['sections'] as List<dynamic>;
      int totalToGenerate = 0;

      for (var section in sections) {
        final questionTypes = section['questionTypes'] as List<dynamic>;
        for (var qt in questionTypes) {
          final count = qt['count'] as Map<String, dynamic>;
          totalToGenerate += int.parse(count['Easy'].toString()) + int.parse(count['Medium'].toString()) + int.parse(count['Hard'].toString());
        }
      }

      if (onProgress != null) onProgress(0, totalToGenerate);

      for (var section in sections) {
        final questionTypes = section['questionTypes'] as List<dynamic>;

        for (var qt in questionTypes) {
          final count = qt['count'] as Map<String, dynamic>;
          final difficulties = ['Easy', 'Medium', 'Hard'];

          for (var difficulty in difficulties) {
            final questionCount = count[difficulty] ?? 0;
            if (questionCount == 0) continue;

            // Create prompt for batch generation
            final conceptsList = chapters.expand((c) => c.concepts).map((c) => c.name).take(20).join(', ');

            final prompt =
                '''Generate $questionCount unique ${qt['type']} questions about: $conceptsList

Requirements:
- Difficulty: $difficulty
- Marks: ${qt['marks']} each
- Type: ${qt['type']}
- Include model answers and rubric points

Return JSON array:
[
  {
    "text": "Question text with \$math\$ in LaTeX",
    "concept": "Related concept",
    "difficulty": "$difficulty",
    "type": "${qt['type']}",
    "modelAnswer": "Detailed answer",
    "rubric": ["Point 1", "Point 2"],
    "options": ["A", "B", "C", "D"] (for MCQ only)
  }
]''';

            final result = await _makeRequest(prompt: prompt, model: 'gemini-3-pro-preview', useJson: true);

            final parsed = _cleanAndParseJson(result['data']);
            if (parsed is List) {
              for (var item in parsed) {
                allQuestions.add(
                  Question(
                    id: 'q_${DateTime.now().millisecondsSinceEpoch}_${allQuestions.length}',
                    sectionId: section['id'],
                    sectionName: section['name'],
                    text: item['text'] ?? '',
                    concept: item['concept'] ?? '',
                    difficulty: difficulty,
                    type: qt['type'],
                    marks: qt['marks'],
                    modelAnswer: item['modelAnswer'] ?? '',
                    rubric: List<String>.from(item['rubric'] ?? []),
                    options: item['options'] != null ? List<String>.from(item['options']) : null,
                    negativeValue: qt['negativeValue'] ?? 0.0,
                    allowPartial: qt['partialScoring'] ?? false,
                    isOrType: false,
                    bloomsLevel: item['bloomsLevel'] ?? 'Mixed',
                  ),
                );

                currentProgress++;
                if (onProgress != null) onProgress(currentProgress, totalToGenerate);
              }
            }
          }
        }
      }

      return allQuestions;
    } catch (e) {
      if (kDebugMode) print('Question generation error: $e');
      rethrow;
    }
  }
*/
  /*static Future<List<Question>> translateQuestions(List<Question> questions, String targetLanguage) async {
    if (targetLanguage == 'English') return questions;

    try {
      // Batch translate in groups of 5
      const batchSize = 5;
      List<Question> translated = [];

      for (int i = 0; i < questions.length; i += batchSize) {
        final batch = questions.sublist(i, i + batchSize > questions.length ? questions.length : i + batchSize);

        final prompt = '''Translate these questions to $targetLanguage.
Keep LaTeX math (inside \$...\$) exactly as is. Maintain JSON structure.

Questions: ${jsonEncode(batch.map((q) => {'id': q.id, 'text': q.text, 'options': q.options}).toList())}''';

        final result = await _makeRequest(prompt: prompt, model: 'gemini-3-flash-preview', useJson: true);

        final parsed = _cleanAndParseJson(result['data']);
        if (parsed is List) {
          for (int j = 0; j < batch.length; j++) {
            final original = batch[j];
            final translatedData = parsed[j];

            translated.add(
              Question(
                id: original.id,
                sectionId: original.sectionId,
                sectionName: original.sectionName,
                text: translatedData['text'] ?? original.text,
                concept: original.concept,
                difficulty: original.difficulty,
                type: original.type,
                marks: original.marks,
                modelAnswer: original.modelAnswer,
                rubric: original.rubric,
                options: translatedData['options'] != null ? List<String>.from(translatedData['options']) : original.options,
                negativeValue: original.negativeValue,
                allowPartial: original.allowPartial,
                isOrType: original.isOrType,
                bloomsLevel: original.bloomsLevel,
              ),
            );
          }
        }
      }

      return translated;
    } catch (e) {
      if (kDebugMode) print('Translation error: $e');
      return questions;
    }
  }*/

  /*  static Future<Map<String, dynamic>> gradeAnswerImage({required Question question, required String imageBase64}) async {
    try {
      // Remove data:image prefix if present
      final base64Data = imageBase64.contains(',') ? imageBase64.split(',')[1] : imageBase64;

      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-3-flash-preview:generateContent?key=${GeminiConfig.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'inlineData': {'mimeType': 'image/jpeg', 'data': base64Data},
                },
                {
                  'text':
                      '''Grade this student's handwritten answer using vision analysis.

Question: "${question.text}"
Model Answer: "${question.modelAnswer}"
Rubric: ${question.rubric.join(', ')}
Max Score: ${question.marks}

Return JSON:
{
  "transcription": "What the student wrote",
  "result": {
    "score": number,
    "maxScore": ${question.marks},
    "breakdown": [
      {"symbol": "✓"|"✗"|"⚠", "text": "Explanation", "points": number}
    ],
    "feedback": "Overall feedback"
  }
}''',
                },
              ],
            },
          ],
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final parsed = _cleanAndParseJson(text);

        return {
          'transcription': parsed['transcription'] ?? '',
          'result': parsed['result'] ?? {'score': 0, 'maxScore': question.marks, 'breakdown': [], 'feedback': 'Error in grading'},
        };
      }

      throw Exception('Grading failed: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('Grading error: $e');
      return {
        'transcription': 'Error analyzing image',
        'result': {'score': 0, 'maxScore': question.marks, 'breakdown': [], 'feedback': 'Service error during grading'},
      };
    }
  }*/
}
