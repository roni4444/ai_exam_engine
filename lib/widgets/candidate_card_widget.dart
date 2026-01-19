import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/candidate_model.dart';

class CandidateCard extends StatelessWidget {
  final Candidate file;
  final VoidCallback onDelete;

  const CandidateCard({super.key, required this.file, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                    file.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM d, yyyy').format(file.createdAt!), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(file.email, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(file.phone ?? "", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(file.rollNumber ?? "", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            /* Text(
               file.name,
               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
             ),
             const SizedBox(width: 12),*/
            ElevatedButton.icon(
              onPressed: onDelete,
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
  }
}
