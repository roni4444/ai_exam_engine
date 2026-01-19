import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_models.dart';

class LibraryProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<LibraryFile> _files = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LibraryFile> get files => _files;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLibraryFiles() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      final response = await supabase.storage.from('exam-assets').list(path: 'library/$userId');
      final response2 = await supabase.from('library_items').select().eq('user_id', userId);

      _files = response.map((file) {
        return LibraryFile(
          name: file.name,
          createdAt: file.createdAt != null ? DateTime.parse(file.createdAt!) : DateTime.now(),
          fullPath: 'library/$userId/${file.name}',
          isGeminiProcessed: response2.firstWhere((item) => item['name'] == file.name && item['user_id'] == userId)['is_gemini_processed'] as bool,
          size: response2.firstWhere((item) => item['name'] == file.name && item['user_id'] == userId)['size'],
          url: response2.firstWhere((item) => item['name'] == file.name && item['user_id'] == userId)['url'],
          language: response2.firstWhere((item) => item['name'] == file.name && item['user_id'] == userId)['language'],
          fileType: response2.firstWhere((item) => item['name'] == file.name && item['user_id'] == userId)['file_type'],
          id: response2.firstWhere((item) => item['name'] == file.name && item['user_id'] == userId)['id'],
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFile(String fileName) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final filePath = 'library/$userId/$fileName';
      await supabase.storage.from('exam-assets').remove([filePath]);
      await supabase.from('library_items').delete().eq('name', fileName).eq('user_id', userId);

      _files.removeWhere((file) => file.name == fileName);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
