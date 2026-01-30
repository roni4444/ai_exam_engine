import 'package:flutter/material.dart';

import '../models/exam_models.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int number;

  const QuestionCard({super.key, required this.question, required this.number});

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFF059669);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(question.difficulty).withValues(alpha: 255 * 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      question.difficulty,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getDifficultyColor(question.difficulty)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${question.marks} Marks',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              if (question.options != null) ...[
                const SizedBox(height: 12),
                ...question.options!.first.substring(1, question.options!.first.length - 1).split(",").map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(option.split(":").first, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(option.split(":").last, style: TextStyle(color: Colors.grey[700])),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(question.type), backgroundColor: Colors.grey[100], labelStyle: const TextStyle(fontSize: 11)),
                  Chip(
                    label: Text(question.bloomsLevel ?? 'Mixed'),
                    backgroundColor: Colors.purple[50],
                    labelStyle: TextStyle(fontSize: 11, color: Colors.purple[700]),
                  ),
                  Chip(
                    label: Text(question.sectionName),
                    backgroundColor: Colors.blue[50],
                    labelStyle: TextStyle(fontSize: 11, color: Colors.blue[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
