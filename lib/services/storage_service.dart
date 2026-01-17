import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class StorageService {
  static final _supabase = Supabase.instance.client;

  static Future<String> uploadFile(File file, String path) async {
    final response = await _supabase.storage.from('exam-assets').upload(path, file);

    final url = _supabase.storage.from('exam-assets').getPublicUrl(path);

    return url;
  }

  static Future<void> deleteFile(String path) async {
    await _supabase.storage.from('exam-assets').remove([path]);
  }
}
