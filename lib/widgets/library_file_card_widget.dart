import 'package:ai_exam_engine/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/exam_models.dart';
import '../providers/gemini_provider.dart';
import '../providers/library_provider.dart';
import '../screens/dashboard_screen.dart';

// enum ProcessingStatus { idle, extracting, analyzing, completed }

class LibraryFileCard extends StatefulWidget {
  final LibraryFile file;
  final VoidCallback onDelete;
  final ProcessingStatus processingStatus;

  const LibraryFileCard({super.key, required this.file, required this.onDelete, required this.processingStatus});

  @override
  State<LibraryFileCard> createState() => _LibraryFileCardState();
}

class _LibraryFileCardState extends State<LibraryFileCard> {
  final GeminiService geminiService = GeminiService();
  late ProcessingStatus fileProcessingStatus = ProcessingStatus.idle;

  @override
  void initState() {
    super.initState();
    fileProcessingStatus = widget.processingStatus;
  }

  String _getStatusText() {
    switch (fileProcessingStatus) {
      case ProcessingStatus.completed:
        return 'Analysis Ready';
      case ProcessingStatus.idle:
        return 'Awaiting Input';
      case ProcessingStatus.extracting:
        return 'Reading File...';
      case ProcessingStatus.analyzing:
        return 'Identifying Concepts...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiProvider>(
      builder: (context, geminiProvider, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(DateFormat('MMM d, yyyy').format(widget.file.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      const SizedBox(height: 2),
                      Text(formatFileSize(widget.file.size), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),

                (fileProcessingStatus == ProcessingStatus.idle || fileProcessingStatus == ProcessingStatus.completed)
                    ? ElevatedButton(
                        onPressed: () => widget.file.isGeminiProcessed
                            ? null
                            : geminiProvider.genAIOnPDF(
                                fileName: widget.file.name,
                                onStatusUpdate: (String status) {
                                  setState(() {
                                    if (status == 'detecting_language') {
                                      fileProcessingStatus = ProcessingStatus.extracting;
                                    } else if (status == 'analyzing_chapters') {
                                      fileProcessingStatus = ProcessingStatus.analyzing;
                                    } else if (status == 'completed') {
                                      fileProcessingStatus = ProcessingStatus.completed;
                                      context.read<LibraryProvider>().loadLibraryFiles();
                                    }
                                  });
                                },
                              ),
                        child: Text(widget.file.isGeminiProcessed ? "Your File is processed" : "Analyze with Gemini"),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.grey,
                            strokeWidth: 3.0,
                            constraints: BoxConstraints(maxWidth: 18, minWidth: 18, maxHeight: 18, minHeight: 18),
                          ),
                          SizedBox(width: 5),
                          Text(
                            _getStatusText(),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                        ],
                      ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onDelete,
                  label: Icon(Icons.delete_outline, size: 18, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
                // IconButton(icon: const , color: Colors.grey[400], onPressed: onDelete),
              ],
            ),
          ),
        );
      },
    );
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
