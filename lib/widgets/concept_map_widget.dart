import 'package:flutter/material.dart';
import '../models/exam_config.dart';
import '../models/exam_models.dart';

class ConceptMapWidget extends StatelessWidget {
  final List<ChapterConcept> concepts;

  const ConceptMapWidget({super.key, required this.concepts});

  @override
  Widget build(BuildContext context) {
    final groupedConcepts = <String, List<ChapterConcept>>{};
    for (final concept in concepts) {
      final type = concept.type.isEmpty ? 'general' : concept.type;
      groupedConcepts.putIfAbsent(type, () => []).add(concept);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: groupedConcepts.entries.map((entry) {
          return _buildConceptGroup(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildConceptGroup(String type, List<ChapterConcept> concepts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withValues(alpha: 255 * 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getTypeIcon(type), size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                _getTypeLabel(type).toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.2),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  concepts.length.toString(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...concepts.map((concept) => _buildConceptCard(concept, type)),
        ],
      ),
    );
  }

  Widget _buildConceptCard(ChapterConcept concept, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 255 * 0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: _getTypeColor(type), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concept.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                /*const SizedBox(height: 4),
                Text(concept.description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5)),*/
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'definition':
        return const Color(0xFF2563EB);
      case 'process':
        return const Color(0xFF8B5CF6);
      case 'misconception':
        return const Color(0xFFD97706);
      case 'cause-effect':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'definition':
        return Icons.menu_book;
      case 'process':
        return Icons.alt_route;
      case 'misconception':
        return Icons.warning_amber;
      case 'cause-effect':
        return Icons.bolt;
      default:
        return Icons.label;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'definition':
        return 'Key Definitions';
      case 'process':
        return 'Core Processes';
      case 'misconception':
        return 'Common Misconceptions';
      case 'cause-effect':
        return 'Cause & Effect';
      default:
        return 'Key Concepts';
    }
  }
}
