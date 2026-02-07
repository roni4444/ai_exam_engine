import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_config.dart';
import '../providers/exam_provider.dart';
import '../providers/supabase_provider.dart';
import '../widgets/student_card_widget.dart';

class SimulationScreen extends StatefulWidget {
  final String examId;
  final ExamConfig? config;
  const SimulationScreen({super.key, required this.examId, required this.config});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final Map<String, bool> _uploadedScripts = {};
  final ImagePicker _picker = ImagePicker();
  int uploadedCount = 0;

  // Mock students
  final List<Map<String, dynamic>> _students = [
    {'id': 'S1', 'name': 'Student 1', 'language': 'English'},
    {'id': 'S2', 'name': 'Student 2', 'language': 'English'},
    {'id': 'S3', 'name': 'Student 3', 'language': 'English'},
  ];

  Future<void> buildStudentLatex(String examId) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session == null) return;
    final response = await supabase.functions.invoke('build_student_pdfs', body: {'exam_id': examId});
    if (response.status != 200) {
      throw Exception(response.data ?? 'Failed to build exam LaTeX');
    }

    if (kDebugMode) {
      print('Edge function response: ${response.data}');
    }
  }

  Future<void> _downloadExam(Map<String, dynamic> student) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating PDF...')])),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded exam for ${student['name']}'), backgroundColor: Colors.green));
  }

  Future<void> _uploadAnswerScript(Map<String, dynamic> student) async {
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
                          '${examProvider.examName} Distribution',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        );
                      },
                    ),
                    ElevatedButton(onPressed: () {}, child: Text("Distribute Questions")),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Download exams papers', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Consumer<SupabaseProvider>(
                      builder: (context, supabaseProvider, _) {
                        return StreamBuilder(
                          stream: supabaseProvider.client.from("pdf_tasks").stream(primaryKey: ["id"]).eq("exam_id", widget.examId ?? ""),
                          initialData: supabaseProvider.client
                              .from("pdf_tasks")
                              .select()
                              .eq("exam_id", widget.examId ?? "")
                              .eq("task_type", "student_pdf")
                              .single(),
                          builder: (context, asyncSnapshot) {
                            final task = asyncSnapshot.data as List<Map<String, dynamic>>;
                            setState(() {
                              uploadedCount = task.where((element) => element['task_type'] == 'student_pdf').toList().length;
                            });
                            return Expanded(
                              child: LinearProgressIndicator(
                                value: uploadedCount / widget.config!.studentCount * 2,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    /*Expanded(
                      child: LinearProgressIndicator(
                        value: uploadedCount / _students.length,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    ),*/
                    SizedBox(width: 16),
                    Text(
                      '$uploadedCount of ${_students.length} question paper ready',
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
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final hasUploaded = _uploadedScripts[student['id']] ?? false;

                return StudentCard(
                  student: student,
                  hasUploaded: hasUploaded,
                  onDownload: () => _downloadExam(student),
                  onUpload: () => _uploadAnswerScript(student),
                  onLanguageChange: (String language) {
                    setState(() {
                      student['language'] = language;
                    });
                  },
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
