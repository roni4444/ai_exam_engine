import 'package:ai_exam_engine/models/candidate_model.dart';
import 'package:ai_exam_engine/models/exam_blueprint_model.dart';
import 'package:ai_exam_engine/providers/candidate_provider.dart';
import 'package:ai_exam_engine/providers/exam_blueprint_provider.dart';
import 'package:ai_exam_engine/widgets/candidate_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_config.dart';
import '../providers/supabase_provider.dart';
import '../widgets/blueprint_selection_modal.dart';
import '../widgets/concept_map_widget.dart';
import '../widgets/section_modal.dart';
import '../widgets/weighting_modal.dart';
import '../widgets/library_modal.dart';

enum ProcessingStatus { idle, extracting, translating, analyzing, completed }

class SetupScreen extends StatefulWidget {
  final Function(String text, ExamConfig config, List<AnalyzedChapter> chapters)? onNext;

  const SetupScreen({super.key, this.onNext});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  ProcessingStatus _libraryProcessingStatus = ProcessingStatus.idle;
  ProcessingStatus _candidateProcessingStatus = ProcessingStatus.idle;
  ProcessingStatus _blueprintProcessingStatus = ProcessingStatus.idle;
  List<AnalyzedChapter> _analyzedChapters = [];
  List<Candidate> _fetchedCandidates = [];
  late ExamBlueprint section;

  String sourceText = '';

  String _examName = 'Exam';
  int _studentCount = 3;
  List<String> _studentNames = ['Student 1', 'Student 2', 'Student 3'];

  List<String> _importantChapters = [];
  int _importancePercentage = 70;

  List<ExamSection> sections = [];

  // final PdfService _pdfService = PdfService();
  // final GeminiService _geminiService = GeminiService();
  // // final DbService _dbService = DbService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(child: _buildSourceMaterialColumn()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildExamConfigColumn()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildBlueprintColumn()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Create New Examination',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text('Define your scope, students, and assessment structure below.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              ],
            ),
          ),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDEEBFF),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 255 * 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'STATUS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB), letterSpacing: 1.2),
          ),
          const SizedBox(width: 12),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _getStatusColor()),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_libraryProcessingStatus) {
      case ProcessingStatus.completed:
        return const Color(0xFF22C55E);
      case ProcessingStatus.idle:
        return const Color(0xFFCBD5E1);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _getStatusText() {
    switch (_libraryProcessingStatus) {
      case ProcessingStatus.completed:
        return 'Analysis Ready';
      case ProcessingStatus.idle:
        return 'Awaiting Input';
      case ProcessingStatus.extracting:
        return 'Extracting...';
      case ProcessingStatus.translating:
        return 'Translating...';
      case ProcessingStatus.analyzing:
        return 'Analyzing...';
    }
  }

  Widget _buildSourceMaterialColumn() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildSourceHeader(),
          Expanded(child: _buildSourceContent()),
        ],
      ),
    );
  }

  Widget _buildSourceHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Color(0xFF2563EB), size: 18),
          const SizedBox(width: 8),
          const Text(
            'Source Material',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          /*const Spacer(),
          IconButton(
            icon: const Icon(Icons.photo_library, size: 16),
            color: const Color(0xFF6366F1),
            onPressed: _openLibrary,
            tooltip: 'Select from Library',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, size: 16),
            color: const Color(0xFF2563EB),
            onPressed: null, //_handleFileUpload,
            tooltip: 'Upload PDF',
          ),*/
        ],
      ),
    );
  }

  Widget _buildSourceContent() {
    if (_libraryProcessingStatus == ProcessingStatus.idle) {
      return _buildUploadPrompt();
    }

    if (_libraryProcessingStatus != ProcessingStatus.completed) {
      return _buildProcessingIndicator();
    }

    return _buildAnalyzedContent();
  }

  Widget _buildCandidateList() {
    if (_candidateProcessingStatus == ProcessingStatus.idle) {
      return _buildStudentListSection();
    }

    if (_candidateProcessingStatus != ProcessingStatus.completed) {
      return _buildProcessingIndicator();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SingleChildScrollView(child: Column(children: _buildStudentNameFields())),
    );
  }

  Widget _buildUploadPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /*InkWell(
            onTap: _handleFileUpload,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Color(0xFFDEEBFF), shape: BoxShape.circle),
                    child: const Icon(Icons.upload_file, size: 32, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload PDF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload a textbook or chapter directly.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade300),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 32),*/
          ElevatedButton.icon(
            onPressed: _openLibrary,
            icon: const Icon(Icons.photo_library, size: 16),
            label: const Text('Select from Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2563EB))),
          const SizedBox(height: 24),
          Text(
            _getProcessingMessage(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text('Please wait while we process your selection.', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  String _getProcessingMessage() {
    switch (_libraryProcessingStatus) {
      case ProcessingStatus.extracting:
        return 'Extracting Text...';
      case ProcessingStatus.translating:
        return 'Translating Content...';
      case ProcessingStatus.analyzing:
        return 'Identifying Concepts...';
      default:
        return 'Processing...';
    }
  }

  Widget _buildAnalyzedContent() {
    return SingleChildScrollView(
      child: Column(
        children: [_buildChapterWeightingSummary(), _buildConceptMapHeader(), ..._analyzedChapters.map((chapter) => _buildChapterSection(chapter))],
      ),
    );
  }

  Widget _buildChapterWeightingSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.star, size: 16, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chapter Priorities',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _importantChapters.isEmpty
                            ? 'No specific focus set (Balanced)'
                            : '${_importantChapters.length} chapters selected for $_importancePercentage% focus',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openWeightingModal,
                icon: const Icon(Icons.settings, size: 14),
                label: const Text('Configure Weighting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptMapHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, size: 14, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          const Text(
            'KNOWLEDGE GRAPH',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF334155), letterSpacing: 1.2),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_analyzedChapters.length} Chapters Found',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterSection(AnalyzedChapter chapter) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Text(
            chapter.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
          ),
        ),
        ConceptMapWidget(concepts: chapter.concepts),
      ],
    );
  }

  Widget _buildExamConfigColumn() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildConfigHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildExamNameField(),
                  Expanded(child: _buildCandidateList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: const [
          Icon(Icons.settings, color: Color(0xFF64748B), size: 18),
          SizedBox(width: 8),
          Text(
            'Identity & Cohort',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXAMINATION NAME',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: _examName),
          onChanged: (value) => setState(() => _examName = value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildStudentListSection() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _openGroupList,
            icon: const Icon(Icons.photo_library, size: 16),
            label: const Text('Select from Group List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STUDENT COUNT',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.2),
            ),
            // Row(children: [_buildImportButton(), const SizedBox(width: 8), _buildExportButton()]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: _studentCount.toString()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final count = int.tryParse(value) ?? 1;
                  _handleStudentCountChange(count);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.group, size: 16),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                _buildCounterButton(Icons.keyboard_arrow_up, () => _handleStudentCountChange(_studentCount + 1)),
                const SizedBox(height: 4),
                _buildCounterButton(Icons.keyboard_arrow_down, () => _handleStudentCountChange(_studentCount - 1)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._buildStudentNameFields(),
      ],
    );
  }

  Widget _buildImportButton() {
    return InkWell(
      onTap: _handleBulkUpload,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFDEEBFF), borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.table_chart, size: 12, color: Color(0xFF2563EB)),
            SizedBox(width: 4),
            Text(
              'Import CSV/XLSX',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return InkWell(
      onTap: _downloadStudentList,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.download, size: 12, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text(
              'Export',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFDEEBFF),
          border: Border.all(color: const Color(0xFF93C5FD)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
      ),
    );
  }

  List<Widget> _buildStudentNameFields() {
    return List.generate(_fetchedCandidates.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: const Color(0xFFF8FAFC),
                shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _fetchedCandidates[index].name,
                    /*decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),*/
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 14),
              color: Colors.grey.shade700,
              onPressed: () => _removeStudent(index),
              hoverColor: Colors.red,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBlueprintColumn() {
    return Container(
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
          // _buildBlueprintFooter(),
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
          /*const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildHeaderButton(Icons.file_upload, 'Import XML', _handleImportBlueprint),
              const SizedBox(width: 8),
              _buildHeaderButton(Icons.download, 'Export', _handleExportBlueprint),
            ],
          ),*/
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

  Widget _buildHeaderButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFDEEBFF), borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF2563EB)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBlueprint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /*const Text(
            'No BBlueprint',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),*/
          ElevatedButton.icon(
            onPressed: _openAddSectionModal,
            icon: const Icon(Icons.photo_library, size: 16),
            label: const Text('Select from Blueprints List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        /*if (index == sections.length) {
          return _buildAddSectionButton();
        }*/
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
              /*Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit, size: 14), color: const Color(0xFF94A3B8), onPressed: () => _openEditSectionModal(section)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 14),
                    color: const Color(0xFF94A3B8),
                    onPressed: () => _deleteSection(index),
                  ),
                ],
              ),*/
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

  /*  Widget _buildBlueprintFooter() {
    final canStart = _libraryProcessingStatus == ProcessingStatus.completed && sections.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canStart ? _handleStartClick : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canStart ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            foregroundColor: canStart ? Colors.white : const Color(0xFF94A3B8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: canStart ? 10 : 0,
            shadowColor: canStart ? const Color(0xFF2563EB).withValues(alpha: 255 * 0.3) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Generate Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }*/

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

  void _handleStudentCountChange(int count) {
    final validCount = count < 1 ? 1 : count;
    setState(() {
      _studentCount = validCount;
      if (validCount > _studentNames.length) {
        for (int i = _studentNames.length; i < validCount; i++) {
          _studentNames.add('Student ${i + 1}');
        }
      } else {
        _studentNames = _studentNames.sublist(0, validCount);
      }
    });
  }

  void _handleStudentNameChange(int index, String value) {
    setState(() {
      _studentNames[index] = value;
    });
  }

  void _removeStudent(int index) {
    if (_fetchedCandidates.length > 1) {
      setState(() {
        _fetchedCandidates.removeAt(index);
        // _studentCount = _studentNames.length;
      });
    }
  }

  /*Future<void> _handleFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

      if (result != null && result.files.single.bytes != null) {
        await _processPdfData(result.files.single.bytes!);
      }
    } catch (e) {
      _showError('Failed to upload file: $e');
    }
  }

  Future<void> _processPdfData(Uint8List bytes) async {
    setState(() {
      _processingStatus = ProcessingStatus.extracting;
      _analyzedChapters = [];
      _sourceText = '';
      _importantChapters = [];
    });

    try {
      final fullText = await PdfService.extractTextFromBytes(bytes);

      setState(() => _processingStatus = ProcessingStatus.analyzing);

      final result = await GeminiService.processFullDocument(fullText, (status) {
        setState(() {
          if (status == 'translating') {
            _processingStatus = ProcessingStatus.translating;
          } else if (status == 'extracting_concepts') {
            _processingStatus = ProcessingStatus.analyzing;
          }
        });
      });

      setState(() {
        _sourceText = result['processedText'];
        _analyzedChapters = result['chapters'];
        _examName = result['title'];
        _processingStatus = ProcessingStatus.completed;
      });
    } catch (e) {
      _showError('Failed to process PDF: $e');
      setState(() => _processingStatus = ProcessingStatus.idle);
    }
  }*/

  Future<void> _handleBulkUpload() async {
    // TODO: Implement CSV/XLSX import
    _showInfo('Bulk upload feature coming soon');
  }

  Future<void> _downloadStudentList() async {
    // TODO: Implement student list export
    _showInfo('Export feature coming soon');
  }

  void _openLibrary() {
    showDialog(
      context: context,
      builder: (context) => LibraryModal(onSelect: _handleSelectFromLibrary),
    );
  }

  void _openGroupList() {
    showDialog(
      context: context,
      builder: (context) => CandidateSelectionModal(onSelect: _handleSelectFromGroup),
    );
  }

  Future<void> _handleSelectFromLibrary(String fileName) async {
    Navigator.of(context).pop();
    final supabase = context.read<SupabaseProvider>();
    final user = supabase.client.auth.currentSession?.user.id;
    if (user == null) return;
    // final fullPath = 'library/$user/$fileName';
    final metadata = await supabase.client.from("chapters").select("title, concepts").eq("user_id", user).eq("file_name", fileName);
    if (metadata.isEmpty) return;
    setState(() {
      // _sourceText = metadata['extracted_text'];
      _analyzedChapters = (metadata as List).map((c) => AnalyzedChapter.fromJson(c)).toList();
      // _examName = metadata['title_suggestion'] ?? 'Exam from Library';
      _libraryProcessingStatus = ProcessingStatus.completed;
    });
    return;
  }

  Future<void> _handleSelectFromGroup(String groupName) async {
    Navigator.of(context).pop();
    final supabase = context.read<SupabaseProvider>();
    final candid = context.read<CandidateProvider>();
    final user = supabase.client.auth.currentSession?.user.id;
    if (user == null) return;
    // final fullPath = 'library/$user/$fileName';
    final candidates = await candid.getCandidatesForGroup(groupName);
    // final metadata = await supabase.client.from("chapters").select("title, concepts").eq("user_id", user).eq("file_name", groupName);
    setState(() {
      // _sourceText = metadata['extracted_text'];
      _fetchedCandidates = candidates;
      // _examName = metadata['title_suggestion'] ?? 'Exam from Library';
      _candidateProcessingStatus = ProcessingStatus.completed;
    });
    return;
  }

  void _openWeightingModal() {
    showDialog(
      context: context,
      builder: (context) => WeightingModal(
        chapters: _analyzedChapters,
        importantChapters: _importantChapters,
        importancePercentage: _importancePercentage,
        onSave: (important, percentage) {
          setState(() {
            _importantChapters = important;
            _importancePercentage = percentage;
          });
        },
      ),
    );
  }

  void _openAddSectionModal() {
    showDialog(
      context: context,
      builder: (context) => BlueprintSelectionModal(onSelect: _handleSelectFromBlueprint),
    );
  }

  Future<void> _handleSelectFromBlueprint(String blueprintId) async {
    Navigator.of(context).pop();
    final supabase = context.read<SupabaseProvider>();
    final candid = context.read<ExamBlueprintProvider>();
    final user = supabase.client.auth.currentSession?.user.id;
    if (user == null) return;
    // final fullPath = 'library/$user/$fileName';
    final examSection = await candid.getBlueprintById(blueprintId);
    // final metadata = await supabase.client.from("chapters").select("title, concepts").eq("user_id", user).eq("file_name", groupName);
    if (examSection == null) return;
    setState(() {
      // _sourceText = metadata['extracted_text'];
      sections = examSection.sections;
      // _examName = metadata['title_suggestion'] ?? 'Exam from Library';
      _blueprintProcessingStatus = ProcessingStatus.completed;
    });

    return;
  }

  /*void _openEditSectionModal(ExamSection section) {
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
  }*/

  Future<void> _handleImportBlueprint() async {
    // TODO: Implement XML import
    _showInfo('Import feature coming soon');
  }

  Future<void> _handleExportBlueprint() async {
    // TODO: Implement XML export
    _showInfo('Export feature coming soon');
  }

  /* void _handleStartClick() {
    if (sourceText.isNotEmpty && sections.isNotEmpty) {
      final config = ExamConfig(
        examName: _examName,
        studentCount: _studentCount,
        studentNames: _studentNames,
        sections: sections,
        importantChapters: _importantChapters,
        importancePercentage: _importancePercentage,
      );

      widget.onStart?.call(sourceText, config, _analyzedChapters);
    }
  }*/

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
