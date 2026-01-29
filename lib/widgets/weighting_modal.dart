import 'package:flutter/material.dart';
import '../models/exam_config.dart';
import '../models/exam_models.dart';

class WeightingModal extends StatefulWidget {
  final List<AnalyzedChapter> chapters;
  final List<String> importantChapters;
  final int importancePercentage;
  final Function(List<String>, int) onSave;

  const WeightingModal({
    super.key,
    required this.chapters,
    required this.importantChapters,
    required this.importancePercentage,
    required this.onSave,
  });

  @override
  State<WeightingModal> createState() => _WeightingModalState();
}

class _WeightingModalState extends State<WeightingModal> {
  late List<String> _importantChapters;
  late double _percentage;

  @override
  void initState() {
    super.initState();
    _importantChapters = List.from(widget.importantChapters);
    _percentage = widget.importancePercentage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final availableChapters = widget.chapters.where((c) => !_importantChapters.contains(c.title)).toList();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(child: _buildChapterList('Available Chapters', availableChapters, false)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildChapterList(
                        'Priority Chapters',
                        widget.chapters.where((c) => _importantChapters.contains(c.title)).toList(),
                        true,
                      ),
                    ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text('Chapter Weighting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildChapterList(String title, List<AnalyzedChapter> chapters, bool isPriority) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPriority ? const Color(0xFFFEF3C7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isPriority) {
                        _importantChapters.remove(chapter.title);
                      } else {
                        _importantChapters.add(chapter.title);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(chapter.title, style: const TextStyle(fontSize: 14)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Percentage: ${_percentage.toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Slider(value: _percentage, min: 0, max: 100, divisions: 10, onChanged: (value) => setState(() => _percentage = value)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.onSave(_importantChapters, _percentage.toInt());
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
