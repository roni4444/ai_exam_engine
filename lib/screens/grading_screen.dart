import 'package:flutter/material.dart';
import '../widgets/graded_answer_card_widget.dart';
import 'results_screen.dart';

class GradingScreen extends StatefulWidget {
  const GradingScreen({super.key});

  @override
  State<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends State<GradingScreen> {
  String? _selectedStudentId;

  // Mock grading data
  final Map<String, Map<String, dynamic>> _gradingProgress = {
    'S1': {
      'name': 'Student 1',
      'total': 3,
      'graded': 3,
      'status': 'completed',
      'answers': [
        {
          'questionId': 'q1',
          'questionText': 'What is the capital of France?',
          'transcription': 'Paris',
          'score': 1,
          'maxScore': 1,
          'feedback': 'Correct answer',
          'breakdown': [
            {'symbol': '✓', 'text': 'Correct city identified', 'points': 1},
          ],
        },
        {
          'questionId': 'q2',
          'questionText': 'Explain the water cycle.',
          'transcription': 'Water evaporates, forms clouds, and rains',
          'score': 3,
          'maxScore': 4,
          'feedback': 'Good explanation but missing collection phase',
          'breakdown': [
            {'symbol': '✓', 'text': 'Mentioned evaporation', 'points': 1},
            {'symbol': '✓', 'text': 'Mentioned condensation', 'points': 1},
            {'symbol': '✓', 'text': 'Mentioned precipitation', 'points': 1},
            {'symbol': '✗', 'text': 'Collection phase missing', 'points': 0},
          ],
        },
        {
          'questionId': 'q3',
          'questionText': 'Derive the quadratic formula.',
          'transcription': 'Started with ax² + bx + c = 0...',
          'score': 8,
          'maxScore': 10,
          'feedback': 'Good attempt, minor calculation errors',
          'breakdown': [
            {'symbol': '✓', 'text': 'Correct setup', 'points': 3},
            {'symbol': '⚠', 'text': 'Partial completion', 'points': 3},
            {'symbol': '✓', 'text': 'Correct approach', 'points': 2},
          ],
        },
      ],
    },
    'S2': {'name': 'Student 2', 'total': 3, 'graded': 2, 'status': 'grading'},
    'S3': {'name': 'Student 3', 'total': 3, 'graded': 0, 'status': 'pending'},
  };

  @override
  void initState() {
    super.initState();
    _startAutoGrading();
  }

  Future<void> _startAutoGrading() async {
    // Simulate grading process
    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          if (_gradingProgress['S2']!['graded'] < 3) {
            _gradingProgress['S2']!['graded']++;
          }
          if (_gradingProgress['S2']!['graded'] == 3) {
            _gradingProgress['S2']!['status'] = 'completed';
          }
        });
      }
    }

    // Simulate S3 grading
    await Future.delayed(const Duration(seconds: 1));
    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _gradingProgress['S3']!['status'] = 'grading';
          if (_gradingProgress['S3']!['graded'] < 3) {
            _gradingProgress['S3']!['graded']++;
          }
          if (_gradingProgress['S3']!['graded'] == 3) {
            _gradingProgress['S3']!['status'] = 'completed';
          }
        });
      }
    }

    // Navigate to results
    if (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ResultsScreen()));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF059669);
      case 'grading':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCompleted = _gradingProgress.values.every((data) => data['status'] == 'completed');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grading Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          if (allCompleted)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ResultsScreen()));
              },
            ),
        ],
      ),
      body: _selectedStudentId == null ? _buildSummaryView() : _buildDetailView(),
    );
  }

  Widget _buildSummaryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grading Progress',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text('Monitor AI grading progress for all students', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _gradingProgress.length,
            itemBuilder: (context, index) {
              final entry = _gradingProgress.entries.elementAt(index);
              final studentId = entry.key;
              final data = entry.value;

              return InkWell(
                onTap: data['status'] == 'completed' ? () => setState(() => _selectedStudentId = studentId) : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
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
                              backgroundColor: _getStatusColor(data['status']),
                              child: Text(
                                data['name'][0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status']).withValues(alpha: 255 * 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (data['status'] == 'grading')
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _getStatusColor(data['status'])),
                                      ),
                                    ),
                                  Text(
                                    data['status'].toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(data['status'])),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        Text('Student ID: $studentId', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const Spacer(),
                        LinearProgressIndicator(
                          value: data['graded'] / data['total'],
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(data['status'])),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data['graded']}/${data['total']} Questions',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                        if (data['status'] == 'completed') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => setState(() => _selectedStudentId = studentId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('View Details'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView() {
    final data = _gradingProgress[_selectedStudentId]!;
    final answers = data['answers'] as List<Map<String, dynamic>>? ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedStudentId = null)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data['name']} - Detailed Results',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text('Reviewing ${answers.length} graded questions', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: answers.length,
            itemBuilder: (context, index) {
              final answer = answers[index];
              return GradedAnswerCard(answer: answer, number: index + 1);
            },
          ),
        ),
      ],
    );
  }
}
