import 'package:flutter/material.dart';
import '../models/exam_config.dart';
import '../utils/question_types.dart';

class SectionModal extends StatefulWidget {
  final ExamSection? section;
  final Function(ExamSection) onSave;

  const SectionModal({super.key, this.section, required this.onSave});

  @override
  State<SectionModal> createState() => _SectionModalState();
}

class _SectionModalState extends State<SectionModal> {
  late TextEditingController _nameController;
  late List<QuestionTypeConfig> _questionTypes;
  int? _expandedTypeIdx;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.section?.name ?? 'Section ${String.fromCharCode(65)}');
    _questionTypes = widget.section?.questionTypes ?? _createInitialTypes();
  }

  List<QuestionTypeConfig> _createInitialTypes() {
    return QuestionTypes.types.map((type) {
      return QuestionTypeConfig(
        type: type,
        marks: type == 'Long Answer'
            ? 10
            : type == 'Short Answer'
            ? 4
            : 1,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionNameField(),
                    const SizedBox(height: 32),
                    ..._questionTypes.asMap().entries.map((entry) {
                      return _buildQuestionTypeCard(entry.key, entry.value);
                    }),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text(
            'Configure Section',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, size: 24), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildSectionNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SECTION LABEL',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'e.g. Section A: Knowledge',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 4),
            ),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeCard(int index, QuestionTypeConfig qt) {
    final isExpanded = _expandedTypeIdx == index;
    final totalCount = qt.count.easy + qt.count.medium + qt.count.hard;
    final hasScenario = qt.scenarios.isNotEmpty;
    final isActive = totalCount > 0 || hasScenario || isExpanded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? const Color(0xFF93C5FD) : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedTypeIdx = isExpanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDEEBFF) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qt.type,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (qt.type != 'Scenario Based') ...[
                                _buildSmallBadge('${qt.count.easy} E', const Color(0xFF22C55E)),
                                _buildSmallBadge('${qt.count.medium} M', const Color(0xFFEAB308)),
                                _buildSmallBadge('${qt.count.hard} H', const Color(0xFFEF4444)),
                              ] else
                                _buildSmallBadge('${qt.scenarios.length} Scenarios', const Color(0xFF8B5CF6)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (qt.type != 'Scenario Based')
                    Column(
                      children: [
                        const Text(
                          'MARKS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${qt.marks} pts',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildExpandedContent(index, qt),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildExpandedContent(int index, QuestionTypeConfig qt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (qt.type != 'Scenario Based') ...[
            Row(
              children: [
                Expanded(
                  child: _buildDifficultyControl('Easy', qt.count.easy, (val) {
                    setState(() {
                      _questionTypes[index] = qt.copyWith(count: qt.count.copyWith(easy: val));
                    });
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDifficultyControl('Medium', qt.count.medium, (val) {
                    setState(() {
                      _questionTypes[index] = qt.copyWith(count: qt.count.copyWith(medium: val));
                    });
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDifficultyControl('Hard', qt.count.hard, (val) {
                    setState(() {
                      _questionTypes[index] = qt.copyWith(count: qt.count.copyWith(hard: val));
                    });
                  }),
                ),
              ],
            ),
          ] else ...[
            const Text('Scenario-based questions coming soon', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultyControl(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 24,
                color: const Color(0xFF64748B),
                onPressed: () => onChanged((value - 1).clamp(0, 999)),
              ),
              Text(
                value.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 24,
                color: const Color(0xFF64748B),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final totalQuestions = _questionTypes.fold<int>(0, (sum, qt) => sum + qt.count.easy + qt.count.medium + qt.count.hard + qt.scenarios.length);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              const Icon(Icons.layers, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                '$totalQuestions Items',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Discard',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Section', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a section name')));
      return;
    }

    final section = ExamSection(
      id: widget.section?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      questionTypes: _questionTypes,
    );

    widget.onSave(section);
    Navigator.of(context).pop();
  }
}
