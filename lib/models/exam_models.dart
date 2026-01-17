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
  final String sectionId;
  final String sectionName;
  final String text;
  final String concept;
  final String difficulty;
  final String type;
  final int marks;
  final String modelAnswer;
  final List<String> rubric;
  final List<String>? options;
  final List<MatchingPair>? matchingPairs;
  final double negativeValue;
  final bool allowPartial;
  final bool isOrType;
  final String? orGroupId;
  final String? bloomsLevel;
  final bool isScenario;
  final String? scenarioText;
  final List<Question>? subQuestions;

  Question({
    required this.id,
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
    required this.negativeValue,
    required this.allowPartial,
    required this.isOrType,
    this.orGroupId,
    this.bloomsLevel,
    this.isScenario = false,
    this.scenarioText,
    this.subQuestions,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      sectionId: json['sectionId'] ?? '',
      sectionName: json['sectionName'] ?? '',
      text: json['text'],
      concept: json['concept'] ?? '',
      difficulty: json['difficulty'],
      type: json['type'],
      marks: json['marks'],
      modelAnswer: json['modelAnswer'] ?? '',
      rubric: List<String>.from(json['rubric'] ?? []),
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      matchingPairs: json['matchingPairs'] != null ? (json['matchingPairs'] as List).map((m) => MatchingPair.fromJson(m)).toList() : null,
      negativeValue: (json['negativeValue'] ?? 0.0).toDouble(),
      allowPartial: json['allowPartial'] ?? false,
      isOrType: json['isOrType'] ?? false,
      orGroupId: json['orGroupId'],
      bloomsLevel: json['bloomsLevel'],
      isScenario: json['isScenario'] ?? false,
      scenarioText: json['scenarioText'],
      subQuestions: json['subQuestions'] != null ? (json['subQuestions'] as List).map((q) => Question.fromJson(q)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
    };
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
    return ExamRecord(id: json['id'], name: json['name'], state: json['state'], createdAt: DateTime.parse(json['created_at']));
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
