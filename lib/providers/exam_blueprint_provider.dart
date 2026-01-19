import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exam_blueprint_model.dart';
import '../models/exam_config.dart';

class ExamBlueprintProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ExamBlueprint> _blueprints = [];
  bool _isLoading = false;
  String? _error;

  List<ExamBlueprint> get blueprints => _blueprints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all blueprints for the current user
  Future<void> fetchBlueprints() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('exam_blueprints').select().eq('user_id', userId).order('created_at', ascending: false);

      _blueprints = (response as List).map((json) => ExamBlueprint.fromJson(json as Map<String, dynamic>)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create a new exam blueprint
  Future<ExamBlueprint> createBlueprint({
    required String name,
    String? description,
    required List<ExamSection> sections,
    List<String> importantChapters = const [],
    int importancePercentage = 70,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final blueprint = ExamBlueprint(
        id: '', // Will be set by Supabase
        userId: userId,
        name: name,
        description: description,
        sections: sections,
        importantChapters: importantChapters,
        importancePercentage: importancePercentage,
        createdAt: now,
        updatedAt: now,
      );

      final response = await _supabase
          .from('exam_blueprints')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'sections': sections.map((e) => e.toJson()).toList(),
            'important_chapters': importantChapters,
            'importance_percentage': importancePercentage,
          })
          .select()
          .single();

      final createdBlueprint = ExamBlueprint.fromJson(response);
      _blueprints.insert(0, createdBlueprint);

      _isLoading = false;
      notifyListeners();

      return createdBlueprint;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing blueprint
  Future<void> updateBlueprint({
    required String blueprintId,
    String? name,
    String? description,
    List<ExamSection>? sections,
    List<String>? importantChapters,
    int? importancePercentage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (sections != null) {
        updateData['sections'] = sections.map((e) => e.toJson()).toList();
      }
      if (importantChapters != null) {
        updateData['important_chapters'] = importantChapters;
      }
      if (importancePercentage != null) {
        updateData['importance_percentage'] = importancePercentage;
      }

      final response = await _supabase.from('exam_blueprints').update(updateData).eq('id', blueprintId).select().single();

      final updatedBlueprint = ExamBlueprint.fromJson(response);

      final index = _blueprints.indexWhere((b) => b.id == blueprintId);
      if (index != -1) {
        _blueprints[index] = updatedBlueprint;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a blueprint
  Future<void> deleteBlueprint(String blueprintId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('exam_blueprints').delete().eq('id', blueprintId);

      _blueprints.removeWhere((b) => b.id == blueprintId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get a single blueprint by ID
  Future<ExamBlueprint?> getBlueprintById(String blueprintId) async {
    try {
      final response = await _supabase.from('exam_blueprints').select().eq('id', blueprintId).single();

      return ExamBlueprint.fromJson(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Duplicate a blueprint
  Future<ExamBlueprint> duplicateBlueprint(String blueprintId) async {
    final original = await getBlueprintById(blueprintId);
    if (original == null) {
      throw Exception('Blueprint not found');
    }

    return createBlueprint(
      name: '${original.name} (Copy)',
      description: original.description,
      sections: original.sections,
      importantChapters: original.importantChapters,
      importancePercentage: original.importancePercentage,
    );
  }

  /*/// Export blueprint to XML (similar to web version)
  String exportToXml(ExamBlueprint blueprint) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<blueprint>');
    buffer.writeln('  <examName>${_escapeXml(blueprint.name)}</examName>');
    buffer.writeln('  <sections>');

    for (final section in blueprint.sections) {
      buffer.writeln('    <section id="${section.id}">');
      buffer.writeln('      <name>${_escapeXml(section.name)}</name>');
      buffer.writeln('      <questionTypes>');

      for (final qt in section.questionTypes) {
        final hasStandard = (qt.count['Easy']! + qt.count['Medium']! + qt.count['Hard']!) > 0;
        final hasScenarios = qt.type == 'Scenario Based' && (qt.scenarios?.isNotEmpty ?? false);

        if (hasStandard || hasScenarios || qt.orCount > 0) {
          buffer.writeln('        <questionType type="${qt.type}">');
          buffer.writeln('          <marks>${qt.marks}</marks>');
          buffer.writeln('          <count easy="${qt.count['Easy']}" medium="${qt.count['Medium']}" hard="${qt.count['Hard']}" />');

          if (qt.negativeMarks) {
            buffer.writeln('          <negativeMarking value="${qt.negativeValue}" />');
          }
          if (qt.partialScoring) {
            buffer.writeln('          <partialScoring>true</partialScoring>');
          }
          if (qt.orCount > 0) {
            buffer.writeln('          <orCount>${qt.orCount}</orCount>');
          }
          if (qt.bloomsLevel != null) {
            buffer.writeln('          <bloomsLevel>${qt.bloomsLevel}</bloomsLevel>');
          }

          buffer.writeln('        </questionType>');
        }
      }

      buffer.writeln('      </questionTypes>');
      buffer.writeln('    </section>');
    }

    buffer.writeln('  </sections>');
    buffer.writeln('</blueprint>');

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&apos;');
  }*/

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
