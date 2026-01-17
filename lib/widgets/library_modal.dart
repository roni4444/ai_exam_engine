import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/supabase_provider.dart';

class LibraryModal extends StatefulWidget {
  final Function(String fileName, String? fullPath) onSelect;

  const LibraryModal({super.key, required this.onSelect});

  @override
  State<LibraryModal> createState() => _LibraryModalState();
}

class _LibraryModalState extends State<LibraryModal> {
  // final DbService _dbService = DbService();
  List<dynamic> _files = [];
  bool _loading = true;
  String? _deletingFile;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  /// Load all files from the library
  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final dbService = context.read<SupabaseProvider>();
      final files = await dbService.getLibraryFiles();
      if (mounted) {
        setState(() {
          _files = files;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to load library files: $e');
      }
    }
  }

  /// Delete a file from the library with confirmation
  Future<void> _deleteFile(String fileName) async {
    final dbService = context.read<SupabaseProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete File?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(
          'Are you sure you want to delete "${_cleanFileName(fileName)}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletingFile = fileName);

    try {
      await dbService.deleteLibraryItem(fileName);

      if (mounted) {
        setState(() {
          _files.removeWhere((f) => f.name == fileName);
          _deletingFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('File deleted successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deletingFile = null);
        _showError('Failed to delete file: $e');
      }
    }
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

  /// Format file size in human-readable format
  String _formatFileSize(dynamic file) {
    try {
      if (file.metadata != null && file.metadata['size'] != null) {
        final bytes = file.metadata['size'] as int;
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return '';
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
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
                  'Select Source Material',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text('Choose a file from your resource library', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
            'Loading library...',
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
            'Library is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Text('Upload a PDF file to get started', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
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
              final file = _files[index];
              final fileName = file.name ?? '';
              final isDeleting = _deletingFile == fileName;

              return _buildFileCard(fileName, file, isDeleting);
            },
          ),
        ),
      ],
    );
  }

  /// Build individual file card
  Widget _buildFileCard(String fileName, dynamic file, bool isDeleting) {
    return AnimatedOpacity(
      opacity: isDeleting ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: isDeleting ? null : () => widget.onSelect(fileName, fileName),
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFFDEEBFF).withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDeleting ? Colors.grey.shade200 : Colors.grey.shade200, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                    child: Icon(Icons.picture_as_pdf_rounded, color: isDeleting ? Colors.grey.shade400 : const Color(0xFFDC2626), size: 24),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDeleting ? Colors.grey.shade400 : const Color(0xFF1E293B),
                            height: 1.2,
                          ),
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
                            if (_formatFileSize(file).isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                                ),
                              ),
                              Icon(Icons.insert_drive_file_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                _formatFileSize(file),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Delete button
              Positioned(
                top: -6,
                right: -6,
                child: isDeleting
                    ? Container(
                        width: 28,
                        height: 28,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                        ),
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _deleteFile(fileName),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
