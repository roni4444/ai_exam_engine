import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/exam_provider.dart';
import '../widgets/student_card_widget.dart';
import 'grading_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final Map<String, bool> _uploadedScripts = {};
  final ImagePicker _picker = ImagePicker();

  // Mock students
  final List<Map<String, dynamic>> _students = [
    {'id': 'S1', 'name': 'Student 1', 'language': 'English'},
    {'id': 'S2', 'name': 'Student 2', 'language': 'English'},
    {'id': 'S3', 'name': 'Student 3', 'language': 'English'},
  ];

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

  void _startGrading() {
    final uploadedCount = _uploadedScripts.values.where((v) => v).length;

    if (uploadedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please upload at least one answer script'), backgroundColor: Colors.red));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GradingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final uploadedCount = _uploadedScripts.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<ExamProvider>(
          builder: (context, examProvider, _) {
            return Text('${examProvider.examName} Distribution');
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam Distribution',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text('Download exams and upload answer scripts for grading', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: uploadedCount / _students.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
                const SizedBox(height: 8),
                Text(
                  '$uploadedCount of ${_students.length} scripts uploaded',
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
                childAspectRatio: 0.85,
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

          // Action Button
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
          ),
        ],
      ),
    );
  }
}
