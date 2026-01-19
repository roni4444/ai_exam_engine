import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/candidate_model.dart';

class CandidateProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Candidate> _candidates = [];
  List<CandidateGroup> _groups = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _searchQuery;
  String? _classFilter;
  String? _sectionFilter;

  List<Candidate> get candidates {
    var filtered = _candidates;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
            (c.email.toLowerCase().contains(_searchQuery!.toLowerCase())) ||
            (c.rollNumber?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false);
      }).toList();
    }

    if (_classFilter != null) {
      filtered = filtered.where((c) => c.class_ == _classFilter).toList();
    }

    if (_sectionFilter != null) {
      filtered = filtered.where((c) => c.section == _sectionFilter).toList();
    }

    return filtered;
  }

  List<CandidateGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  String? get classFilter => _classFilter;
  String? get sectionFilter => _sectionFilter;

  /// Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set class filter
  void setClassFilter(String? class_) {
    _classFilter = class_;
    notifyListeners();
  }

  /// Set section filter
  void setSectionFilter(String? section) {
    _sectionFilter = section;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = null;
    _classFilter = null;
    _sectionFilter = null;
    notifyListeners();
  }

  /// Fetch all candidates for the current user
  Future<void> fetchCandidates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('candidates').select().eq('user_id', userId).order('name', ascending: true);

      _candidates = (response as List).map((json) => Candidate.fromJson(json as Map<String, dynamic>)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch all candidate groups
  Future<void> fetchGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('candidate_groups').select().eq('user_id', userId).order('created_at', ascending: false);

      _groups = (response as List).map((json) => CandidateGroup.fromJson(json as Map<String, dynamic>)).toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
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

  /// Create a new candidate
  Future<Candidate> createCandidate({
    required String name,
    String? email,
    String? phone,
    String? rollNumber,
    String? class_,
    String? section,
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('candidates')
          .insert({
            'user_id': userId,
            'name': name,
            'email': email,
            'phone': phone,
            'roll_number': rollNumber,
            'class': class_,
            'section': section,
            'metadata': metadata,
          })
          .select()
          .single();

      final candidate = Candidate.fromJson(response);
      _candidates.add(candidate);

      _isLoading = false;
      notifyListeners();

      return candidate;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Bulk import candidates from CSV-like data
  Future<List<Candidate>> importCandidates(List<Map<String, dynamic>> candidateData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final insertData = candidateData.map((data) {
        return {
          'user_id': userId,
          'name': data['name'] as String,
          'email': data['email'] as String?,
          'phone': data['phone'] as String?,
          'roll_number': data['roll_number'] as String?,
          'class': data['class'] as String?,
          'section': data['section'] as String?,
          'metadata': data['metadata'] as Map<String, dynamic>?,
        };
      }).toList();

      final response = await _supabase.from('candidates').insert(insertData).select();

      final newCandidates = (response as List).map((json) => Candidate.fromJson(json as Map<String, dynamic>)).toList();

      _candidates.addAll(newCandidates);

      _isLoading = false;
      notifyListeners();

      return newCandidates;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update a candidate
  Future<void> updateCandidate({
    required String candidateId,
    String? name,
    String? email,
    String? phone,
    String? rollNumber,
    String? class_,
    String? section,
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (rollNumber != null) updateData['roll_number'] = rollNumber;
      if (phone != null) updateData['phone'] = phone;
      if (class_ != null) updateData['class'] = class_;
      if (section != null) updateData['section'] = section;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await _supabase.from('candidates').update(updateData).eq('id', candidateId).select().single();

      final updatedCandidate = Candidate.fromJson(response);

      final index = _candidates.indexWhere((c) => c.id == candidateId);
      if (index != -1) {
        _candidates[index] = updatedCandidate;
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

  /// Delete a candidate
  Future<void> deleteCandidate(String candidateId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('candidates').delete().eq('id', candidateId);

      _candidates.removeWhere((c) => c.id == candidateId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete multiple candidates
  Future<void> deleteCandidates(List<String> candidateIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('candidates').delete().inFilter('id', candidateIds);

      _candidates.removeWhere((c) => candidateIds.contains(c.id));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create a candidate group
  Future<CandidateGroup> createGroup({required String name, String? description, required List<String> candidateIds}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('candidate_groups')
          .insert({'user_id': userId, 'name': name, 'description': description, 'candidate_ids': candidateIds})
          .select()
          .single();

      final groupId = response['id'];
      final associations = candidateIds
          .map((candidateId) => {'candidate_id': candidateId, 'group_id': groupId, 'assigned_at': DateTime.now().toIso8601String()})
          .toList();

      await _supabase.from('candidate_group_members').insert(associations);

      final group = CandidateGroup.fromJson(response);
      _groups.insert(0, group);

      _isLoading = false;
      notifyListeners();

      return group;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update a candidate group
  Future<void> updateGroup({required String groupId, String? name, String? description, List<String>? candidateIds}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (candidateIds != null) updateData['candidate_ids'] = candidateIds;

      final response = await _supabase.from('candidate_groups').update(updateData).eq('id', groupId).select().single();

      final updatedGroup = CandidateGroup.fromJson(response);

      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup;
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

  /// Delete a candidate group
  Future<void> deleteGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('candidate_groups').delete().eq('id', groupId);

      _groups.removeWhere((g) => g.id == groupId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get candidates by group ID
  List<Candidate> getCandidatesByGroup(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Group not found'));

    return _candidates.where((c) => group.candidateIds.contains(c.id)).toList();
  }

  /// Get unique class values
  List<String> get uniqueClasses {
    return _candidates.map((c) => c.class_).where((c) => c != null).cast<String>().toSet().toList()..sort();
  }

  /// Get unique section values
  List<String> get uniqueSections {
    return _candidates.map((c) => c.section).where((s) => s != null).cast<String>().toSet().toList()..sort();
  }

  /// Export candidates to CSV format
  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Name,Email,Roll Number,Class,Section');

    for (final candidate in _candidates) {
      buffer.writeln(
        '${_escapeCsv(candidate.name)},${_escapeCsv(candidate.email)},${_escapeCsv(candidate.rollNumber ?? '')},${_escapeCsv(candidate.class_ ?? '')},${_escapeCsv(candidate.section ?? '')}',
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
