import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import '../models/candidate_model.dart';
import '../providers/exam_provider.dart';
import '../providers/supabase_provider.dart';
import '../widgets/student_card_widget.dart';

class DistributionScreen extends StatefulWidget {
  final String examId;

  final String groupId;

  const DistributionScreen({super.key, required this.examId, required this.groupId});

  @override
  State<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen> {
  final Map<String, bool> _uploadedScripts = {};
  // final ImagePicker _picker = ImagePicker();
  List<Candidate> students = [];
  // int uploadedCount = 0;
  bool _isDownloading = false;
  bool _isProcessing = false;
  bool _isReady = false;

  Future<void> downloadQuestionPDF(String roll) async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await Supabase.instance.client.storage.from('exam-assets').download('exams/${widget.examId}/${roll}_question.pdf');
      if (kIsWeb) {
        final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: "application/pdf"));

        final url = web.URL.createObjectURL(blob);

        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = "${roll}_question.pdf";

        anchor.click();

        web.URL.revokeObjectURL(url);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exam paper ready to download')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _isDownloading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded questions'), backgroundColor: Colors.green));
  }

  Future<void> downloadAnswerPDF(String roll) async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await Supabase.instance.client.storage.from('exam-assets').download('exams/${widget.examId}/${roll}_answer.pdf');
      if (kIsWeb) {
        final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: "application/pdf"));

        final url = web.URL.createObjectURL(blob);

        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = "${roll}_answer.pdf";

        anchor.click();

        web.URL.revokeObjectURL(url);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exam paper ready to download')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _isDownloading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded questions'), backgroundColor: Colors.green));
  }

  Future<void> buildStudentLatex(String examId) async {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Question Distribution for ${students.length} students is started', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
    );
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session == null) return;
    final response = await supabase.functions.invoke('build_student_pdfs', body: {'exam_id': examId});
    if (response.status != 200) {
      throw Exception(response.data ?? 'Failed to build exam LaTeX');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Question Distribution for ${students.length} students is complete'), backgroundColor: Colors.green));
    if (kDebugMode) {
      print('Edge function response: ${response.data}');
    }
    setState(() {
      _isProcessing = false;
      _isReady = true;
    });
  }

  /*Future<void> _downloadExam(Map<String, dynamic> student) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating PDF...')])),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded exam for ${student['name']}'), backgroundColor: Colors.green));
  }*/

  /*Future<void> _uploadAnswerScript(Map<String, dynamic> student) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _uploadedScripts[student['id']] = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded script for ${student['name']}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }*/

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(seconds: 5));
      final supabase = Supabase.instance.client;
      final candidate = await supabase.from('candidate_group_members').select('candidate_id').eq('group_id', widget.groupId);
      final candidates = await supabase.from('candidates').select().inFilter('id', candidate.map((e) => e['candidate_id']).toList());
      students = candidates.map((e) => Candidate.fromJson(e)).toList();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Consumer<ExamProvider>(
                      builder: (context, examProvider, _) {
                        return Text(
                          '${examProvider.examName.titleCase} Distribution',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        );
                      },
                    ),
                    (students.isNotEmpty)
                        ? ElevatedButton.icon(
                            onPressed: (_isProcessing) ? null : () => buildStudentLatex(widget.examId),
                            icon: _isProcessing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.question_answer, color: Colors.white),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                            label: Text("Distribute Questions", style: TextStyle(color: Colors.white)),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Download exams papers', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 16),
                (students.isNotEmpty)
                    ? Consumer<SupabaseProvider>(
                        builder: (context, supabaseProvider, _) {
                          return StreamBuilder(
                            stream: supabaseProvider.client.from("pdf_tasks").stream(primaryKey: ["id"]).eq("exam_id", widget.examId),
                            builder: (context, asyncSnapshot) {
                              final data = asyncSnapshot.data;
                              if (data != null) {
                                final task = asyncSnapshot.data as List<Map<String, dynamic>>;
                                // setState(() {
                                final uploadedCount = task.where((e) => e['task_type'] == 'student_pdf' && e['status'] == 'completed').length;
                                // });
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: uploadedCount / students.length * 2,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          '${(uploadedCount / 2).floor()} of ${students.length} question paper ready',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ready to start',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                );
                              }
                              return CircularProgressIndicator();
                            },
                          );
                        },
                      )
                    : Center(child: CircularProgressIndicator()),
              ],
            ),
          ),

          // Student Cards
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final hasUploaded = _uploadedScripts[student.id] ?? false;

                return StudentCard(
                  student: student,
                  onQuestionDownload: () => (student.rollNumber == null) ? {} : downloadQuestionPDF(student.rollNumber ?? ""),
                  onAnswerDownload: () => (student.rollNumber == null) ? {} : downloadAnswerPDF(student.rollNumber ?? ""),
                  isReady: _isReady,
                  isDownloading: _isDownloading,
                  /*hasUploaded: hasUploaded,
                  onLanguageChange: (String language) {
                    setState(() {
                      student['language'] = language;
                    });
                  },*/
                );
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to Grade',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$uploadedCount/${_students.length} answer scripts uploaded',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: uploadedCount > 0 ? _startGrading : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.play_circle_outline),
                      SizedBox(width: 8),
                      Text('Start Grading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),*/
        ],
      ),
    );
  }
}
