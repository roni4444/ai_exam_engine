import 'package:ai_exam_engine/models/candidate_model.dart';
import 'package:ai_exam_engine/models/exam_blueprint_model.dart';
import 'package:ai_exam_engine/models/exam_config.dart';
import 'package:firebase_ai/firebase_ai.dart' hide Candidate;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import '../models/exam_models.dart';

// Helper class to group tasks
class QuestionTypeTask {
  final ExamSection section;
  final QuestionTypeConfig questionType;

  QuestionTypeTask({required this.section, required this.questionType});
}

class QuestionProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  late String _currentExamId;
  late String _libraryId;
  late String _candidateGroupId;
  late String _examBlueprintId;
  List<Question> _questions = [];
  List<AnalyzedChapter> _currentChapters = [];
  List<String> _importantChapters = [];
  List<Candidate> _currentCandidates = [];
  ExamBlueprint? _examBlueprint;
  QuestionGenerationProgress? _progress;
  bool _isGenerating = false;
  String? _error;
  late String _fileName;

  List<Question> get questions => _questions;
  QuestionGenerationProgress? get progress => _progress;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  // ExamBlueprint get examBlueprint => _examBlueprint;
  // String get currentExamId => _currentExamId;
  // String get libraryId => _libraryId;
  // String get candidateGroupId => _candidateGroupId;
  // String get examBlueprintId => _examBlueprintId;
  List<AnalyzedChapter> get currentChapters => _currentChapters;
  List<String> get importantChapters => _importantChapters;
  List<Candidate> get currentCandidates => _currentCandidates;
  // String get fileName => _fileName;

  /// Start question generation directly in Flutter
  Future<void> generateQuestions(String? examId) async {
    _isGenerating = true;
    _error = null;
    await loadQuestions(examId);

    final totalQuestions = _calculateTotalQuestions();
    _progress = QuestionGenerationProgress(current: 0, total: totalQuestions, status: 'initializing');
    notifyListeners();
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    _progress = QuestionGenerationProgress(current: 0, total: totalQuestions, status: 'downloading details');
    notifyListeners();
    final bytes = await supabase.storage.from('exam-assets').download('library/$userId/$_fileName');

    try {
      // Update progress in database
      await _updateProgressInDb(_progress!);
      // print("object");
      // Build syllabus context
      final syllabusContext = _buildSyllabusContext();
      final allQuestions = <Question>[];

      final batchCount = (_currentCandidates.length);
      int currentProgress = 0;

      // Update to generating status
      _progress = QuestionGenerationProgress(current: 0, total: totalQuestions, status: 'preparing batches');
      notifyListeners();
      await _updateProgressInDb(_progress!);

      // Generate questions in batches by question type
      // for (int batch = 0; batch < batchCount; batch++) {
      final sections = _examBlueprint?.sections ?? [];

      // Group all question types across sections by their type name
      final Map<String, List<QuestionTypeTask>> questionTypeGroups = {};

      for (ExamSection section in sections) {
        final questionTypes = section.questionTypes as List<QuestionTypeConfig>? ?? [];

        for (QuestionTypeConfig qt in questionTypes) {
          final typeKey = qt.type;

          if (!questionTypeGroups.containsKey(typeKey)) {
            questionTypeGroups[typeKey] = [];
          }

          questionTypeGroups[typeKey]!.add(QuestionTypeTask(section: section, questionType: qt));
        }
      }
      // Process each question type group in batch
      for (var entry in questionTypeGroups.entries) {
        final String typeName = entry.key;
        final List<QuestionTypeTask> tasks = entry.value;

        try {
          if (typeName == 'Scenario Based') {
            // Batch process all scenario questions of this type
            final scenarioQuestions = await _generateScenarioBatch(
              examId: _currentExamId,
              batch: batchCount,
              tasks: tasks,
              chapters: _currentChapters,
              bytes: bytes,
            );
            // if (kDebugMode) {
            //   print('The standard questions $scenarioQuestions of length ${scenarioQuestions.length}');
            // }
            allQuestions.addAll(scenarioQuestions);
            currentProgress += scenarioQuestions.length;
            // if (kDebugMode) {
            //   print('The standard questions $scenarioQuestions of length ${scenarioQuestions.length}');
            // }
            await _saveQuestionsToDb(scenarioQuestions);
          } else {
            // Batch process all standard questions of this type
            final standardQuestions = await _generateStandardQuestionsBatch(
              examId: _currentExamId,
              batch: batchCount,
              typeName: typeName,
              tasks: tasks,
              syllabusContext: syllabusContext,
              bytes: bytes,
            );
            // if (kDebugMode) {
            //   print('The standard questions $standardQuestions of length ${standardQuestions.length}');
            // }
            allQuestions.addAll(standardQuestions);
            currentProgress += standardQuestions.length;
            // if (kDebugMode) {
            //   print('The standard questions $standardQuestions of length ${standardQuestions.length}');
            // }
            await _saveQuestionsToDb(standardQuestions);
          }

          // Update progress after each question type batch
          _progress = QuestionGenerationProgress(current: currentProgress, total: totalQuestions, status: 'generating $typeName');
          notifyListeners();
          await _updateProgressInDb(_progress!);
        } catch (e) {
          debugPrint('Failed to generate questions for type $typeName: $e');
        }
      }
      // }

      /*// Generate questions for each batch
      for (int batch = 0; batch < batchCount; batch++) {
        final sections = _examBlueprint.sections as List<ExamSection>? ?? [];

        for (ExamSection section in sections) {
          final questionTypes = section.questionTypes as List<QuestionTypeConfig>? ?? [];

          for (QuestionTypeConfig qt in questionTypes) {
            // Handle Scenario Based Questions
            if (qt.type == 'Scenario Based') {
              final scenarios = qt.scenarios;

              for (ScenarioConfig scenarioConfig in scenarios) {
                try {
                  final scenarioQ = await _generateScenarioQuestion(
                    examId: _currentExamId,
                    batch: batch,
                    section: section,
                    qt: qt,
                    scenarioConfig: scenarioConfig,
                    chapters: _currentChapters,
                    bytes: bytes,
                  );

                  if (scenarioQ != null) {
                    allQuestions.add(scenarioQ);
                    currentProgress++;

                    _progress = QuestionGenerationProgress(current: currentProgress, total: totalQuestions, status: 'generating');
                    notifyListeners();
                    await _updateProgressInDb(_progress!);
                  }
                } catch (e) {
                  debugPrint('Scenario generation failed: $e');
                }
              }
              continue;
            }

            // Handle Standard Questions
            final DifficultyCount count = qt.count;
            final totalForType = (count.easy) + (count.medium) + (count.hard);

            if (totalForType > 0) {
              try {
                final standardQs = await _generateStandardQuestions(
                  examId: _currentExamId,
                  batch: batch,
                  section: section,
                  qt: qt,
                  syllabusContext: syllabusContext,
                  bytes: bytes,
                );

                allQuestions.addAll(standardQs);
                currentProgress += standardQs.length;

                _progress = QuestionGenerationProgress(current: currentProgress, total: totalQuestions, status: 'generating');
                notifyListeners();
                await _updateProgressInDb(_progress!);
              } catch (e) {
                debugPrint('Standard question generation failed: $e');
              }
            }
          }
        }
      }*/

      // Save all questions to database
      // await _saveQuestionsToDb(allQuestions);
      _questions = allQuestions;

      // Mark as complete
      _progress = QuestionGenerationProgress(current: allQuestions.length, total: allQuestions.length, status: 'completed', isComplete: true);
      _isGenerating = false;
      notifyListeners();
      await _updateProgressInDb(_progress!);
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;

      _progress = QuestionGenerationProgress(current: 0, total: totalQuestions, status: 'failed', error: e.toString());
      notifyListeners();
      await _updateProgressInDb(_progress!);
      rethrow;
    }
  }

  /* Future<Question?> _generateScenarioQuestion({
    required String examId,
    required int batch,
    required ExamSection section,
    required QuestionTypeConfig qt,
    required ScenarioConfig scenarioConfig,
    required List<AnalyzedChapter> chapters,
    required Uint8List bytes,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-flash-preview',
      systemInstruction: Content.system('''
      You must output ONLY valid JSON.
        Rules:
        - Output must be a JSON array.
        - Each array item represents exactly ONE chapter.
        - Each chapter MUST contain:
        - "title" (string)
        - "concepts" (array, can be empty)
        - Never split title and concepts into separate objects.
        - Never omit required keys.
        - Do not add extra keys.
        - Do not add markdown or explanations.

        Concept rules:
        - Each concept may include name, description, and type.
        - If type is unknown, use "general".
        - Keep descriptions short (1 sentence).

      Follow the provided JSON schema exactly.'''),
    );
    // Create InlineDataPart
    final docPart = InlineDataPart('application/pdf', bytes);
    final prompt = TextPart(_buildScenarioPrompt(scenarioConfig, chapters));
    final responseSchema = Schema.array(
      items: Schema.object(
        properties: {
          'title': Schema.string(description: 'Chapter name'),
          'concepts': Schema.array(
            items: Schema.object(
              properties: {
                'name': Schema.string(description: 'Concept name'),
                'description': Schema.string(description: 'Brief description'),
                'type': Schema.enumString(enumValues: ['definition', 'process', 'cause-effect', 'misconception', 'general']),
              },
              // concept fields can be optional
              optionalProperties: ['name', 'description', 'type'],
            ),
          ),
        },
        // 🚨 IMPORTANT: NOTHING optional here
        optionalProperties: [],
      ),
    );
    // Gemini call
    final response = await model.generateContent([
      Content.multi([prompt, docPart]),
    ], generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: responseSchema));
    // final response = await _callGemini(prompt);
    final scenarioData = _parseJsonResponse(response.text ?? "");
    // final scenarioData = response.text;

    if (scenarioData == null) return null;

    final questionId = 'sc_${DateTime.now().millisecondsSinceEpoch}_${batch}_${scenarioConfig.id}';

    final question = Question(
      id: questionId,
      examId: examId,
      sectionId: section.id,
      sectionName: section.name,
      text: scenarioData['scenarioText'] ?? '',
      concept: scenarioConfig.topic,
      difficulty: 'Hard',
      type: 'Scenario Based',
      marks: (scenarioConfig.subQuestions).fold(0, (sum, sq) => sum + (sq.marks)),
      isScenario: true,
      scenarioText: scenarioData['scenarioText'],
      subQuestions: scenarioData['subQuestions'],
      modelAnswer: '',
      rubric: [],
      negativeValue: 0,
      allowPartial: false,
      isOrType: false,
      latexVersion: scenarioData['latexVersion'],
    );

    return question;
  }*/

  /*  Future<List<Question>> _generateStandardQuestions({
    required String examId,
    required int batch,
    required ExamSection section,
    required QuestionTypeConfig qt,
    required String syllabusContext,
    required Uint8List bytes,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-flash-preview',
      systemInstruction: Content.system('''
      You must output ONLY valid JSON.
        Rules:
        - Output must be a JSON array.
        - Each array item represents exactly ONE question.
        - Each question MUST contain:
        - "text" (string)
        - "concept" (string)
        - "difficulty" (string)
        - "type" (string)
        - "modelAnswer" (string)
        - "bloomsLevel" (string)
        - "latex" (string)
        - Never split the properties into separate objects.
        - Never omit required keys.
        - Do not add extra keys.
        - Do not add markdown or explanations.
        - MATH: Wrap ALL math in \$ signs (e.g. \$E=mc^2\$) for text based question.
        - DOUBLE ESCAPE backslashes (e.g. "\\\\frac").
        - Latex version of the question should be perfectly generated

        Model Answer rules:
        - Each Model Answer should be the proper answer of the question justifying the rubric (if present).
        - If type is unknown, use "general".
        - Keep descriptions short (1 sentence).

      Follow the provided JSON schema exactly.'''),
    );
    // Create InlineDataPart
    final docPart = InlineDataPart('application/pdf', bytes);
    final prompt = TextPart(_buildStandardQuestionPrompt(qt, section, syllabusContext));
    // final response = await _callGemini(prompt);
    final responseSchema = Schema.array(
      items: Schema.object(
        properties: {
          'text': Schema.string(description: ''),
          'concept': Schema.string(description: ''),
          'difficulty': Schema.string(description: ''),
          'type': Schema.string(description: ''),
          'modelAnswer': Schema.string(description: ''),
          'rubric': Schema.string(description: ''),
          'options (MCQ)': Schema.string(description: ''),
          'bloomsLevel': Schema.string(description: ''),
          'latex': Schema.string(description: ''),
        },
        // 🚨 IMPORTANT: NOTHING optional here
        optionalProperties: ['rubric', 'options (MCQ)'],
      ),
    );
    // Gemini call
    final response = await model.generateContent([
      Content.multi([prompt, docPart]),
    ], generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: responseSchema));
    final questionsData = _parseJsonResponse(response.text ?? "");

    if (questionsData == null || questionsData is! List) return [];

    final questions = <Question>[];
    for (int idx = 0; idx < questionsData.length; idx++) {
      final qData = questionsData[idx];
      final questionId = 'q_${DateTime.now().millisecondsSinceEpoch}_${batch}_${questions.length}_$idx';

      questions.add(
        Question(
          id: questionId,
          examId: examId,
          text: qData['text'] ?? '',
          concept: qData['concept'] ?? '',
          difficulty: qData['difficulty'] ?? '',
          type: qData['type'] ?? '',
          modelAnswer: qData['modelAnswer'] ?? '',
          rubric: qData['rubric'] ?? [],
          options: qData['options'] ?? [],
          bloomsLevel: qData['bloomsLevel'] ?? '',
          isScenario: false,
          scenarioText: '',
          subQuestions: [],
          marks: qt.marks,
          isOrType: false,
          negativeValue: qt.negativeMarks == true ? qt.negativeValue : 0,
          allowPartial: qt.partialScoring,
          sectionId: section.id,
          sectionName: section.name,
          latexVersion: qData['latexVersion'],
        ),
      );
    }

    return questions;
  }*/

  /*/// Call Gemini API
  Future<String> _callGemini(String prompt) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$_geminiApiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'topK': 40, 'topP': 0.95, 'maxOutputTokens': 8192},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
  }*/

  /*

  String _buildScenarioPrompt(ScenarioConfig scenarioConfig, List<AnalyzedChapter> chapters) {
    final subQuestions = scenarioConfig.subQuestions as List<SubQuestionConfig>? ?? [];

    return '''
Create a detailed, real-life "Scenario Based Question".
Topic/Focus: "${scenarioConfig.topic}".

Instructions:
1. Write a rich, detailed paragraph (100-200 words) describing a real-world scenario.
2. Generate ${subQuestions.length} sub-questions based strictly on this scenario.
3. CRITICAL: Wrap ALL mathematical expressions in \$ signs (e.g. \$E=mc^2\$).

Sub-Question Requirements:
${jsonEncode(subQuestions)}

Return STRICT JSON Object:
{
    "scenarioText": "The detailed paragraph...",
    "subQuestions": [
        {
            "text": "Question text...",
            "type": "Type from requirement",
            "modelAnswer": "...",
            "rubric": ["point 1", "point 2"],
            "options": ["A", "B", "C", "D"] (if MCQ)
        }
    ]
}
''';
  }


  String _buildStandardQuestionPrompt(QuestionTypeConfig qt, ExamSection section, String syllabusContext) {
    final DifficultyCount count = qt.count;
    String bloomsInstruction = '';

    final List<BloomsDistribution> dist = qt.bloomsDistribution;
    final distString = dist.map((d) => "${d.count} questions at '${d.level}' level").join(', ');
    bloomsInstruction = 'STRICT COGNITIVE DISTRIBUTION REQ: $distString.';

    return '''
Generate exam questions based on this syllabus:

SYLLABUS CONTEXT:
$syllabusContext

REQUIREMENTS:
1. Section: "${section.name}"
2. Question Type: "${qt.type}"
3. Difficulty: Easy (${count.easy}), Medium (${count.medium}), Hard (${count.hard})
4. $bloomsInstruction

FORMATTING RULES:
- Return STRICT JSON array.
- MATH: Wrap ALL math in \$ signs (e.g. \$E=mc^2\$).
- DOUBLE ESCAPE backslashes (e.g. "\\\\frac").

Return JSON array with fields: text, concept, difficulty, type, modelAnswer, rubric, options (MCQ), bloomsLevel.
''';
  }
*/

  /// Build syllabus context from chapters
  String _buildSyllabusContext() {
    final importantChapters = _importantChapters as List<String>? ?? [];

    return _currentChapters
        .map((c) {
          final isPriority = importantChapters.contains(c.title);
          final List<ChapterConcept> concepts = c.concepts;
          final conceptsList = concepts.take(40).map((x) => x.name).join(', ');

          return 'Chapter: "${c.title}" ${isPriority ? '[HIGH PRIORITY]' : '[Standard]'}\nConcepts: $conceptsList';
        })
        .join('\n\n');
  }

  /// Parse JSON response from Gemini
  dynamic _parseJsonResponse(String text) {
    try {
      // Remove markdown code blocks
      String cleaned = text.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '').trim();

      // Find JSON object/array
      final firstBrace = cleaned.indexOf('{');
      final firstBracket = cleaned.indexOf('[');

      int start = -1;
      if (firstBrace != -1 && firstBracket != -1) {
        start = firstBrace < firstBracket ? firstBrace : firstBracket;
      } else if (firstBrace != -1) {
        start = firstBrace;
      } else if (firstBracket != -1) {
        start = firstBracket;
      }

      if (start != -1) {
        cleaned = cleaned.substring(start);
      }

      return jsonDecode(cleaned);
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }

  /// Calculate total questions to generate
  int _calculateTotalQuestions() {
    int total = 0;
    final List<ExamSection> sections = _examBlueprint!.sections;

    for (ExamSection section in sections) {
      final List<QuestionTypeConfig> questionTypes = section.questionTypes;
      for (QuestionTypeConfig qt in questionTypes) {
        final DifficultyCount count = qt.count;
        total += (count.easy);
        total += (count.medium);
        total += (count.hard);
        total += ((qt.scenarios as List?)?.length ?? 0);
      }
    }

    return total * (_currentCandidates.length).clamp(1, 5);
  }

  /// Update progress in database
  Future<void> _updateProgressInDb(QuestionGenerationProgress progress) async {
    try {
      await _supabase.from('question_generation_progress').upsert({
        'exam_id': _currentExamId,
        'current': progress.current,
        'total': progress.total,
        'status': progress.status,
        'error': progress.error,
        'is_complete': progress.isComplete,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'exam_id');
    } catch (e) {
      debugPrint('Failed to update progress in DB: $e');
    }
  }

  /// Save questions to database
  Future<void> _saveQuestionsToDb(List<Question> questions) async {
    try {
      /*if (kDebugMode) {
        print('The $questions questions of length ${questions.length}');
      }*/
      final batch = questions.map((q) => q.toDBJson(_currentExamId)).toList();
      /*if (kDebugMode) {
        print('Saving in $_currentExamId the $batch questions');
      }*/
      // Insert in chunks of 100 to avoid payload size limits
      for (int i = 0; i < batch.length; i += 10) {
        final chunk = batch.skip(i).take(10).toList();
        if (kDebugMode) {
          print("chunk $chunk");
        }
        await _supabase.from('questions').insert(chunk);
      }
    } catch (e) {
      debugPrint('Failed to save questions to DB: $e');
      rethrow;
    }
  }

  /// Load existing questions for an exam
  Future<void> loadQuestions(String? examId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      if (examId == null) {
        final findId = await _supabase.from('exams').select().eq('user_id', userId).order('created_at', ascending: false).limit(1).single();
        _currentExamId = findId['id'];
        _libraryId = findId['library_id'];
        _candidateGroupId = findId['candidate_group_id'];
        _examBlueprintId = findId['exam_blueprint_id'];
      } else {
        final findId = await _supabase.from('exams').select().eq('id', examId).single();
        _currentExamId = examId;
        _libraryId = findId['library_id'];
        _candidateGroupId = findId['candidate_group_id'];
        _examBlueprintId = findId['exam_blueprint_id'];
      }
      try {
        final response1 = await _supabase.from('questions').select().eq('exam_id', _currentExamId);
        _questions = (response1 as List).map((json) => Question.fromJson(json)).toList();
        final response2 = await _supabase.from('chapters').select().eq('file_id', _libraryId);
        _currentChapters = (response2 as List).map((json) => AnalyzedChapter.fromJson(json)).toList();
        _importantChapters = (response2 as List).map((json) => json['importantChapters'].toString()).toList();
        _fileName = (response2 as List).map((json) => json['file_name'].toString()).toList().first;
        _currentCandidates = await getCandidatesForGroup(_candidateGroupId);
        final response4 = await _supabase.from('exam_blueprints').select().eq('id', _examBlueprintId).single();
        _examBlueprint = ExamBlueprint.fromJson(response4);
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  Future<List<Candidate>> getCandidatesForGroup(String? groupId) async {
    try {
      if (groupId == null) return [];
      // Query the junction table to get candidate IDs for this group
      // Then join with candidates table to get full candidate details
      final response = await _supabase
          .from('candidate_group_members')
          .select('''
            candidates (
              id,
              name,
              email,
              phone,
              roll_number,
              created_at,
              class,
              section,
              metadata,
              user_id,
              updated_at
            )
          ''')
          .eq('group_id', groupId)
          .order('assigned_at', ascending: true);

      // Extract candidates from the nested response
      final List<Candidate> candidates = [];

      for (final item in response as List) {
        if (item['candidates'] != null) {
          candidates.add(Candidate.fromJson(item['candidates']));
        }
      }
      return candidates;
    } catch (error) {
      throw Exception('Failed to fetch candidates for group: $error');
    }
  }

  /// Cancel generation (cleanup)
  void cancelGeneration() {
    _isGenerating = false;
    _currentExamId = "";
    notifyListeners();
  }

  @override
  void dispose() {
    cancelGeneration();
    super.dispose();
  }

  // New batch generation method for scenarios
  Future<List<Question>> _generateScenarioBatch({
    required String examId,
    required int batch,
    required List<QuestionTypeTask> tasks,
    required List<AnalyzedChapter> chapters,
    required Uint8List bytes,
  }) async {
    final List<Question> generatedQuestions = [];

    // Collect all scenario configs from all tasks
    final List<ScenarioGenerationRequest> requests = [];

    for (var task in tasks) {
      final scenarios = task.questionType.scenarios;

      for (var scenarioConfig in scenarios) {
        requests.add(ScenarioGenerationRequest(section: task.section, questionType: task.questionType, scenarioConfig: scenarioConfig));
      }
    }

    // Generate all scenarios in a single API call
    if (requests.isNotEmpty) {
      final batchResults = await _generateScenariosInBatch(examId: examId, batch: batch, requests: requests, chapters: chapters, bytes: bytes);

      generatedQuestions.addAll(batchResults);
    }

    return generatedQuestions;
  }

  // New batch generation method for standard questions
  Future<List<Question>> _generateStandardQuestionsBatch({
    required String examId,
    required int batch,
    required String typeName,
    required List<QuestionTypeTask> tasks,
    required String syllabusContext,
    required Uint8List bytes,
  }) async {
    final List<Question> generatedQuestions = [];

    // Aggregate difficulty counts across all sections
    int totalEasy = 0;
    int totalMedium = 0;
    int totalHard = 0;

    for (var task in tasks) {
      totalEasy += task.questionType.count.easy;
      totalMedium += task.questionType.count.medium;
      totalHard += task.questionType.count.hard;
    }

    if (totalEasy + totalMedium + totalHard > 0) {
      // Generate all questions of this type in one batch
      final batchQuestions = await _generateQuestionTypeBatch(
        examId: examId,
        batch: batch,
        typeName: typeName,
        totalEasy: totalEasy,
        totalMedium: totalMedium,
        totalHard: totalHard,
        tasks: tasks,
        syllabusContext: syllabusContext,
        bytes: bytes,
      );
      // if (kDebugMode) {
      //   print('The batch questions $batchQuestions of length ${batchQuestions.length}');
      // }

      generatedQuestions.addAll(batchQuestions);
    }

    return generatedQuestions;
  }

  // Single API call for multiple scenarios
  Future<List<Question>> _generateScenariosInBatch({
    required String examId,
    required int batch,
    required List<ScenarioGenerationRequest> requests,
    required List<AnalyzedChapter> chapters,
    required Uint8List bytes,
  }) async {
    // Build prompt for all scenarios at once
    final prompt = TextPart(_buildScenarioBatchPrompt(requests, chapters));
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-flash-preview',
      systemInstruction: Content.system('''
      You must output ONLY valid JSON.
        Rules:
        - Output must be a JSON array.
        - Each array item represents exactly ONE question.
        - Each question MUST contain:
        - "text" (string)
        - "concept" (string)
        - "difficulty" (string)
        - "type" (string)
        - "modelAnswer" (string)
        - "bloomsLevel" (string)
        - "latex" (string)
        - Never split the properties into separate objects.
        - Never omit required keys.
        - Do not add extra keys.
        - Do not add markdown or explanations.
        - MATH: Wrap ALL math in \$ signs (e.g. \$E=mc^2\$) for text based question.
        - DOUBLE ESCAPE backslashes (e.g. "\\\\frac").
        - Latex version of the question should be perfectly generated

        Model Answer rules:
        - Each Model Answer should be the proper answer of the question justifying the rubric (if present).
        
      Follow the provided JSON schema exactly.'''),
    );
    // Create InlineDataPart
    final docPart = InlineDataPart('application/pdf', bytes);
    // final response = await _callGemini(prompt);
    final responseSchema = Schema.array(
      items: Schema.object(
        properties: {
          'scenarioIndex': Schema.string(description: 'Match scenarioIndex to the input requests'),
          'scenarioText': Schema.string(description: 'The detailed paragraph...'),
          'subQuestions': Schema.array(
            description: 'sub-questions for scenario questions only',
            items: Schema.object(
              properties: {
                'text': Schema.string(description: 'Question text...'),
                'concept': Schema.string(description: 'Related concept name'),
                'difficulty': Schema.string(description: 'Easy|Medium|Hard'),
                'type': Schema.string(description: "Type from requirement"),
                'modelAnswer': Schema.string(description: 'Detailed answer...'),
                'rubric': Schema.string(description: 'Explain how to answer or how marks will be awarded in few words'),
                'options (MCQ)': Schema.array(
                  description: 'options for MCQ questions only',
                  items: Schema.object(
                    properties: {
                      "A": Schema.string(description: 'Option 1'),
                      "B": Schema.string(description: 'Option 2'),
                      "C": Schema.string(description: 'Option 3'),
                      "D": Schema.string(description: 'Option 4'),
                    },
                    optionalProperties: [],
                  ),
                ),
                "matchingPairs": Schema.array(
                  description: 'matching pairs for matching questions only',
                  items: Schema.object(
                    properties: {
                      "left": Schema.string(description: 'Left side of the pair'),
                      "right": Schema.string(description: 'Right side of the pair'),
                    },
                    optionalProperties: [],
                  ),
                ),
                'latex': Schema.string(description: 'Latex version of the question'),
                'bloomsLevel': Schema.string(description: 'Remember|Understand|Apply|Analyze|Evaluate|Create'),
              },
            ),
          ),
        },
        // 🚨 IMPORTANT: NOTHING optional here
        optionalProperties: ['rubric', 'options (MCQ)'],
      ),
    );
    // Gemini call
    final response = await model.generateContent([
      Content.multi([prompt, docPart]),
    ], generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: responseSchema));

    // Parse and distribute results back to appropriate sections
    return _parseScenarioBatchResponse(response.text ?? "", requests, batch, examId);
  }

  // Single API call for multiple standard questions
  Future<List<Question>> _generateQuestionTypeBatch({
    required String examId,
    required int batch,
    required String typeName,
    required int totalEasy,
    required int totalMedium,
    required int totalHard,
    required List<QuestionTypeTask> tasks,
    required String syllabusContext,
    required Uint8List bytes,
  }) async {
    // Build prompt for all questions of this type
    final prompt = TextPart(
      _buildStandardBatchPrompt(
        typeName: typeName,
        totalEasy: totalEasy,
        totalMedium: totalMedium,
        totalHard: totalHard,
        tasks: tasks,
        syllabusContext: syllabusContext,
        batch: batch,
      ),
    );
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-flash-preview',
      systemInstruction: Content.system('''
      You must output ONLY valid JSON.
        Rules:
        - Output must be a JSON array.
        - Each array item represents exactly ONE question.
        - Each question must be unique
        - Each question MUST contain:
        - "sectionIndex" (integer)
        - "sectionName" (string)
        - "text" (string)
        - "concept" (string)
        - "difficulty" (string)
        - "type" (string)
        - "modelAnswer" (string)
        - "bloomsLevel" (string)
        - "latexVersion" (string)
        - Never split the properties into separate objects.
        - Never omit required keys.
        - Do not add extra keys.
        - Do not add markdown or explanations.
        - MATH: Wrap ALL mathematical expressions, units, and chemical symbols in \$ signs (e.g. \$E=mc^2\$, \$12 \\text{V}\$, \$CO_2\$) for text based question.
        - Escape backslashes correctly for valid JSON strings
        - Latex version of the question should be perfectly generated
        - Distribute questions across sections proportionally
        - All LaTeX content must be Base64-encoded
        - Do NOT include raw LaTeX anywhere except the value of the latexVersion field
        - Do NOT wrap output in markdown
        - Encode LaTeX using UTF-8 before Base64

        Model Answer rules:
        - Each Model Answer should be the proper answer of the question justifying the rubric (if present) separately.
        
      Follow the provided JSON schema exactly.'''),
    );
    // Create InlineDataPart
    final docPart = InlineDataPart('application/pdf', bytes);
    // final response = await _callGemini(prompt);
    final responseSchema = Schema.array(
      items: Schema.object(
        properties: {
          'sectionIndex': Schema.integer(description: 'Section No'),
          'sectionName': Schema.string(description: 'Section name'),
          'text': Schema.string(description: 'Question text'),
          'concept': Schema.string(description: 'Related concept name'),
          'difficulty': Schema.string(description: 'Easy|Medium|Hard'),
          'type': Schema.string(description: typeName),
          'marks': Schema.integer(description: 'Marks for this question'),
          'modelAnswer': Schema.string(description: 'Detailed answer'),
          'rubric': Schema.array(description: 'Marking rubric', items: Schema.string()),
          'options': Schema.array(
            description: 'Options for MCQ only',
            items: Schema.object(
              properties: {
                "A": Schema.string(description: 'Option 1'),
                "B": Schema.string(description: 'Option 2'),
                "C": Schema.string(description: 'Option 3'),
                "D": Schema.string(description: 'Option 4'),
              },
              optionalProperties: [],
            ),
          ),
          'matchingPairs': Schema.array(
            description: 'Matching pairs',
            items: Schema.object(properties: {'left': Schema.string(), 'right': Schema.string()}, optionalProperties: []),
          ),
          'negativeValue': Schema.number(description: 'Negative marking value'),
          'allowPartial': Schema.boolean(description: 'Allow partial marking'),
          'isOrType': Schema.boolean(description: 'Is OR question'),
          'orGroupId': Schema.string(description: 'UUID for OR group'),
          'bloomsLevel': Schema.string(description: 'Remember|Understand|Apply|Analyze|Evaluate|Create'),
          'isScenario': Schema.boolean(description: 'Scenario based question'),
          'scenarioText': Schema.string(description: 'Scenario context'),
          'subQuestions': Schema.array(
            items: Schema.object(
              properties: {
                'text': Schema.string(description: 'Sub-question text'),
                'concept': Schema.string(description: 'Related concept name'),
                'difficulty': Schema.string(description: 'Easy|Medium|Hard'),
                'type': Schema.string(description: typeName),
                'marks': Schema.integer(description: 'Marks for this sub-question'),
                'modelAnswer': Schema.string(description: 'Detailed answer'),
                'rubric': Schema.array(description: 'Marking rubric', items: Schema.string()),
                'options': Schema.array(
                  description: 'Options for MCQ only',
                  items: Schema.object(
                    properties: {
                      "A": Schema.string(description: 'Option 1'),
                      "B": Schema.string(description: 'Option 2'),
                      "C": Schema.string(description: 'Option 3'),
                      "D": Schema.string(description: 'Option 4'),
                    },
                    optionalProperties: [],
                  ),
                ),
                'matchingPairs': Schema.array(
                  description: 'Matching pairs',
                  items: Schema.object(properties: {'left': Schema.string(), 'right': Schema.string()}, optionalProperties: []),
                ),
                'negativeValue': Schema.number(description: 'Negative marking value'),
                'allowPartial': Schema.boolean(description: 'Allow partial marking'),
                'isOrType': Schema.boolean(description: 'Is OR sub-question'),
                'orGroupId': Schema.string(description: 'UUID for OR group'),
                'bloomsLevel': Schema.string(description: 'Remember|Understand|Apply|Analyze|Evaluate|Create'),
                'latexVersion': Schema.string(description: 'LaTeX version of the sub-question in Base64-encoded LaTeX source (UTF-8)'),
              },
              optionalProperties: ['options', 'matchingPairs', 'orGroupId'],
            ),
          ),
          'latexVersion': Schema.string(description: 'LaTeX version of the question in Base64-encoded LaTeX source (UTF-8)'),
        },
        optionalProperties: ['options', 'matchingPairs', 'orGroupId', 'scenarioText', 'subQuestions'],
      ),
    );
    // Gemini call
    final response = await model.generateContent([
      Content.multi([prompt, docPart]),
    ], generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: responseSchema));
    // Parse and distribute results back to appropriate sections
    // if (kDebugMode) {
    //   debugPrint("response: ${response.text}");
    //   debugPrint("tasks: $tasks");
    //   debugPrint("batch: $batch");
    // }
    return await _parseStandardBatchResponse(response.text ?? "", tasks, batch, examId);
  }

  // Build prompt for batch scenario generation
  String _buildScenarioBatchPrompt(List<ScenarioGenerationRequest> requests, List<AnalyzedChapter> chapters) {
    final conceptsContext = chapters.map((c) => 'Chapter: "${c.title}"\nConcepts: ${c.concepts.map((x) => x.name).join(", ")}').join('\n\n');

    final scenarioRequests = requests.asMap().entries.map((entry) {
      final index = entry.key;
      final request = entry.value;
      final scenarioConfig = request.scenarioConfig;
      final sectionName = request.section.name;

      final subQuestionsSpec = scenarioConfig.subQuestions.map((sq) {
        return {'type': sq.type, 'marks': sq.marks, 'difficulty': sq.difficulty, 'bloomsLevel': sq.bloomsLevel, 'count': sq.count};
      }).toList();

      return {
        'scenarioIndex': index,
        'section': sectionName,
        'topic': scenarioConfig.topic.isEmpty ? 'AUTO_RANDOM' : scenarioConfig.topic,
        'subQuestions': subQuestionsSpec,
      };
    }).toList();

    return '''
Generate ${requests.length} detailed, real-life "Scenario Based Questions" in a single batch.

SYLLABUS CONTEXT:
$conceptsContext

SCENARIO REQUIREMENTS:
${jsonEncode(scenarioRequests)}

For EACH scenario, you must:
1. Write a rich, detailed paragraph (100-200 words) describing a real-world scenario
2. Generate the exact number of sub-questions specified in the requirements
3. CRITICAL: Wrap ALL mathematical expressions, units, and chemical symbols in \$ signs (e.g. \$E=mc^2\$, \$12 \\text{V}\$, \$H_2O\$)

IMPORTANT:
- Return exactly ${requests.length} scenario objects
- Match scenarioIndex to the input requests
- Ensure sub-question count matches specification
- Double escape all LaTeX backslashes (e.g. use "\\\\frac" instead of "\\frac")
''';
  }

  // Build prompt for batch standard question generation
  String _buildStandardBatchPrompt({
    required String typeName,
    required int batch,
    required int totalEasy,
    required int totalMedium,
    required int totalHard,
    required List<QuestionTypeTask> tasks,
    required String syllabusContext,
  }) {
    // Collect Bloom's distribution if specified
    final bloomsInstructions = <String>[];

    for (var task in tasks) {
      if (task.questionType.bloomsDistribution.isNotEmpty) {
        final distString = task.questionType.bloomsDistribution.map((d) => '${d.count} questions at "${d.level}" level').join(', ');
        bloomsInstructions.add(distString);
      } else if (task.questionType.bloomsLevel != 'Mixed') {
        bloomsInstructions.add('Questions targeting "${task.questionType.bloomsLevel}" cognitive level');
      }
    }

    final bloomsInstruction = bloomsInstructions.isNotEmpty
        ? 'STRICT COGNITIVE DISTRIBUTION: ${bloomsInstructions.join("; ")}'
        : 'Vary Bloom\'s Taxonomy levels (Remember to Create) appropriate for the difficulty.';

    // Build section mapping for distribution
    final sectionMapping = tasks.asMap().entries.map((entry) {
      final index = entry.key;
      final task = entry.value;
      return {
        'sectionIndex': index,
        'sectionName': task.section.name,
        'sectionId': task.section.id,
        'easy': task.questionType.count.easy,
        'medium': task.questionType.count.medium,
        'hard': task.questionType.count.hard,
      };
    }).toList();

    return '''
Generate a batch of "$typeName" questions for multiple exam sections.

SYLLABUS CONTEXT:
$syllabusContext

GENERATION REQUIREMENTS:
1. Question Type: "$typeName"
2. Total Quantity: Easy ($totalEasy), Medium ($totalMedium), Hard ($totalHard)
3. Section Distribution: ${jsonEncode(sectionMapping)}
4. $bloomsInstruction

Generate exactly ${(totalEasy + totalMedium + totalHard) * batch} questions total.
Ensure syllabus coverage is wide and concepts are distributed evenly.
''';
  }

  // Parse scenario batch response
  Future<List<Question>> _parseScenarioBatchResponse(String response, List<ScenarioGenerationRequest> requests, int batch, String examId) async {
    final List<Question> generatedQuestions = [];

    try {
      final rawData = _cleanAndParseJson(response);

      if (rawData is! List) {
        debugPrint('Expected array response for scenario batch');
        return generatedQuestions;
      }

      for (var scenarioData in rawData) {
        final scenarioIndex = scenarioData['scenarioIndex'] as int?;

        if (scenarioIndex == null || scenarioIndex >= requests.length) {
          debugPrint('Invalid scenarioIndex: $scenarioIndex');
          continue;
        }

        final request = requests[scenarioIndex];
        final section = request.section;
        final qt = request.questionType;
        final scenarioConfig = request.scenarioConfig;

        final scenarioText = scenarioData['scenarioText'] as String? ?? '';
        final subQuestionsData = scenarioData['subQuestions'] as List? ?? [];

        // Calculate total marks for scenario
        final totalMarks = scenarioConfig.subQuestions.fold<int>(0, (sum, sq) => sum + (sq.marks * sq.count));

        // Parse sub-questions
        final subQuestions = <SubQuestion>[];

        for (var i = 0; i < subQuestionsData.length; i++) {
          final sqData = subQuestionsData[i];

          final subQ = SubQuestion(
            text: sqData['text'] as String? ?? '',
            type: sqData['type'] as String? ?? 'Short Answer',
            marks: sqData['marks'] as int? ?? scenarioConfig.subQuestions[i].marks,
            difficulty: sqData['difficulty'] as String? ?? scenarioConfig.subQuestions[i].difficulty,
            bloomsLevel: sqData['bloomsLevel'] as String? ?? scenarioConfig.subQuestions[i].bloomsLevel,
            modelAnswer: sqData['modelAnswer'] as String? ?? '',
            rubric: (sqData['rubric'] as List?)?.map((e) => e.toString()).toList() ?? [],
            options: (sqData['options'] as List?)?.map((e) => e.toString()).toList(),
            negativeValue: qt.negativeMarks ? qt.negativeValue : 0,
            allowPartial: qt.partialScoring,
            isOrType: false,
            concept: scenarioConfig.topic,
            latexVersion: sqData['latex'],
          );

          subQuestions.add(subQ);
        }

        // Create scenario question
        final scenarioQ = Question(
          id: 'sc_${DateTime.now().millisecondsSinceEpoch}_${batch}_${scenarioConfig.id}',
          sectionId: section.id,
          sectionName: section.name,
          text: scenarioText,
          concept: scenarioConfig.topic,
          difficulty: 'Hard',
          type: 'Scenario Based',
          marks: totalMarks,
          modelAnswer: 'Refer to sub-questions.',
          rubric: [],
          negativeValue: 0,
          allowPartial: true,
          isOrType: false,
          isScenario: true,
          scenarioText: scenarioText,
          subQuestions: subQuestions,
          examId: _currentExamId,
          latexVersion: scenarioData['latex'],
        );

        generatedQuestions.add(scenarioQ);
      }
    } catch (e) {
      debugPrint('Error parsing scenario batch response: $e');
    }

    return generatedQuestions;
  }

  // Parse standard questions batch response
  Future<List<Question>> _parseStandardBatchResponse(String response, List<QuestionTypeTask> tasks, int batch, String examId) async {
    List<Question> generatedQuestions = [];

    try {
      final rawBatch = _cleanAndParseJson(response);

      // if (rawBatch is! List) {
      //   debugPrint('Expected array response for standard batch');
      //   return generatedQuestions;
      // }

      // if (kDebugMode) {
      //   debugPrint("raw batch: $rawBatch");
      // }

      for (var qData in rawBatch) {
        // if (kDebugMode) {
        //   debugPrint("qData: $qData");
        // }
        final sectionIndex = qData['sectionIndex'] as int?;

        if (sectionIndex == null || sectionIndex >= tasks.length) {
          debugPrint('Invalid sectionIndex in standard batch: $sectionIndex');
          continue;
        }

        final task = tasks[sectionIndex];
        final section = task.section;
        final qt = task.questionType;

        final question = Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_${batch}_${generatedQuestions.length}',
          sectionId: section.id,
          sectionName: section.name,
          text: qData['text'] as String? ?? '',
          concept: qData['concept'] as String? ?? '',
          difficulty: qData['difficulty'] as String? ?? 'Medium',
          type: qData['type'] as String? ?? qt.type,
          marks: qt.marks,
          modelAnswer: qData['modelAnswer'] as String? ?? '',
          rubric: (qData['rubric'] as List?)?.map((e) => e.toString()).toList() ?? [],
          options: (qData['options'] as List?)?.map((e) => e.toString()).toList(),
          matchingPairs: (qData['matchingPairs'] as List?)?.map((pair) {
            return MatchingPair(left: pair['left'] as String? ?? '', right: pair['right'] as String? ?? '');
          }).toList(),
          negativeValue: qt.negativeMarks ? qt.negativeValue : 0,
          allowPartial: qt.partialScoring,
          isOrType: qData['isOrType'] as bool? ?? false,
          orGroupId: qData['orGroupId'] as String? ?? '',
          bloomsLevel: qData['bloomsLevel'] as String? ?? qt.bloomsLevel,
          examId: _currentExamId,
          latexVersion: qData['latexVersion'] as String? ?? '',
        );

        generatedQuestions.add(question);
      }
    } catch (e) {
      debugPrint('Error parsing standard batch response: $e');
    }

    return generatedQuestions;
  }

  dynamic _cleanAndParseJson(String text) {
    try {
      // 1. Remove Markdown code fences if present
      final cleaned = text.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '').trim();

      // 2. Decode JSON directly
      final decoded = jsonDecode(cleaned);

      // 3. Enforce expected top-level type (array)
      if (decoded is! List) {
        throw const FormatException('Expected top-level JSON array');
      }

      return decoded;
    } catch (e, stack) {
      debugPrint('JSON parse error: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  // Helper method to clean and parse JSON (matches your JS implementation)
  /*dynamic _cleanAndParseJson(String text) {
    try {
      // Remove markdown code blocks
      String cleaned = text.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '').trim();

      // Protect LaTeX commands
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\\(text|tau|theta|times|tan|to|tiny|nu|neq|nabla|not|natural|rho|right|Re|ragged|beta|bar|bf|bullet|frac|forall|phi)'),
        (match) => '\\\\${match.group(1)}',
      );

      // Find JSON start
      final firstBrace = cleaned.indexOf('{');
      final firstBracket = cleaned.indexOf('[');

      int start = -1;
      if (firstBrace != -1 && firstBracket != -1) {
        start = firstBrace < firstBracket ? firstBrace : firstBracket;
      } else if (firstBrace != -1) {
        start = firstBrace;
      } else if (firstBracket != -1) {
        start = firstBracket;
      }

      if (start == -1) return null;

      // Extract JSON using stack-based parsing
      final stack = <String>[];
      bool inString = false;
      bool escaped = false;
      int end = -1;

      for (int i = start; i < cleaned.length; i++) {
        final char = cleaned[i];

        if (escaped) {
          escaped = false;
          continue;
        }

        if (char == '\\') {
          escaped = true;
          continue;
        }

        if (char == '"') {
          inString = !inString;
          continue;
        }

        if (!inString) {
          if (char == '{' || char == '[') {
            stack.add(char);
          } else if (char == '}' || char == ']') {
            if (stack.isEmpty) break;
            final last = stack.removeLast();
            if ((char == '}' && last != '{') || (char == ']' && last != '[')) {
              break;
            }
            if (stack.isEmpty) {
              end = i;
              break;
            }
          }
        }
      }

      String jsonStr = end != -1 ? cleaned.substring(start, end + 1) : cleaned.substring(start);

      // Clean trailing commas
      jsonStr = jsonStr.replaceAllMapped(RegExp(r',\s*([\]}])'), (match) => match.group(1)!);

      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }*/
}

// Helper classes
class ScenarioGenerationRequest {
  final ExamSection section;
  final QuestionTypeConfig questionType;
  final ScenarioConfig scenarioConfig;

  ScenarioGenerationRequest({required this.section, required this.questionType, required this.scenarioConfig});
}
