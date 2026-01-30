import 'package:flutter/material.dart';
import '../models/exam_models.dart';
import '../widgets/question_card_widget.dart';
import '../widgets/stat_card_widget.dart';
import 'simulation_screen.dart';

class ReviewQuestionsScreen extends StatefulWidget {
  final List<Question> questions;

  const ReviewQuestionsScreen({super.key, required this.questions});

  @override
  State<ReviewQuestionsScreen> createState() => _ReviewQuestionsScreenState();
}

class _ReviewQuestionsScreenState extends State<ReviewQuestionsScreen> {
  String _selectedLanguage = 'English';
  bool _isDownloading = false;

  // Mock questions for demo
  /*final List<Question> _mockQuestions = [
    Question(
      id: 'q1',
      sectionId: 's1',
      sectionName: 'Section A',
      text: 'What is the capital of France?',
      concept: 'Geography',
      difficulty: 'Easy',
      type: 'Multiple Choice',
      marks: 1,
      modelAnswer: 'Paris',
      rubric: ['Correct city name'],
      options: ['London', 'Paris', 'Berlin', 'Madrid'],
      negativeValue: 0.25,
      allowPartial: false,
      isOrType: false,
      bloomsLevel: 'Remember',
      examId: '',
      latexVersion: '',
    ),
    Question(
      id: 'q2',
      sectionId: 's1',
      sectionName: 'Section A',
      text: 'Explain the water cycle in detail.',
      concept: 'Science',
      difficulty: 'Medium',
      type: 'Short Answer',
      marks: 4,
      modelAnswer: 'The water cycle involves evaporation, condensation, precipitation, and collection.',
      rubric: ['Mention evaporation', 'Mention condensation', 'Mention precipitation', 'Mention collection'],
      negativeValue: 0,
      allowPartial: true,
      isOrType: false,
      bloomsLevel: 'Understand',
      examId: '',
      latexVersion: '',
    ),
    Question(
      id: 'q3',
      sectionId: 's2',
      sectionName: 'Section B',
      text: 'Derive the quadratic formula from ax² + bx + c = 0.',
      concept: 'Mathematics',
      difficulty: 'Hard',
      type: 'Equation Derivation',
      marks: 10,
      modelAnswer: 'Complete derivation using completing the square method.',
      rubric: ['Start with standard form', 'Complete the square', 'Simplify', 'Final formula'],
      negativeValue: 0,
      allowPartial: true,
      isOrType: false,
      bloomsLevel: 'Apply',
      examId: '',
      latexVersion: '',
    ),
  ];*/

  Future<void> _downloadQuestions() async {
    setState(() => _isDownloading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isDownloading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded questions in $_selectedLanguage'), backgroundColor: Colors.green));
  }

  void _distributeToStudents() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SimulationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Review Questions'), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E293B), elevation: 0),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question Pool Generated',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Text('Review the generated content pool before distributing', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
                SizedBox(width: MediaQuery.widthOf(context) / 3),
                StatCard(label: 'Total Questions', value: widget.questions.length.toString(), color: const Color(0xFF2563EB)),
                const SizedBox(width: 16),
                StatCard(label: 'Total Marks', value: widget.questions.fold(0, (sum, q) => sum + q.marks).toString(), color: const Color(0xFF7C3AED)),
                const SizedBox(width: 16),
                StatCard(
                  label: 'Sections',
                  value: widget.questions.map((q) => q.sectionName).toSet().length.toString(),
                  color: const Color(0xFF059669),
                ),
              ],
            ),
          ),

          // Download Controls
          Container(
            padding: const EdgeInsets.all(24),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const Text('Language:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: ['English', 'Bengali', 'Hindi'].map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value!);
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadQuestions,
                  icon: _isDownloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download, color: Colors.white),
                  label: const Text('Download Questions', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadQuestions,
                  icon: _isDownloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.book, color: Colors.white),
                  label: const Text('Download Solutions', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                ),
              ],
            ),
          ),

          // Questions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                return QuestionCard(question: question, number: index + 1);
              },
            ),
          ),

          /*// Action Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 255 * 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Consumer<ExamProvider>(
              builder: (context, examProvider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _distributeToStudents,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people),
                        const SizedBox(width: 8),
                        Text(
                          'Distribute to ${examProvider.students.isNotEmpty ? examProvider.students.length : '3'} Students',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),*/
        ],
      ),
    );
  }
}
