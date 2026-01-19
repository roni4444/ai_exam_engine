import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';

import '../models/candidate_model.dart';
import '../providers/candidate_provider.dart';

// Modal dialog for creating a candidate group and assigning candidates
class CreateCandidateGroupModal extends StatefulWidget {
  final VoidCallback? onGroupCreated;

  const CreateCandidateGroupModal({super.key, this.onGroupCreated});

  @override
  State<CreateCandidateGroupModal> createState() => _CreateCandidateGroupModalState();
}

class _CreateCandidateGroupModalState extends State<CreateCandidateGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // bool _isLoading = false;
  // bool _isLoadingCandidates = true;
  String? _errorMessage;

  List<Candidate> allCandidates = [];
  Set<String> selectedCandidateIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // _loadCandidates();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /*Future<void> _loadCandidates() async {
    try {
      final supabase = Supabase.instance.client;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase.from('candidates').select().eq('user_id', userId).order('name', ascending: true);

      setState(() {
        _allCandidates = (response as List).map((json) => Candidate.fromJson(json)).toList();
        _isLoadingCandidates = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load candidates: $error';
        _isLoadingCandidates = false;
      });
    }
  }*/

  List<Candidate> get _filteredCandidates {
    allCandidates = context.read<CandidateProvider>().candidates;
    if (_searchQuery.isEmpty) return allCandidates;

    final query = _searchQuery.toLowerCase();
    return allCandidates.where((candidate) {
      return candidate.name.toLowerCase().contains(query) ||
          candidate.email.toLowerCase().contains(query) ||
          (candidate.rollNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /*Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCandidateIds.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one candidate';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Step 1: Create the candidate group
      final groupResponse = await supabase
          .from('candidate_groups')
          .insert({
            'name': _groupNameController.text.trim(),
            'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final groupId = groupResponse['id'];

      // Step 2: Create candidate-group associations
      final associations = selectedCandidateIds
          .map((candidateId) => {'candidate_id': candidateId, 'group_id': groupId, 'assigned_at': DateTime.now().toIso8601String()})
          .toList();

      await supabase.from('candidate_group_members').insert(associations);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "${_groupNameController.text}" created with ${selectedCandidateIds.length} candidates'),
            backgroundColor: Colors.green,
          ),
        );

        // Callback to refresh parent list
        widget.onGroupCreated?.call();

        // Close modal
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Consumer<CandidateProvider>(
        builder: (context, candidateProvider, _) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.group_add, color: Colors.purple.shade700, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create Candidate Group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Group candidates for batch exams', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // Group Name Field
                  TextFormField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name *',
                      hintText: 'e.g., Class A 2024',
                      prefixIcon: const Icon(Icons.label_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Group name is required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add a brief description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Candidates Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Candidates',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                      if (selectedCandidateIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '${selectedCandidateIds.length} selected',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search candidates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Candidates List
                  Expanded(
                    child: candidateProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredCandidates.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? 'No candidates available' : 'No candidates found',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              itemCount: _filteredCandidates.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final candidate = _filteredCandidates[index];
                                final isSelected = selectedCandidateIds.contains(candidate.id);

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedCandidateIds.add(candidate.id);
                                      } else {
                                        selectedCandidateIds.remove(candidate.id);
                                      }
                                    });
                                  },
                                  title: Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(candidate.email, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                      if (candidate.rollNumber != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text('Roll: ${candidate.rollNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ),
                                    ],
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundColor: isSelected ? Colors.purple.shade100 : Colors.grey.shade200,
                                    child: Text(
                                      candidate.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.purple.shade700 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  activeColor: Colors.purple.shade700,
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: candidateProvider.isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: candidateProvider.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  await candidateProvider.createGroup(
                                    name: _groupNameController.text.trim().titleCase,
                                    description: _descriptionController.text.trim().sentenceCase,
                                    candidateIds: selectedCandidateIds.toList(),
                                  );

                                  if (context.mounted) {
                                    // Show success message
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(const SnackBar(content: Text('Candidate added successfully'), backgroundColor: Colors.green));

                                    // Close modal
                                    Navigator.of(context).pop();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.purple.shade700,
                          ),
                          child: candidateProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Text(
                                  'Create Group',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
