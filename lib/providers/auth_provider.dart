import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_models.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  User? _user;
  UserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      _user = _supabase.auth.currentUser;

      if (_user != null) {
        await _loadProfile(_user!.id);
      }

      _supabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        if (_user != null) {
          _loadProfile(_user!.id);
        } else {
          _profile = null;
        }
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final response = await _supabase.from('profiles').select().eq('id', userId).single();
      if (kDebugMode) {
        print("Response: $response");
      }
      _profile = UserProfile.fromJson(response);
      if (kDebugMode) {
        print("Profile: ${_profile?.fullName}");
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Profile load error: $e');
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(email: email, password: password);

      _user = response.user;
      if (_user != null) {
        await _loadProfile(_user!.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _supabase.auth.signUp(email: email, password: password);

      _user = response.user;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      _profile = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createProfile(UserProfile profile) async {
    try {
      await _supabase.from('profiles').insert(profile.toJson());
      _profile = profile;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
