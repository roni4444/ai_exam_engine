import 'package:ai_exam_engine/models/candidate_model.dart';
import 'package:ai_exam_engine/providers/candidate_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/supabase_provider.dart';

class CandidateSelectionModal extends StatefulWidget {
  final Function(String fileName) onSelect;

  const CandidateSelectionModal({super.key, required this.onSelect});

  @override
  State<CandidateSelectionModal> createState() => _CandidateSelectionModalState();
}

class _CandidateSelectionModalState extends State<CandidateSelectionModal> {
  List<dynamic> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  /// Load all files from the library
  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final dbService = context.read<CandidateProvider>();
      await dbService.fetchGroups();
      if (mounted) {
        setState(() {
          _files = dbService.groups;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to load candidate groups: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 255 * 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : _files.isEmpty
                  ? _buildEmptyState()
                  : _buildFileList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build modal header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Groups',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text('Choose groups from the database', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: const Color(0xFF64748B),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2563EB))),
          const SizedBox(height: 16),
          Text(
            'Loading database...',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          const Text(
            'No group is found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  /// Build file list grid
  Widget _buildFileList() {
    return Column(
      children: [
        // Header with file count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                '${_files.length} ${_files.length == 1 ? 'file' : 'files'}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // File grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final CandidateGroup file = _files[index];
              final fileName = file.name;
              final fileId = file.id;
              return _buildFileCard(fileName, fileId, file);
            },
          ),
        ),
      ],
    );
  }

  /// Build individual file card
  Widget _buildFileCard(String fileName, String fileId, dynamic file) {
    return InkWell(
      onTap: () => widget.onSelect(fileId),
      borderRadius: BorderRadius.circular(12),
      hoverColor: const Color(0xFFDEEBFF).withValues(alpha: 255 * 0.5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 255 * 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content
            Row(
              children: [
                // PDF Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.picture_as_pdf_rounded, color: const Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 14),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // File name
                      Text(
                        _cleanFileName(fileName),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Metadata row
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(file),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Remove timestamp prefix from filename
  String _cleanFileName(String fileName) {
    final parts = fileName.split('_');
    return parts.length > 1 ? parts.skip(1).join('_') : fileName;
  }

  /// Format file creation date
  String _formatDate(dynamic file) {
    try {
      if (file.createdAt != null) {
        final date = DateTime.parse(file.createdAt);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'Unknown date';
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
