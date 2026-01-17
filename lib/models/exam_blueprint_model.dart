import 'package:flutter/material.dart';

import 'exam_config.dart';

class ExamBlueprint {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<ExamSection> sections;
  final List<String> importantChapters;
  final int importancePercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamBlueprint({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.sections,
    this.importantChapters = const [],
    this.importancePercentage = 70,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'sections': sections.map((e) => e.toJson()).toList(),
    'important_chapters': importantChapters,
    'importance_percentage': importancePercentage,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ExamBlueprint.fromJson(Map<String, dynamic> json) {
    return ExamBlueprint(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sections: (json['sections'] as List).map((e) => ExamSection.fromJson(e as Map<String, dynamic>)).toList(),
      importantChapters: List<String>.from(json['important_chapters'] ?? []),
      importancePercentage: json['importance_percentage'] as int? ?? 70,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Calculate total questions in blueprint
  int get totalQuestions {
    int total = 0;
    for (final section in sections) {
      for (final qt in section.questionTypes) {
        total += qt.count.easy + qt.count.medium + qt.count.hard;
        total += qt.scenarios.length;
      }
    }
    return total;
  }

  /// Calculate total marks in blueprint
  double get totalMarks {
    double total = 0;
    for (final section in sections) {
      for (final qt in section.questionTypes) {
        if (qt.type == 'Scenario Based' && qt.scenarios.isNotEmpty) {
          for (final scenario in qt.scenarios) {
            for (final sq in scenario.subQuestions) {
              total += sq.marks * sq.count;
            }
          }
        } else {
          final count = qt.count.easy + qt.count.medium + qt.count.hard;
          total += qt.marks * count;
        }
      }
    }
    return total;
  }
}
