import 'package:ai_exam_engine/models/candidate_model.dart';

class ExamConfig {
  final String examName;
  final int studentCount;
  final List<Candidate> studentNames;
  final List<ExamSection> sections;
  final List<String> importantChapters;
  final int importancePercentage;

  ExamConfig({
    required this.examName,
    required this.studentCount,
    required this.studentNames,
    required this.sections,
    this.importantChapters = const [],
    this.importancePercentage = 70,
  });

  Map<String, dynamic> toJson() => {
    'examName': examName,
    'studentCount': studentCount,
    'studentNames': studentNames,
    'sections': sections.map((s) => s.toJson()).toList(),
    'importantChapters': importantChapters,
    'importancePercentage': importancePercentage,
  };

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
    examName: json['examName'] ?? 'Exam',
    studentCount: json['studentCount'] ?? 1,
    studentNames: List<Candidate>.from(json['studentNames'] ?? []),
    sections: (json['sections'] as List?)?.map((s) => ExamSection.fromJson(s)).toList() ?? [],
    importantChapters: List<String>.from(json['importantChapters'] ?? []),
    importancePercentage: json['importancePercentage'] ?? 70,
  );
}

class ExamSection {
  final String id;
  final String name;
  final List<QuestionTypeConfig> questionTypes;

  ExamSection({required this.id, required this.name, required this.questionTypes});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'questionTypes': questionTypes.map((q) => q.toJson()).toList()};

  factory ExamSection.fromJson(Map<String, dynamic> json) => ExamSection(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    questionTypes: (json['questionTypes'] as List?)?.map((q) => QuestionTypeConfig.fromJson(q)).toList() ?? [],
  );
}

class QuestionTypeConfig {
  final String type;
  final int marks;
  final DifficultyCount count;
  final bool negativeMarks;
  final double negativeValue;
  final bool partialScoring;
  final int orCount;
  final String bloomsLevel;
  final List<BloomsDistribution> bloomsDistribution;
  final List<ScenarioConfig> scenarios;

  QuestionTypeConfig({
    required this.type,
    this.marks = 1,
    DifficultyCount? count,
    this.negativeMarks = false,
    this.negativeValue = 0.25,
    this.partialScoring = false,
    this.orCount = 0,
    this.bloomsLevel = 'Mixed',
    this.bloomsDistribution = const [],
    this.scenarios = const [],
  }) : count = count ?? DifficultyCount();

  Map<String, dynamic> toJson() => {
    'type': type,
    'marks': marks,
    'count': count.toJson(),
    'negativeMarks': negativeMarks,
    'negativeValue': negativeValue,
    'partialScoring': partialScoring,
    'orCount': orCount,
    'bloomsLevel': bloomsLevel,
    'bloomsDistribution': bloomsDistribution.map((b) => b.toJson()).toList(),
    'scenarios': scenarios.map((s) => s.toJson()).toList(),
  };

  factory QuestionTypeConfig.fromJson(Map<String, dynamic> json) => QuestionTypeConfig(
    type: json['type'] ?? 'Multiple Choice',
    marks: json['marks'] ?? 1,
    count: json['count'] != null ? DifficultyCount.fromJson(json['count']) : DifficultyCount(),
    negativeMarks: json['negativeMarks'] ?? false,
    negativeValue: (json['negativeValue'] ?? 0.25).toDouble(),
    partialScoring: json['partialScoring'] ?? false,
    orCount: json['orCount'] ?? 0,
    bloomsLevel: json['bloomsLevel'] ?? 'Mixed',
    bloomsDistribution: (json['bloomsDistribution'] as List?)?.map((b) => BloomsDistribution.fromJson(b)).toList() ?? [],
    scenarios: (json['scenarios'] as List?)?.map((s) => ScenarioConfig.fromJson(s)).toList() ?? [],
  );

  QuestionTypeConfig copyWith({
    String? type,
    int? marks,
    DifficultyCount? count,
    bool? negativeMarks,
    double? negativeValue,
    bool? partialScoring,
    int? orCount,
    String? bloomsLevel,
    List<BloomsDistribution>? bloomsDistribution,
    List<ScenarioConfig>? scenarios,
  }) {
    return QuestionTypeConfig(
      type: type ?? this.type,
      marks: marks ?? this.marks,
      count: count ?? this.count,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      negativeValue: negativeValue ?? this.negativeValue,
      partialScoring: partialScoring ?? this.partialScoring,
      orCount: orCount ?? this.orCount,
      bloomsLevel: bloomsLevel ?? this.bloomsLevel,
      bloomsDistribution: bloomsDistribution ?? this.bloomsDistribution,
      scenarios: scenarios ?? this.scenarios,
    );
  }
}

class DifficultyCount {
  int easy;
  int medium;
  int hard;

  DifficultyCount({this.easy = 0, this.medium = 0, this.hard = 0});

  Map<String, dynamic> toJson() => {'Easy': easy, 'Medium': medium, 'Hard': hard};

  factory DifficultyCount.fromJson(Map<String, dynamic> json) =>
      DifficultyCount(easy: json['Easy'] ?? 0, medium: json['Medium'] ?? 0, hard: json['Hard'] ?? 0);

  DifficultyCount copyWith({int? easy, int? medium, int? hard}) {
    return DifficultyCount(easy: easy ?? this.easy, medium: medium ?? this.medium, hard: hard ?? this.hard);
  }
}

class BloomsDistribution {
  final String level;
  final int count;

  BloomsDistribution({required this.level, required this.count});

  Map<String, dynamic> toJson() => {'level': level, 'count': count};

  factory BloomsDistribution.fromJson(Map<String, dynamic> json) => BloomsDistribution(level: json['level'] ?? 'Remember', count: json['count'] ?? 0);
}

class ScenarioConfig {
  final String id;
  final String topic;
  final List<SubQuestionConfig> subQuestions;

  ScenarioConfig({required this.id, required this.topic, required this.subQuestions});

  Map<String, dynamic> toJson() => {'id': id, 'topic': topic, 'subQuestions': subQuestions.map((s) => s.toJson()).toList()};

  factory ScenarioConfig.fromJson(Map<String, dynamic> json) => ScenarioConfig(
    id: json['id'] ?? '',
    topic: json['topic'] ?? '',
    subQuestions: (json['subQuestions'] as List?)?.map((s) => SubQuestionConfig.fromJson(s)).toList() ?? [],
  );
}

class SubQuestionConfig {
  final String type;
  final int marks;
  final int count;
  final String difficulty;
  final String bloomsLevel;

  SubQuestionConfig({required this.type, required this.marks, required this.count, required this.difficulty, required this.bloomsLevel});

  Map<String, dynamic> toJson() => {'type': type, 'marks': marks, 'count': count, 'difficulty': difficulty, 'bloomsLevel': bloomsLevel};

  factory SubQuestionConfig.fromJson(Map<String, dynamic> json) => SubQuestionConfig(
    type: json['type'] ?? 'Multiple Choice',
    marks: json['marks'] ?? 1,
    count: json['count'] ?? 1,
    difficulty: json['difficulty'] ?? 'Medium',
    bloomsLevel: json['bloomsLevel'] ?? 'Analyze',
  );
}

/*

class AnalyzedChapter {
  final String title;
  final List<ChapterConcept> concepts;

  AnalyzedChapter({required this.title, required this.concepts});

  Map<String, dynamic> toJson() => {'title': title, 'concepts': concepts.map((c) => c.toJson()).toList()};

  factory AnalyzedChapter.fromJson(Map<String, dynamic> json) =>
      AnalyzedChapter(title: json['title'] ?? '', concepts: (json['concepts'] as List?)?.map((c) => ChapterConcept.fromJson(c)).toList() ?? []);
}

class ChapterConcept {
  final String name;
  final String description;
  final String type;

  ChapterConcept({required this.name, required this.description, required this.type});

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'type': type};

  factory ChapterConcept.fromJson(Map<String, dynamic> json) =>
      ChapterConcept(name: json['name'] ?? '', description: json['description'] ?? '', type: json['type'] ?? 'general');
}
*/
