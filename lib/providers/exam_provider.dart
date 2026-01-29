import 'package:ai_exam_engine/models/candidate_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_models.dart';

enum ExamState { idle, extracting, translating, analyzing, generatingQuestions, reviewingQuestions, distributing, grading, completed }

class ExamProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  ExamState _state = ExamState.idle;
  List<ExamRecord> _recentExams = [];
  List<AnalyzedChapter> _chapters = [];
  List<Question> _questions = [];
  List<Candidate> _students = [];
  String? _currentExamId;
  String _examName = 'New Exam';
  bool _isLoading = false;
  String? _errorMessage;
  int _currentProgress = 0;
  int _totalProgress = 0;

  ExamState get state => _state;
  List<ExamRecord> get recentExams => _recentExams;
  List<AnalyzedChapter> get chapters => _chapters;
  List<Question> get questions => _questions;
  List<Candidate> get students => _students;
  String? get currentExamId => _currentExamId;
  String get examName => _examName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentProgress => _currentProgress;
  int get totalProgress => _totalProgress;

  ExamProvider() {
    loadRecentExams();
  }

  void setExamName(String name) {
    _examName = name;
    notifyListeners();
  }

  void updateProgress(int current, int total) {
    _currentProgress = current;
    _totalProgress = total;
    notifyListeners();
  }

  void setState(ExamState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadRecentExams() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase.from('exams').select().eq('user_id', userId).order('created_at', ascending: false).limit(5);
      _recentExams = response.where((test) => test['state'] != null).toList().map((e) => ExamRecord.fromJson(e)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createExam({required String name, required Map<String, dynamic> config, required String state}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.from('exams').insert({'name': name, 'config': config, 'state': state, 'user_id': userId}).select().single();

      _currentExamId = response['id'];
      return _currentExamId;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<void> saveChapters(String examId, List<AnalyzedChapter> chapters) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final rows = chapters
          .map((c) => {'exam_id': examId, 'title': c.title, 'concepts': c.concepts.map((concept) => concept.toJson()).toList(), 'user_id': userId})
          .toList();

      await _supabase.from('chapters').insert(rows);
      _chapters = chapters;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> saveQuestions(String examId, List<Question> questions) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final rows = questions.map((q) => {'id': q.id, 'exam_id': examId, 'text': q.text, 'data': q.toJson(), 'user_id': userId}).toList();

      await _supabase.from('questions').upsert(rows);
      _questions = questions;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> saveStudents(String examId, List<Candidate> students) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final rows = students.map((s) => {'id': s.id, 'name': s.name, 'user_id': userId}).toList();

      await _supabase.from('students').upsert(rows);
      _students = students;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<Map<String, dynamic>?> loadExamData(String examId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final exam = await _supabase.from('exams').select().eq('id', examId).single();
      if (kDebugMode) {
        print("exam ${exam["state"]}");
      }

      final chapters = await _supabase.from('chapters').select().eq('file_id', exam['library_id']);

      // final questions = await _supabase.from('questions').select().eq('exam_id', examId);

      final candidate = await _supabase.from('candidate_group_members').select().eq('group_id', exam['candidate_group_id']);

      _currentExamId = examId;
      _examName = exam['name'];
      // _chapters = (chapters as List).map((c) => AnalyzedChapter.fromJson({'title': c['title'], 'concepts': c['concepts']})).toList();

      // _questions = (questions as List).map((q) => Question.fromJson(q['data'])).toList();

      // _students = (candidate as List).map((s) => Candidate.fromJson({'id': s['id']})).toList();

      return {'state': exam["state"]};
      // return {'config': exam['config'], 'state': exam['state'], 'allocations': exam['allocations'] ?? {}};
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print(_errorMessage);
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _state = ExamState.idle;
    _chapters = [];
    _questions = [];
    _students = [];
    _currentExamId = null;
    _examName = 'New Exam';
    _currentProgress = 0;
    _totalProgress = 0;
    notifyListeners();
  }
}
