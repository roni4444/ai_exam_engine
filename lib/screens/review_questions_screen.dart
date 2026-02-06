import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_models.dart';
import '../providers/supabase_provider.dart';
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
  // String _selectedLanguage = 'English';
  bool _isDownloading = false;

  Future<void> buildExamLatex(String examId) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session == null) return;
    final response = await supabase.functions.invoke('build_exam_latex', body: {'exam_id': examId});
    if (response.status != 200) {
      throw Exception(response.data ?? 'Failed to build exam LaTeX');
    }

    if (kDebugMode) {
      print('Edge function response: ${response.data}');
    }
  }

  Future<void> preparePDF() async {
    setState(() => _isDownloading = true);
    try {
      await buildExamLatex(widget.questions.first.examId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF task created')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _isDownloading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded questions'), backgroundColor: Colors.green));
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
                /*const Text('Language:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: ['English', 'Bengali', 'Hindi'].map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value!);
                  },
                ),*/
                const Spacer(),
                Consumer<SupabaseProvider>(
                  builder: (context, supabaseProvider, _) {
                    return StreamBuilder(
                      stream: supabaseProvider.client.from("pdf_tasks").stream(primaryKey: ["id"]).eq("exam_id", widget.questions.first.examId),
                      initialData: supabaseProvider.client
                          .from("pdf_tasks")
                          .select()
                          .eq("exam_id", widget.questions.first.examId)
                          .eq("task_type", "exam_pdf")
                          .single(),
                      builder: (context, asyncSnapshot) {
                        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (asyncSnapshot.connectionState == ConnectionState.done) {
                          if (asyncSnapshot.hasData) {
                            final task = asyncSnapshot.data as Map<String, dynamic>;
                            if (task['status'] == 'completed') {
                              return ElevatedButton.icon(
                                onPressed: _isDownloading ? null : preparePDF,
                                icon: _isDownloading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.book, color: Colors.white),
                                label: const Text('Download Question', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                              );
                            } else if (task['status'] == 'failed') {
                              return ElevatedButton.icon(
                                onPressed: _isDownloading ? null : preparePDF,
                                icon: _isDownloading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.download, color: Colors.white),
                                label: const Text('Prepare Questions', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                              );
                            } else {
                              return ElevatedButton.icon(
                                onPressed: null,
                                icon: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                label: const Text('Preparing Questions', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                              );
                            }
                          }
                        }
                        return ElevatedButton.icon(
                          onPressed: _isDownloading ? null : preparePDF,
                          icon: _isDownloading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.download, color: Colors.white),
                          label: const Text('Prepare Questions', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                        );
                      },
                    );
                  },
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
