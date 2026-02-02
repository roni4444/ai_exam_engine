import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String? institutionName;
  final String? designation;
  final String? usagePurpose;
  final String? childrenNames;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.institutionName,
    this.designation,
    this.usagePurpose,
    this.childrenNames,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      role: json['role'],
      institutionName: json['institution_name'],
      designation: json['designation'],
      usagePurpose: json['usage_purpose'],
      childrenNames: json['children_names'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'institution_name': institutionName,
      'designation': designation,
      'usage_purpose': usagePurpose,
      'children_names': childrenNames,
    };
  }
}

class ChapterConcept {
  final String name;
  final String description;
  final String type;

  ChapterConcept({required this.name, required this.description, required this.type});

  factory ChapterConcept.fromJson(Map<String, dynamic> json) {
    return ChapterConcept(name: json['name'], description: json['description'], type: json['type']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'type': type};
  }
}

class AnalyzedChapter {
  final String title;
  final List<ChapterConcept> concepts;

  AnalyzedChapter({required this.title, required this.concepts});

  factory AnalyzedChapter.fromJson(Map<String, dynamic> json) {
    return AnalyzedChapter(title: json['title'], concepts: (json['concepts'] as List).map((c) => ChapterConcept.fromJson(c)).toList());
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'concepts': concepts.map((c) => c.toJson()).toList()};
  }
}

class Question {
  final String id;
  final String examId;
  final String sectionId;
  final String sectionName;

  final String text;
  final String concept;
  final String difficulty;
  final String type;
  final int marks;

  final String modelAnswer;
  final List<String> rubric;

  final Map<String, String>? options;
  final List<MatchingPair>? matchingPairs;
  final String? correctOption;

  final double negativeValue;
  final bool allowPartial;

  final bool isOrType;
  final String? orGroupId;

  final String? bloomsLevel;

  final bool isScenario;
  final String? scenarioId;
  final String? scenarioText;

  final List<SubQuestion>? subQuestions;

  final LatexBlock latexVersion;
  final String latexPackages;
  final String latexEngine;

  Question({
    required this.id,
    required this.examId,
    required this.sectionId,
    required this.sectionName,
    required this.text,
    required this.concept,
    required this.difficulty,
    required this.type,
    required this.marks,
    required this.modelAnswer,
    required this.rubric,
    this.options,
    this.matchingPairs,
    this.correctOption,
    required this.negativeValue,
    required this.allowPartial,
    required this.isOrType,
    this.orGroupId,
    this.bloomsLevel,
    required this.isScenario,
    this.scenarioId,
    this.scenarioText,
    this.subQuestions,
    required this.latexVersion,
    required this.latexPackages,
    required this.latexEngine,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      examId: json['exam_id'],
      sectionId: json['sectionId'] ?? '',
      sectionName: json['sectionName'] ?? '',
      text: json['text'],
      concept: json['concept'] ?? '',
      difficulty: json['difficulty'],
      type: json['type'],
      marks: json['marks'],
      modelAnswer: json['modelAnswer'] ?? '',
      rubric: List<String>.from(json['rubric'] ?? []),
      options: json['options'] != null ? Map<String, String>.from(json['options']) : null,
      matchingPairs: json['matchingPairs'] != null ? (json['matchingPairs'] as List).map((m) => MatchingPair.fromJson(m)).toList() : null,
      negativeValue: (json['negativeValue'] ?? 0.0).toDouble(),
      allowPartial: json['allowPartial'] ?? false,
      isOrType: json['isOrType'] ?? false,
      orGroupId: json['orGroupId'],
      bloomsLevel: json['bloomsLevel'],
      isScenario: json['isScenario'] ?? false,
      scenarioText: json['scenarioText'],
      subQuestions: json['subQuestions'] != null ? (json['subQuestions'] as List).map((q) => SubQuestion.fromJson(q)).toList() : null,
      latexVersion: LatexBlock.fromJson(json['latex_version']),
      latexPackages: json['latexPackages'],
      latexEngine: json['latexEngine'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'text': text,
      'concept': concept,
      'difficulty': difficulty,
      'type': type,
      'marks': marks,
      'modelAnswer': modelAnswer,
      'rubric': rubric,
      'options': options,
      'matchingPairs': matchingPairs?.map((m) => m.toJson()).toList(),
      'negativeValue': negativeValue,
      'allowPartial': allowPartial,
      'isOrType': isOrType,
      'orGroupId': orGroupId,
      'bloomsLevel': bloomsLevel,
      'isScenario': isScenario,
      'scenarioText': scenarioText,
      'subQuestions': subQuestions?.map((q) => q.toJson()).toList(),
      'latexVersion': latexVersion,
    };
  }

  factory Question.fromDBJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      examId: json['exam_id'],
      sectionId: json['section_id'] ?? '',
      sectionName: json['section_name'] ?? '',
      text: json['question'],
      concept: json['concept'] ?? '',
      difficulty: json['difficulty'],
      type: json['type'],
      marks: json['marks'],
      modelAnswer: json['model_answer'] ?? '',
      rubric: List<String>.from(json['rubric'] ?? []),
      options: json['options'] != null ? Map<String, String>.from(json['options']) : null,
      matchingPairs: json['matching_pairs'] != null ? (json['matching_pairs'] as List).map((m) => MatchingPair.fromJson(m)).toList() : null,
      negativeValue: (json['negative_value'] ?? 0.0).toDouble(),
      allowPartial: json['allow_partial'] ?? false,
      isOrType: json['is_or_type'] ?? false,
      orGroupId: json['or_group_id'],
      bloomsLevel: json['blooms_level'],
      isScenario: json['is_scenario'] ?? false,
      scenarioText: json['scenario_text'],
      subQuestions: json['sub_questions'] != null ? (json['sub_questions'] as List).map((q) => SubQuestion.fromJson(q)).toList() : null,
      latexVersion: LatexBlock.fromJson(json['latex_version']),
      latexPackages: json['latexPackages'],
      latexEngine: json['latexEngine'],
    );
  }

  Map<String, dynamic> toDBJson({required String examId}) {
    return {
      // identity
      'exam_id': examId,

      // section
      'section_id': sectionId,
      'section_name': sectionName,

      // core question
      'question': text,
      'concept': concept,
      'difficulty': difficulty,
      'type': type,
      'marks': marks,

      // evaluation
      'model_answer': modelAnswer,
      'rubric': rubric, // TEXT[]
      // MCQ / Matching
      'options': options, // Map<String,String> → JSONB
      'correct_option': correctOption,
      'matching_pairs': matchingPairs?.map((m) => m.toJson()).toList(),

      // marking rules
      'negative_value': negativeValue,
      'allow_partial': allowPartial,

      // OR logic
      'is_or_type': isOrType,
      'or_group_id': orGroupId,

      // taxonomy
      'blooms_level': bloomsLevel,

      // scenario
      'is_scenario': isScenario,
      'scenario_id': isScenario ? scenarioId : null,
      'scenario_text': isScenario ? scenarioText : null,

      // LaTeX (single block)
      'latex_version': latexVersion.toJson(),
      'latex_packages': latexPackages,
      'latex_engine': latexEngine,
    };
  }
}

class SubQuestion {
  final String text;
  final String concept;
  final String difficulty;
  final String type;
  final int marks;
  final String modelAnswer;
  final List<String> rubric;
  final Map<String, String>? options;
  final String? correctOption;
  final List<MatchingPair>? matchingPairs;
  final double negativeValue;
  final bool allowPartial;
  final String? bloomsLevel;
  final LatexBlock latexVersion;
  final String latexPackages;
  final String latexEngine;

  SubQuestion({
    required this.text,
    required this.concept,
    required this.difficulty,
    required this.type,
    required this.marks,
    required this.modelAnswer,
    required this.rubric,
    this.options,
    this.matchingPairs,
    required this.negativeValue,
    required this.allowPartial,
    this.bloomsLevel,
    required this.latexVersion,
    required this.latexPackages,
    required this.latexEngine,
    this.correctOption,
  });

  factory SubQuestion.fromJson(Map<String, dynamic> json) {
    return SubQuestion(
      text: json['text'],
      concept: json['concept'],
      difficulty: json['difficulty'],
      type: json['type'],
      marks: json['marks'],
      modelAnswer: json['modelAnswer'],
      rubric: List<String>.from(json['rubric']),
      options: json['options'] != null ? Map<String, String>.from(json['options']) : null,
      matchingPairs: json['matchingPairs'] != null ? (json['matchingPairs'] as List).map((m) => MatchingPair.fromJson(m)).toList() : null,
      negativeValue: (json['negativeValue'] ?? 0).toDouble(),
      allowPartial: json['allowPartial'] ?? false,
      bloomsLevel: json['bloomsLevel'],
      latexVersion: json['latexVersion'],
      latexPackages: json['latexPackages'],
      latexEngine: json['latexEngine'],
    );
  }

  Map<String, dynamic> toDBJson({required String parentQuestionId}) {
    return {
      'question_id': parentQuestionId,

      'question': text,
      'concept': concept,
      'difficulty': difficulty,
      'type': type,
      'marks': marks,

      'model_answer': modelAnswer,
      'rubric': rubric,

      'options': options,
      'correct_option': correctOption,
      'matching_pairs': matchingPairs?.map((m) => m.toJson()).toList(),

      'negative_value': negativeValue,
      'allow_partial': allowPartial,

      'blooms_level': bloomsLevel,

      'latex_version': latexVersion.toJson(),
      'latex_packages': latexPackages,
      'latex_engine': latexEngine,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'question': text,
      'concept': concept,
      'difficulty': difficulty,
      'type': type,
      'marks': marks,

      'model_answer': modelAnswer,
      'rubric': rubric,

      'options': options,
      'correct_option': correctOption,
      'matching_pairs': matchingPairs?.map((m) => m.toJson()).toList(),

      'negative_value': negativeValue,
      'allow_partial': allowPartial,

      'blooms_level': bloomsLevel,

      'latex_version': latexVersion.toJson(),
      'latex_packages': latexPackages,
      'latex_engine': latexEngine,
    };
  }
}

class QuestionGenerationProgress {
  final int current;
  final int total;
  final String status;
  final String? error;
  final bool isComplete;

  QuestionGenerationProgress({required this.current, required this.total, required this.status, this.error, this.isComplete = false});

  double get progress => total > 0 ? current / total : 0;

  factory QuestionGenerationProgress.fromJson(Map<String, dynamic> json) {
    return QuestionGenerationProgress(
      current: json['current'] ?? 0,
      total: json['total'] ?? 0,
      status: json['status'] ?? 'idle',
      error: json['error'],
      isComplete: json['is_complete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'current': current, 'total': total, 'status': status, 'error': error, 'is_complete': isComplete};
  }
}

class MatchingPair {
  final String left;
  final String right;

  MatchingPair({required this.left, required this.right});

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(left: json['left'], right: json['right']);
  }

  Map<String, dynamic> toJson() {
    return {'left': left, 'right': right};
  }
}

class Student {
  final String id;
  final String name;
  final String abilityLevel;

  Student({required this.id, required this.name, required this.abilityLevel});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(id: json['id'], name: json['name'], abilityLevel: json['abilityLevel'] ?? 'Average');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'abilityLevel': abilityLevel};
  }
}

class ExamRecord {
  final String id;
  final String name;
  final String state;
  final DateTime createdAt;

  ExamRecord({required this.id, required this.name, required this.state, required this.createdAt});

  factory ExamRecord.fromJson(Map<String, dynamic> json) {
    return ExamRecord(
      id: json['id'],
      name: json['name'] ?? "Exam",
      state: json['state'] ?? "Pre-Setup",
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class LibraryFile {
  final String id;
  final String name;
  final DateTime createdAt;
  final String fullPath;
  final String? url;
  final String? fileType;
  final int size;
  final String? language;
  final bool isGeminiProcessed;

  LibraryFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.fullPath,
    this.url,
    this.fileType,
    required this.size,
    this.language,
    required this.isGeminiProcessed,
  });

  factory LibraryFile.fromJson(Map<String, dynamic> json) {
    return LibraryFile(
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      fullPath: json['fullPath'],
      url: json['url'],
      fileType: json['fileType'],
      size: json['size'],
      language: json['language'],
      isGeminiProcessed: json['isGeminiProcessed'] ?? false,
      id: json['id'],
    );
  }
}

class LatexOptionBlock {
  final String A;
  final String B;
  final String C;
  final String D;

  LatexOptionBlock({required this.A, required this.B, required this.C, required this.D});

  factory LatexOptionBlock.fromJson(Map<String, dynamic> json) {
    return LatexOptionBlock(A: json['A'] ?? '', B: json['B'] ?? '', C: json['C'] ?? '', D: json['D'] ?? '');
  }
}

class LatexBlock {
  final String question;
  final String answer;
  final String rubric;
  final List<MatchingPair>? matchingPairs;
  final Map<String, String>? options;
  final String? correctOption;
  final String? scenarioText;

  LatexBlock({
    required this.question,
    required this.answer,
    required this.rubric,
    this.matchingPairs,
    this.options,
    this.correctOption,
    this.scenarioText,
  });

  factory LatexBlock.fromJson(Map<String, dynamic> json) {
    return LatexBlock(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      rubric: json['rubric'] ?? '',
      correctOption: json['correctOption'],
      scenarioText: json['scenarioText'],
      matchingPairs: (json['matchingPairs'] as List?)?.map((e) => MatchingPair(left: e['left'] ?? '', right: e['right'] ?? '')).toList(),
      options: json['options'] != null ? Map<String, String>.from(json['options']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'rubric': rubric,
      'correctOption': correctOption,
      'scenarioText': scenarioText,
      'matchingPairs': matchingPairs?.map((m) => {'left': m.left, 'right': m.right}).toList(),
      'options': options,
    };
  }
}
