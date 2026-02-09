import 'package:ai_exam_engine/models/candidate_model.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

class StudentCard extends StatelessWidget {
  final Candidate student;
  final bool isReady;
  final bool isDownloading;
  final VoidCallback onQuestionDownload;
  final VoidCallback onAnswerDownload;
  /*final Function(String) onLanguageChange;*/

  const StudentCard({
    super.key,
    required this.student,
    required this.onQuestionDownload,
    required this.onAnswerDownload,
    required this.isReady,
    required this.isDownloading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: /*hasUploaded ? const Color(0xFF059669) :*/ Colors.grey[200]!, width: /*hasUploaded ? 2 :*/ 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 255 * 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: /*hasUploaded ? const Color(0xFF059669) : */ const Color(0xFF2563EB),
                  child: Text(
                    student.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                /*const Spacer(),
                if (hasUploaded)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),*/
              ],
            ),
            const SizedBox(height: 12),
            Text(
              student.name.titleCase,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text('Roll No.: ${student.rollNumber}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            /*Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: DropdownButton<String>(
                value: student['language'],
                isExpanded: true,
                underline: const SizedBox(),
                items: ['English', 'Bengali', 'Hindi']
                    .map(
                      (lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onLanguageChange(value);
                  }
                },
              ),
            ),*/
            // const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isReady && !isDownloading) ? onQuestionDownload : null,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isReady && !isDownloading) ? onAnswerDownload : null,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Answer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B1E1E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            /*const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpload,
                icon: Icon(hasUploaded ? Icons.check_circle : Icons.upload, size: 18),
                label: Text(hasUploaded ? 'Script Uploaded' : 'Upload Script'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: hasUploaded ? const Color(0xFF059669) : const Color(0xFF2563EB),
                  side: BorderSide(color: hasUploaded ? const Color(0xFF059669) : const Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
