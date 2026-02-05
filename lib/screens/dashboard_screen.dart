import 'dart:math';

import 'package:ai_exam_engine/providers/candidate_provider.dart';
import 'package:ai_exam_engine/providers/exam_blueprint_provider.dart';
import 'package:ai_exam_engine/screens/question_generation_screen.dart';
import 'package:ai_exam_engine/screens/review_questions_screen.dart';
import 'package:ai_exam_engine/screens/settings_screen.dart';
import 'package:ai_exam_engine/screens/simulation_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import '../models/candidate_model.dart';
import '../models/exam_config.dart';
import '../models/exam_models.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/library_provider.dart';
import '../providers/question_provider.dart';
import '../providers/supabase_provider.dart';
import '../widgets/action_card_widget.dart';
import '../widgets/add_candidate_group_modal.dart';
import '../widgets/add_candidate_modal.dart';
import '../widgets/blueprint_card_widget.dart';
import '../widgets/candidate_card_widget.dart';
import '../widgets/exam_card_widget.dart';
import '../widgets/library_file_card_widget.dart';
import '../widgets/section_modal.dart';
import 'setup_screen.dart';
import 'results_screen.dart';
import 'package:timelines_plus/timelines_plus.dart';

enum ProcessingStatus { idle, extracting, analyzing, completed }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  TextEditingController nameController = TextEditingController();
  late PageController _pageViewController;
  List<ExamSection> sections = [];
  List<Question> _questions = [];
  int selectedIndex = 0;
  int processIndex = -10;
  // final TextEditingController _controller = TextEditingController();
  final completeColor = Color(0xff5e6172);
  final inProgressColor = Color(0xff5ec792);
  final todoColor = Color(0xffd1d2d7);
  final processes = ['Setup Exam', 'Question Generation', 'Question Distribution', 'Grading and Evaluation', 'Report Generation'];
  final List<IconData> processesIcons = [Icons.settings, Icons.auto_fix_high, Icons.send, Icons.grading, Icons.summarize];
  ProcessingStatus processingStatus = ProcessingStatus.idle;
  String? selectedGroupId;
  String _examId = "";
  String _language = "";
  ExamConfig? _config;
  // List<Candidate> filteredCandidates = [];
  // List<Candidate> unfilteredCandidates = [];

  Color getColor(int index) {
    if (index == processIndex) {
      return inProgressColor;
    } else if (index < processIndex) {
      return completeColor;
    } else {
      return todoColor;
    }
  }

  void _handleFileUpload(SupabaseProvider supabaseClient) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        await supabaseClient.uploadLibraryFile(bytes, fileName);
      }
    } catch (e) {
      _showError('Failed to upload file: $e');
    }
  }

  /*// Helper method to get group color
  Color _getGroupColor(String groupId, CandidateProvider candidateProvider) {
    // final candidateProvider = context.read<CandidateProvider>();
    final group = candidateProvider.groups.firstWhere((g) => g.id == groupId);

    final color = group.color;
    if (color != null) {
      return Color(int.parse(color.replaceFirst('#', '0xff')));
    }

    // Fallback colors based on group ID
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.teal];

    return colors[groupId.hashCode % colors.length];
  }

  // Helper method to get group name
  String _getGroupName(String groupId, CandidateProvider candidateProvider) {
    // final candidateProvider = context.read<CandidateProvider>();
    final group = candidateProvider.groups.firstWhere((g) => g.id == groupId);
    return group.name ?? 'Unknown Group';
  }*/

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController(initialPage: 0);
    // tabController = TabController(initialIndex: 0, length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadRecentExams();
      // context.read<LibraryProvider>().loadLibraryFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supabaseClient = context.read<SupabaseProvider>();
    return Scaffold(
      appBar: AppBar(
        leadingWidth: MediaQuery.of(context).size.longestSide / 8 + MediaQuery.of(context).size.longestSide / 6,
        leading: Padding(
          padding: EdgeInsets.only(left: MediaQuery.of(context).size.longestSide / 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: SvgPicture.asset("assets/logo/AI_Exam_Engine_Logo.svg", semanticsLabel: 'AI Exam Engine Logo'),
              ),
              /*Container(
                // width: 60,
                // height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 255 * 0.3), blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Icon(Icons.psychology, size: 40, color: Colors.white),
              ),*/
              // const SizedBox(width: 5),
              Expanded(
                child: const Text(
                  'AI Exam Engine',
                  style: TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // title: const Text('Dashboard'),
        // centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actionsPadding: EdgeInsets.only(right: MediaQuery.of(context).size.longestSide / 7),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // bg-blue-50
              borderRadius: BorderRadius.circular(999), // rounded-full
              border: Border.all(
                color: const Color(0xFFDBEAFE), // border-blue-100
              ),
            ),
            child: Text(
              'GEMINI 3 POWERED',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2, // tracking-wider
                color: Color(0xFF1D4ED8), // text-blue-700
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton(
                position: PopupMenuPosition.under,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(authProvider.profile?.fullName[0].toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(authProvider.profile?.fullName ?? 'User', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(authProvider.profile?.role.toUpperCase() ?? '', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'signout') {
                    context.read<AuthProvider>().signOut();
                  }
                  if (value == 'settings') {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            extended: true,
            minExtendedWidth: MediaQuery.of(context).size.longestSide / 8,
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(icon: const Icon(Icons.home), label: const Text('Dashboard')),
              NavigationRailDestination(icon: const Icon(Icons.file_copy_sharp), label: const Text('Resources')),
              NavigationRailDestination(icon: const Icon(Icons.group), label: const Text('Candidate')),
              NavigationRailDestination(icon: const Icon(Icons.assignment), label: const Text('Exam Blueprint')),
            ],
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
                processIndex = -10;
                _pageViewController.jumpToPage(0);
                if (selectedIndex == 0) {
                  context.read<ExamProvider>().loadRecentExams();
                }
                if (selectedIndex == 1) {
                  context.read<LibraryProvider>().loadLibraryFiles();
                }
                if (selectedIndex == 2) {
                  context.read<CandidateProvider>().fetchCandidates();
                  context.read<CandidateProvider>().fetchGroups();
                }
                if (selectedIndex == 3) {
                  context.read<ExamBlueprintProvider>().fetchBlueprints();
                }
                final qProvider = context.read<QuestionProvider>();
                qProvider.cancelGeneration();
                qProvider.questions.clear();
              });
            },
          ),
          const VerticalDivider(width: 1, thickness: 2, color: Color(0xFFE2E8F0)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: (processIndex < 0) ? 0 : 10,
                  child: Offstage(
                    offstage: processIndex < 0 || processIndex >= processes.length,
                    child: SizedBox(
                      height: 100,
                      child: Timeline.tileBuilder(
                        // shrinkWrap: true,
                        semanticChildCount: processes.length,
                        theme: TimelineThemeData(direction: Axis.horizontal, connectorTheme: const ConnectorThemeData(space: 10.0, thickness: 5.0)),
                        builder: TimelineTileBuilder.connected(
                          connectionDirection: ConnectionDirection.before,
                          itemExtentBuilder: (_, _) => MediaQuery.of(context).size.longestSide / processes.length / 1.5,
                          oppositeContentsBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: Icon(processesIcons[index], color: getColor(index), size: 35.0),
                              // child: Image.asset('assets/images/process_timeline/status${index + 1}.png', width: 50.0, color: getColor(index)),
                            );
                          },
                          contentsBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Text(
                                processes[index],
                                style: TextStyle(fontWeight: FontWeight.bold, color: getColor(index)),
                              ),
                            );
                          },
                          indicatorBuilder: (_, index) {
                            Color color;
                            Widget? child;
                            if (index == processIndex) {
                              color = inProgressColor;
                              child = const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 3.0, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              );
                            } else if (index < processIndex) {
                              color = completeColor;
                              child = const Icon(Icons.check, color: Colors.white, size: 15.0);
                            } else {
                              color = todoColor;
                            }

                            if (index <= processIndex) {
                              return Stack(
                                children: [
                                  CustomPaint(
                                    size: const Size(30.0, 30.0),
                                    painter: _BezierPainter(color: color, drawStart: index > 0, drawEnd: index < processIndex),
                                  ),
                                  DotIndicator(size: 30.0, color: color, child: child),
                                ],
                              );
                            } else {
                              return Stack(
                                children: [
                                  CustomPaint(
                                    size: const Size(15.0, 15.0),
                                    painter: _BezierPainter(color: color, drawEnd: index < processes.length - 1),
                                  ),
                                  OutlinedDotIndicator(borderWidth: 4.0, color: color),
                                ],
                              );
                            }
                          },
                          connectorBuilder: (_, index, type) {
                            if (index > 0) {
                              if (index == processIndex) {
                                final prevColor = getColor(index - 1);
                                final color = getColor(index);
                                List<Color> gradientColors;
                                if (type == ConnectorType.start) {
                                  gradientColors = [Color.lerp(prevColor, color, 0.5)!, color];
                                } else {
                                  gradientColors = [prevColor, Color.lerp(prevColor, color, 0.5)!];
                                }
                                return DecoratedLineConnector(
                                  decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors)),
                                );
                              } else {
                                return SolidLineConnector(color: getColor(index));
                              }
                            } else {
                              return null;
                            }
                          },
                          itemCount: processes.length,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 40,
                  child: PageView(
                    controller: _pageViewController,
                    onPageChanged: (page) {
                      if (page == 3) {
                        context.read<QuestionProvider>().loadQuestions(null);
                      }
                      setState(() {
                        processIndex = page - 1;
                      });
                    },
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.longestSide / 30,
                          top: MediaQuery.of(context).size.longestSide / 60,
                          right: MediaQuery.of(context).size.longestSide / 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Consumer<AuthProvider>(
                                          builder: (context, authProvider, _) {
                                            return Text(
                                              'Hello, ${authProvider.profile?.fullName.split(' ')[0] ?? 'Teacher'}!',
                                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Welcome to your AI Exam Engine dashboard', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ActionCard(
                                          icon: Icons.add_circle_outline,
                                          title: 'Create New Exam',
                                          subtitle: 'Generate from content',
                                          color: const Color(0xFF2563EB),
                                          onTap: () {
                                            // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetupScreen()));
                                            setState(() {
                                              _pageViewController.jumpToPage(1);
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        ActionCard(
                                          icon: Icons.upload_file,
                                          title: 'Grade Existing',
                                          subtitle: 'Upload answer scripts',
                                          color: const Color(0xFF059669),
                                          onTap: () {
                                            // Navigate to direct grading
                                            setState(() {
                                              _pageViewController.jumpToPage(3);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 64),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.history, size: 20, color: Color(0xFF64748B)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'RECENT ACTIVITY',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[600],
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Consumer<ExamProvider>(
                                            builder: (context, examProvider, _) {
                                              if (examProvider.isLoading) {
                                                return const Center(child: CircularProgressIndicator());
                                              }

                                              if (examProvider.recentExams.isEmpty) {
                                                return Container(
                                                  padding: const EdgeInsets.all(32),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid, width: 2),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                                                      const SizedBox(height: 16),
                                                      Text("You haven't created any exams yet", style: TextStyle(color: Colors.grey[600])),
                                                      const SizedBox(height: 16),
                                                      TextButton(
                                                        onPressed: () {
                                                          // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetupScreen()));
                                                          setState(() {
                                                            _pageViewController.jumpToPage(1);
                                                          });
                                                        },
                                                        child: const Text('Get Started'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              return Column(
                                                children: examProvider.recentExams.map((exam) {
                                                  return ExamCard(
                                                    exam: exam,
                                                    onTap: () async {
                                                      final data = await examProvider.loadExamData(exam.id);
                                                      if (!context.mounted) return;
                                                      if (kDebugMode) {
                                                        print("data ${data!['state']}");
                                                      }
                                                      _examId = exam.id;
                                                      if (data != null && data['state'] == 'setup') {
                                                        _pageViewController.jumpToPage(1);
                                                      }
                                                      if (data != null && data['state'] == 'setupComplete') {
                                                        _pageViewController.jumpToPage(2);
                                                      }
                                                    },
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    // const SizedBox(width: 24),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.folder_outlined, size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Resources',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2),
                                    ),
                                    Container(
                                      constraints: BoxConstraints(maxWidth: 200),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _handleFileUpload(supabaseClient);
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            // foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF16A34A).withValues(alpha: 255 * 0.3),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add, size: 20, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add Files',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Consumer<LibraryProvider>(
                                  builder: (context, libraryProvider, _) {
                                    if (libraryProvider.isLoading) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    if (libraryProvider.files.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                                        child: Center(
                                          child: Text('No files saved yet', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: libraryProvider.files.map((file) {
                                        return LibraryFileCard(
                                          file: file,
                                          onDelete: () {
                                            libraryProvider.deleteFile(file.name);
                                          },
                                          processingStatus: processingStatus,
                                          /*geminiAction: () {
                                            final response = await GeminiService.genAIOnPDF(
                                              fileName: file.name,
                                              onStatusUpdate: (status) {
                                                setState(() {
                                                  if (status == 'extracting_concepts') {
                                                    processingStatus = ProcessingStatus.extracting;
                                                  } else if (status == 'analyzing_concepts') {
                                                    processingStatus = ProcessingStatus.analyzing;
                                                  } else if (status == 'completed') {
                                                    processingStatus = ProcessingStatus.completed;
                                                  }
                                                });
                                              },
                                            );
                                            if (kDebugMode) {
                                              print(response);
                                            }
                                          },*/
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.folder_outlined, size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Candidates',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2),
                                    ),
                                    Container(
                                      constraints: BoxConstraints(maxWidth: 250),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  AddCandidateModal(onCandidateAdded: () => context.read<CandidateProvider>().fetchCandidates()),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            // foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF16A34A).withValues(alpha: 255 * 0.3),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add, size: 20, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add Candidate',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      constraints: BoxConstraints(maxWidth: 200),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => CreateCandidateGroupModal(onGroupCreated: () {}),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            // foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF16A34A).withValues(alpha: 255 * 0.3),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add, size: 20, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add Group',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Consumer<CandidateProvider>(
                                  builder: (context, candidateProvider, _) {
                                    if (candidateProvider.isLoading) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    if (candidateProvider.candidates.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                                        child: Center(
                                          child: Text('No candidate saved yet', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                        ),
                                      );
                                    }

                                    return Expanded(
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Filter by Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 8,
                                                  children: candidateProvider.groups.map((group) {
                                                    final isSelected = selectedGroupId == group.id;

                                                    return ChoiceChip(
                                                      label: Text(group.name),
                                                      selected: isSelected,
                                                      onSelected: (bool selected) {
                                                        setState(() {
                                                          // Toggle selection - if already selected, deselect it
                                                          selectedGroupId = selected ? group.id : null;
                                                        });
                                                      },
                                                      selectedColor: Colors.cyan,
                                                      backgroundColor: Colors.grey[200],
                                                      labelStyle: TextStyle(
                                                        color: isSelected ? Colors.white : Colors.black87,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                                // Clear filter button
                                                if (selectedGroupId != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          selectedGroupId = null;
                                                        });
                                                      },
                                                      child: const Text('Clear Filter'),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Divider(),
                                          Expanded(
                                            child: FutureBuilder(
                                              future: candidateProvider.getCandidatesForGroup(selectedGroupId),
                                              builder: (context, asyncSnapshot) {
                                                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                                                  return const Center(child: CircularProgressIndicator());
                                                }
                                                if (asyncSnapshot.hasError) {
                                                  return Text('Error: ${asyncSnapshot.error}');
                                                }
                                                if (asyncSnapshot.hasData) {
                                                  final filteredCandidates = asyncSnapshot.data ?? [];
                                                  if (filteredCandidates.isEmpty || selectedGroupId == null) {
                                                    return ListView.builder(
                                                      padding: const EdgeInsets.all(16),
                                                      itemCount: candidateProvider.candidates.length,
                                                      itemBuilder: (context, index) {
                                                        final candidate = candidateProvider.candidates[index];
                                                        return CandidateCard(
                                                          file: candidate,
                                                          onDelete: () {
                                                            candidateProvider.deleteCandidate(candidate.name);
                                                          },
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    return ListView.builder(
                                                      padding: const EdgeInsets.all(16),
                                                      itemCount: filteredCandidates.length,
                                                      itemBuilder: (context, index) {
                                                        final candidate = filteredCandidates[index];
                                                        // final isHighlighted = selectedGroupId == candidate.id;
                                                        // final groupColor = getGroupColor(candidate.id);
                                                        // final groupName = getGroupName(candidate.id);

                                                        return CandidateCard(
                                                          file: candidate,
                                                          // isHighlighted: isHighlighted,
                                                          // groupColor: Colors.cyan,
                                                          // groupName: candidateProvider.groups[index].name,
                                                          onDelete: () {
                                                            candidateProvider.deleteCandidate(candidate.name);
                                                          },
                                                        );
                                                      },
                                                    );
                                                  }
                                                }
                                                return SizedBox.shrink();
                                              },
                                            ),
                                          ),
                                          /* Column(
                                            children: candidateProvider.candidates.map((file) {
                                              return CandidateCard(
                                                file: file,
                                                onDelete: () {
                                                  candidateProvider.deleteCandidate(file.name);
                                                },
                                              );
                                            }).toList(),
                                          ),*/
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.question_answer, size: 20, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Blueprints',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2),
                                    ),
                                    Container(
                                      constraints: BoxConstraints(maxWidth: 300),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {});
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            // foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 10,
                                            shadowColor: const Color(0xFF16A34A).withValues(alpha: 255 * 0.3),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add, size: 20, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add Exam Blueprint',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Consumer<ExamBlueprintProvider>(
                                        builder: (context, examBlueprintProvider, _) {
                                          if (examBlueprintProvider.isLoading) {
                                            return const Center(child: CircularProgressIndicator());
                                          }

                                          if (examBlueprintProvider.blueprints.isEmpty) {
                                            return Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                                              child: Center(
                                                child: Text('No blueprints saved yet', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                              ),
                                            );
                                          }

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: examBlueprintProvider.blueprints.map((file) {
                                              return ExamBlueprintCard(
                                                file: file,
                                                onDelete: () {
                                                  examBlueprintProvider.deleteBlueprint(file.name);
                                                },
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        height: 700,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade200),
                                          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 2))],
                                        ),
                                        child: Column(
                                          children: [
                                            _buildBlueprintHeader(),
                                            Expanded(child: sections.isEmpty ? _buildEmptyBlueprint() : _buildSectionsList()),
                                            _buildBlueprintFooter(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ][selectedIndex],
                        ),
                      ),
                      SetupScreen(onNext: onSetupScreenNext),
                      QuestionGenerationScreen(examId: _examId, config: _config, onNext: onQuestionScreenNext, language: _language),
                      SimulationScreen(),
                    ],
                  ),
                ),
                Expanded(
                  flex: (processIndex < 0) ? 0 : 7,
                  child: Offstage(
                    offstage: processIndex < 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border(top: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_pageViewController.hasClients) {
                                    if (_pageViewController.page == 1) {
                                      selectedIndex = 0;
                                      processIndex = -10;
                                      _pageViewController.jumpToPage(0);
                                      if (selectedIndex == 0) {
                                        context.read<ExamProvider>().loadRecentExams();
                                      }
                                    }
                                    if (_pageViewController.page == 2) {
                                      _pageViewController.jumpToPage(1);
                                    }
                                    if (_pageViewController.page == 3) {
                                      _pageViewController.jumpToPage(2);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  // foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 10,
                                  shadowColor: const Color(0xFF16A34A).withValues(alpha: 255 * 0.3),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back, size: 20, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Bo Back',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: _buildPageViewFooter()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintHeader() {
    final totalQuestions = _calculateTotalQuestions();
    final totalMarks = _calculateTotalMarks();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: Color(0xFF8B5CF6), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Exam Blueprint',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              _buildBadge('$totalQuestions Qs', const Color(0xFFE2E8F0), const Color(0xFF334155)),
              const SizedBox(width: 8),
              _buildBadge('$totalMarks Pts', const Color(0xFF8B5CF6), Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Blueprint Name",
                    filled: true,
                    fillColor: Colors.white,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildEmptyBlueprint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No Assessment Sections',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _openAddSectionModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create First Section', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == sections.length) {
          return _buildAddSectionButton();
        }
        return _buildSectionCard(sections[index], index);
      },
    );
  }

  Widget _buildSectionCard(ExamSection section, int index) {
    final totalItems = section.questionTypes.fold<int>(0, (sum, qt) => sum + qt.count.easy + qt.count.medium + qt.count.hard + (qt.scenarios.length));
    final totalMarks = section.questionTypes.fold<int>(0, (sum, qt) {
      if (qt.type == 'Scenario Based' && qt.scenarios.isNotEmpty) {
        return sum + qt.scenarios.fold<int>(0, (s, sc) => s + sc.subQuestions.fold<int>(0, (sq, sub) => sq + (sub.marks * sub.count)));
      }
      return sum + (qt.marks * (qt.count.easy + qt.count.medium + qt.count.hard));
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$totalItems ITEMS',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$totalMarks MARKS',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit, size: 14), color: const Color(0xFF94A3B8), onPressed: () => _openEditSectionModal(section)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 14),
                    color: const Color(0xFF94A3B8),
                    onPressed: () => _deleteSection(index),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...section.questionTypes
              .where((qt) => qt.count.easy + qt.count.medium + qt.count.hard > 0 || qt.scenarios.isNotEmpty)
              .map((qt) => _buildQuestionTypeCard(qt)),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeCard(QuestionTypeConfig qt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 255 * 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qt.type,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (qt.type != 'Scenario Based') _buildInfoChip('${qt.marks} Marks Each', const Color(0xFFF1F5F9), const Color(0xFF475569)),
                        if (qt.negativeMarks) _buildInfoChip('-${qt.negativeValue} Penalty', const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
                        if (qt.partialScoring) _buildInfoChip('Partial Credit', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
                        if (qt.orCount > 0) _buildInfoChip('${qt.orCount} OR Pairs', const Color(0xFFDEEBFF), const Color(0xFF2563EB)),
                        if (qt.type == 'Scenario Based')
                          _buildInfoChip('${qt.scenarios.length} Scenarios', const Color(0xFFF3E8FF), const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (qt.type != 'Scenario Based') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDifficultyBadge('Easy', qt.count.easy, const Color(0xFF22C55E)),
                const SizedBox(width: 8),
                _buildDifficultyBadge('Medium', qt.count.medium, const Color(0xFFEAB308)),
                const SizedBox(width: 8),
                _buildDifficultyBadge('Hard', qt.count.hard, const Color(0xFFEF4444)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: qt.bloomsDistribution.map((bloom) {
              if (bloom.count != 0) {
                return Card.outlined(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${bloom.level}:", style: TextStyle(color: Colors.grey)),
                        Text("${bloom.count}", style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 255 * 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildDifficultyBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: count > 0 ? color : const Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSectionButton() {
    return InkWell(
      onTap: _openAddSectionModal,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Add Assessment Section',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  Widget _buildBlueprintFooter() {
    return Consumer<ExamBlueprintProvider>(
      builder: (context, examBlueprintProvider, _) {
        if (examBlueprintProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: sections.isEmpty
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a section name')));
                        return;
                      }
                      await examBlueprintProvider.createBlueprint(name: nameController.text.trim().titleCase, sections: sections);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: const Color(0xFF2563EB).withValues(alpha: 255 * 0.3),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Save Blueprint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageViewFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            if (_pageViewController.hasClients) {
              if (_pageViewController.page == 1) {
                final examProvider = context.read<ExamProvider>();
                await _pageViewController.animateToPage(2, duration: Duration(seconds: 3), curve: Curves.easeInOut);
                if (!mounted) return;
                examProvider.loadRecentExams();
              } else if (_pageViewController.page == 2) {
                await _pageViewController.animateToPage(3, duration: Duration(seconds: 3), curve: Curves.easeInOut);
              }
            }
            if (kDebugMode) {
              print(_pageViewController.page);
            }
            setState(() {});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            // foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
            shadowColor: const Color(0xFF2563EB).withValues(alpha: 255 * 0.3),
          ),
          child: (_pageViewController.hasClients)
              ? (_pageViewController.page == 1)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Save and Next',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                        ],
                      )
                    : (_pageViewController.page == 2)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, color: Colors.white),
                          const SizedBox(width: 8),
                          Consumer<ExamProvider>(
                            builder: (context, examProvider, _) {
                              return Text(
                                'Distribute to ${examProvider.students.isNotEmpty ? examProvider.students.length : '3'} Students',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Preparing....',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          SizedBox(width: 18),
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3.0,
                            constraints: BoxConstraints(maxWidth: 18, minWidth: 18, maxHeight: 18, minHeight: 18),
                          ),
                        ],
                      )
              : null,
        ),
      ),
    );
  }

  // Helper methods
  int _calculateTotalQuestions() {
    return sections.fold<int>(
      0,
      (total, section) =>
          total + section.questionTypes.fold<int>(0, (s, qt) => s + qt.count.easy + qt.count.medium + qt.count.hard + qt.scenarios.length),
    );
  }

  int _calculateTotalMarks() {
    return sections.fold<int>(
      0,
      (total, section) =>
          total +
          section.questionTypes.fold<int>(0, (s, qt) {
            if (qt.type == 'Scenario Based' && qt.scenarios.isNotEmpty) {
              return s + qt.scenarios.fold<int>(0, (ss, sc) => ss + sc.subQuestions.fold<int>(0, (sqs, sq) => sqs + (sq.marks * sq.count)));
            }
            return s + (qt.marks * (qt.count.easy + qt.count.medium + qt.count.hard));
          }),
    );
  }

  void _openAddSectionModal() {
    showDialog(
      context: context,
      builder: (context) => SectionModal(
        onSave: (section) {
          setState(() {
            sections.add(section);
          });
        },
      ),
    );
  }

  void _openEditSectionModal(ExamSection section) {
    showDialog(
      context: context,
      builder: (context) => SectionModal(
        section: section,
        onSave: (updatedSection) {
          setState(() {
            final index = sections.indexWhere((s) => s.id == section.id);
            if (index != -1) {
              sections[index] = updatedSection;
            }
          });
        },
      ),
    );
  }

  void _deleteSection(int index) {
    setState(() {
      sections.removeAt(index);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> onSetupScreenNext({required String examId, required ExamConfig config, required String language}) async {
    // Navigator.of(context).pop();
    final supabase = context.read<SupabaseProvider>();
    final user = supabase.client.auth.currentSession?.user.id;
    if (user == null) return;
    _examId = examId;
    _config = config;
    _language = language;

    // print("here");
    // await _pageViewController.animateToPage(2, duration: Duration(seconds: 3), curve: Curves.easeInOut);
    // final fullPath = 'library/$user/$fileName';
    // final metadata = await supabase.client.from("chapters").select("title, concepts").eq("user_id", user).eq("file_name", fileName);
    // if (metadata.isEmpty) return;
    /*setState(() {

      // _sourceText = metadata['extracted_text'];
      // _analyzedChapters = (metadata as List).map((c) => AnalyzedChapter.fromJson(c)).toList();
      // _examName = metadata['title_suggestion'] ?? 'Exam from Library';
      // _libraryProcessingStatus = ProcessingStatus.completed;
    });*/
    // return;
  }

  Future<void> onQuestionScreenNext({required List<Question> questions}) async {
    // Navigator.of(context).pop();
    final supabase = context.read<SupabaseProvider>();
    final user = supabase.client.auth.currentSession?.user.id;
    if (user == null) return;
    _questions = questions;
  }
}

class _BezierPainter extends CustomPainter {
  const _BezierPainter({required this.color, this.drawStart = true, this.drawEnd = true});

  final Color color;
  final bool drawStart;
  final bool drawEnd;

  Offset _offset(double radius, double angle) {
    return Offset(radius * cos(angle) + radius, radius * sin(angle) + radius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final radius = size.width / 2;

    double angle;
    Offset offset1;
    Offset offset2;

    Path path;

    if (drawStart) {
      angle = 3 * pi / 4;
      offset1 = _offset(radius, angle);
      offset2 = _offset(radius, -angle);
      path = Path()
        ..moveTo(offset1.dx, offset1.dy)
        ..quadraticBezierTo(0.0, size.height / 2, -radius, radius) // TODO connector start & gradient
        ..quadraticBezierTo(0.0, size.height / 2, offset2.dx, offset2.dy)
        ..close();

      canvas.drawPath(path, paint);
    }
    if (drawEnd) {
      angle = -pi / 4;
      offset1 = _offset(radius, angle);
      offset2 = _offset(radius, -angle);

      path = Path()
        ..moveTo(offset1.dx, offset1.dy)
        ..quadraticBezierTo(size.width, size.height / 2, size.width + radius, radius) // TODO connector end & gradient
        ..quadraticBezierTo(size.width, size.height / 2, offset2.dx, offset2.dy)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BezierPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.drawStart != drawStart || oldDelegate.drawEnd != drawEnd;
  }
}
