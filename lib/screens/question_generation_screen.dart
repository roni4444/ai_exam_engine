import 'package:ai_exam_engine/models/exam_config.dart';
import 'package:ai_exam_engine/screens/review_questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_models.dart';
import '../providers/question_provider.dart';

class QuestionGenerationScreen extends StatefulWidget {
  final Function({required List<Question> questions})? onNext;
  final String? examId;
  final ExamConfig? config;

  const QuestionGenerationScreen({super.key, this.examId, required this.config, this.onNext});

  @override
  State<QuestionGenerationScreen> createState() => _QuestionGenerationScreenState();
}

class _QuestionGenerationScreenState extends State<QuestionGenerationScreen> {
  late Question question;

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuestionProvider>();
    // Check if questions already exist
    if (provider.questions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await provider.loadQuestions(widget.examId);
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Pool Generation', style: TextStyle(color: Color(0xFF1E293B))),
        elevation: 0,
      ),
      body: Consumer<QuestionProvider>(
        builder: (context, provider, child) {
          // Show error if any
          if (provider.error != null && !provider.isGenerating) {
            return _buildErrorView(provider.error!);
          }

          // Show questions pool report if generation complete
          if (provider.questions.isNotEmpty && !provider.isGenerating) {
            widget.onNext?.call(questions: provider.questions);
            return _buildQuestionPoolReport(provider.questions);
          }

          // Show generation in progress
          if (provider.isGenerating && provider.progress != null) {
            return _buildGenerationProgress(provider.progress!);
          }

          // Initial state - show generate button
          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.indigo.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 255 * 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 40),
          const Text(
            'Ready to Generate Questions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Text(
            'Gemini 3 will create ${_calculateTotalQuestions()} unique questions\nfor ${widget.config?.studentCount} students',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _startGeneration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: Colors.blue.withValues(alpha: 255 * 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow, size: 24),
                SizedBox(width: 12),
                Text('Generate Question Pool', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationProgress(QuestionGenerationProgress progress) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Spinner
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)))),
            ),
            const SizedBox(height: 40),

            // Status Text
            Text(
              _getStatusText(progress.status),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Text('Gemini 3 is building your question bank...', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 40),

            // Progress Card
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 255 * 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Questions Generated',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 14),
                      ),
                      Row(
                        children: [
                          Text(
                            '${progress.current}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                          Text(' / ${progress.total}', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Percentage and Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Processing ${progress.status}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      Text(
                        '${(progress.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPoolReport(List<Question> questions) {
    final stats = _calculateQuestionStats(questions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade50, Colors.amber.shade50]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Question Pool Generated',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text('Successfully created ${questions.length} unique questions', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Statistics Cards
          const Text(
            'Generation Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Questions', questions.length.toString(), Icons.quiz, Colors.blue),
              _buildStatCard('Total Marks', stats['totalMarks'].toString(), Icons.stars, Colors.purple),
              _buildStatCard('Easy', stats['easy'].toString(), Icons.sentiment_satisfied, Colors.green),
              _buildStatCard('Medium', stats['medium'].toString(), Icons.sentiment_neutral, Colors.orange),
              _buildStatCard('Hard', stats['hard'].toString(), Icons.sentiment_very_dissatisfied, Colors.red),
              _buildStatCard('Scenarios', stats['scenarios'].toString(), Icons.auto_stories, Colors.indigo),
            ],
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => ReviewQuestionsScreen(questions: questions),
            ),
            child: Text("Review Questions"),
          ),
          /*// Questions Preview
          const Text(
            'Question Preview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),

          ...questions.take(5).map((q) => _buildQuestionPreviewCard(q)),

          if (questions.length > 5)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '+ ${questions.length - 5} more questions',
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
            ),*/
          /*
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to distribution
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue to Distribution'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),*/
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 255 * 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 255 * 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPreviewCard(Question question) {
    final difficulty = question.difficulty;
    final marks = question.marks;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '[$marks Marks]',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge(difficulty, _getDifficultyColor(difficulty)),
              const SizedBox(width: 8),
              _buildBadge(question.type, Colors.blue.shade100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 24),
          const Text(
            'Generation Failed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startGeneration,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Generation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startGeneration() async {
    await context.read<QuestionProvider>().generateQuestions(widget.examId);
  }

  int _calculateTotalQuestions() {
    int total = 0;
    final List<ExamSection> sections = widget.config?.sections ?? [];

    for (ExamSection section in sections) {
      final List<QuestionTypeConfig> questionTypes = section.questionTypes;
      for (QuestionTypeConfig qt in questionTypes) {
        final DifficultyCount count = qt.count;
        total += count.easy;
        total += count.medium;
        total += count.hard;
        total += ((qt.scenarios as List?)?.length ?? 0);
      }
    }

    return total * (widget.config?.studentCount ?? 1);
  }

  Map<String, int> _calculateQuestionStats(List<Question> questions) {
    int easy = 0, medium = 0, hard = 0, scenarios = 0, totalMarks = 0;

    for (var q in questions) {
      final difficulty = q.difficulty;
      final marks = q.marks;

      totalMarks += marks;

      if (q.isScenario) {
        scenarios++;
      } else {
        switch (difficulty) {
          case 'Easy':
            easy++;
            break;
          case 'Medium':
            medium++;
            break;
          case 'Hard':
            hard++;
            break;
        }
      }
    }

    return {'easy': easy, 'medium': medium, 'hard': hard, 'scenarios': scenarios, 'totalMarks': totalMarks};
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'initializing':
        return 'Initializing Generation...';
      case 'analyzing':
        return 'Analyzing Chapter Content...';
      case 'generating':
        return 'Generating Question Pool...';
      case 'validating':
        return 'Validating Questions...';
      default:
        return 'Processing...';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green.shade100;
      case 'Medium':
        return Colors.orange.shade100;
      case 'Hard':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
