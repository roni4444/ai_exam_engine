import 'package:flutter/material.dart';

/// Model for a candidate/student
class Candidate {
  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? rollNumber;
  final String? class_;
  final String? section;
  final Map<String, dynamic>? metadata; // Additional custom fields
  final DateTime createdAt;
  final DateTime updatedAt;

  Candidate({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.rollNumber,
    this.class_,
    this.section,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'email': email,
    'roll_number': rollNumber,
    'class': class_,
    'section': section,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      rollNumber: json['roll_number'] as String?,
      class_: json['class'] as String?,
      section: json['section'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Create a copy with updated fields
  Candidate copyWith({String? name, String? email, String? rollNumber, String? class_, String? section, Map<String, dynamic>? metadata}) {
    return Candidate(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      rollNumber: rollNumber ?? this.rollNumber,
      class_: class_ ?? this.class_,
      section: section ?? this.section,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Model for candidate groups/batches
class CandidateGroup {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> candidateIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  CandidateGroup({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.candidateIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'candidate_ids': candidateIds,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CandidateGroup.fromJson(Map<String, dynamic> json) {
    return CandidateGroup(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      candidateIds: List<String>.from(json['candidate_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
