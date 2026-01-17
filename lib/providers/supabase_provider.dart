import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exam_config.dart';

class SupabaseProvider with ChangeNotifier {
  late final SupabaseClient _client;

  SupabaseClient get client => _client;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  SupabaseProvider() {
    _client = Supabase.instance.client;
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      // Try a simple query to check connection
      await _client.from('profiles').select('id').limit(1);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      if (kDebugMode) print('Supabase connection check failed: $e');
    }
    notifyListeners();
  }

  Future<void> reconnect() async {
    await _checkConnection();
  }

  // Database operations with error handling

  Future<T?> safeQuery<T>({required Future<T> Function() query, T? defaultValue}) async {
    try {
      return await query();
    } catch (e) {
      if (kDebugMode) print('Query error: $e');
      return defaultValue;
    }
  }

  Future<bool> safeInsert({required String table, required Map<String, dynamic> data}) async {
    try {
      await _client.from(table).insert(data);
      return true;
    } catch (e) {
      if (kDebugMode) print('Insert error: $e');
      return false;
    }
  }

  Future<bool> safeUpdate({required String table, required Map<String, dynamic> data, required String column, required dynamic value}) async {
    try {
      await _client.from(table).update(data).eq(column, value);
      return true;
    } catch (e) {
      if (kDebugMode) print('Update error: $e');
      return false;
    }
  }

  Future<bool> safeDelete({required String table, required String column, required dynamic value}) async {
    try {
      await _client.from(table).delete().eq(column, value);
      return true;
    } catch (e) {
      if (kDebugMode) print('Delete error: $e');
      return false;
    }
  }

  // Storage operations with error handling

  Future<String?> uploadFile({required String bucket, required String path, required dynamic file}) async {
    try {
      await _client.storage.from(bucket).upload(path, file);
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      if (kDebugMode) print('Upload error: $e');
      return null;
    }
  }

  Future<dynamic> downloadFile({required String bucket, required String path}) async {
    try {
      return await _client.storage.from(bucket).download(path);
    } catch (e) {
      if (kDebugMode) print('Download error: $e');
      return null;
    }
  }

  Future<bool> deleteFile({required String bucket, required String path}) async {
    try {
      await _client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      if (kDebugMode) print('Delete file error: $e');
      return false;
    }
  }

  Future<List<FileObject>> listFiles({required String bucket, String? path}) async {
    try {
      return await _client.storage.from(bucket).list(path: path);
    } catch (e) {
      if (kDebugMode) print('List files error: $e');
      return [];
    }
  }

  Future<String?> getCurrentUserId() async {
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  Future<void> uploadLibraryFile(Uint8List bytes, String fileName) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');

    final path = 'library/$userId/$fileName';

    await _client.storage.from('exam-assets').uploadBinary(path, bytes);
    final String url = _client.storage.from('exam-assets').getPublicUrl(path);
    final FileObjectV2 fileInfo = await _client.storage.from('exam-assets').info(path);

    await saveLibraryMetadata(path, fileName, null, null, url, fileInfo.size ?? 1, fileInfo.contentType);
    notifyListeners();
  }

  Future<void> saveLibraryMetadata(
    String filePath,
    String fileName,
    String? lang,
    List<AnalyzedChapter>? chapters,
    String url,
    int size,
    String? fileType,
  ) async {
    final userId = await getCurrentUserId();

    final data = {
      'user_id': userId,
      'file_path': filePath,
      'name': fileName,
      'url': url,
      'size': size,
      'is_gemini_processed': false,
      'file_type': fileType,
      'chapters': chapters?.map((c) => c.toJson()).toList(),
    };

    if (lang != null && lang.isNotEmpty) {
      data['language'] = lang;
    }

    try {
      await _client.from('library_items').upsert(data);
    } catch (e) {
      if (kDebugMode) {
        print('Metadata SQL save failed: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getLibraryMetadata(String filePath) async {
    try {
      final response = await _client.from('library_items').select().eq('file_path', filePath).single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getLibraryFiles() async {
    final userId = await getCurrentUserId();
    if (userId == null) return [];

    try {
      final response = await _client.storage.from('exam-assets').list(path: 'library/$userId');

      return response.where((f) => f.name != '.emptyFolderPlaceholder' && !f.name.endsWith('.meta.json')).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Library fetch error: $e');
      }
      return [];
    }
  }

  Future<Uint8List> downloadLibraryFile(String fileName) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');

    final path = 'library/$userId/$fileName';
    final response = await _client.storage.from('exam-assets').download(path);

    return response;
  }

  Future<void> deleteLibraryItem(String fileName) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');

    final filePath = 'library/$userId/$fileName';

    await _client.from('library_items').delete().eq('file_path', filePath);
    await _client.storage.from('exam-assets').remove([filePath]);
  }
}
