import 'package:flutter/material.dart';

class GradedAnswerCard extends StatelessWidget {
  final Map<String, dynamic> answer;
  final int number;

  const GradedAnswerCard({super.key, required this.answer, required this.number});

  @override
  Widget build(BuildContext context) {
    final scorePercent = answer['score'] / answer['maxScore'];
    final color = scorePercent > 0.7
        ? const Color(0xFF059669)
        : scorePercent > 0.4
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 255 * 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 255 * 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q$number',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
                const Spacer(),
                Text(
                  '${answer['score']}',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                ),
                Text('/${answer['maxScore']}', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              answer['questionText'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 4),
                      Text(
                        'Transcription',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${answer['transcription']}"',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF78350F)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Grading Breakdown',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            ...((answer['breakdown'] as List<Map<String, dynamic>>).map((item) {
              Color itemColor;
              IconData icon;
              switch (item['symbol']) {
                case '✓':
                  itemColor = const Color(0xFF059669);
                  icon = Icons.check_circle;
                  break;
                case '✗':
                  itemColor = const Color(0xFFEF4444);
                  icon = Icons.cancel;
                  break;
                default:
                  itemColor = const Color(0xFFF59E0B);
                  icon = Icons.warning;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(icon, color: itemColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item['text'], style: TextStyle(color: Colors.grey[700])),
                    ),
                    Text(
                      '${item['points'] > 0 ? '+' : ''}${item['points']}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: item['points'] > 0 ? const Color(0xFF059669) : const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              );
            })),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.feedback_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(answer['feedback'], style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
