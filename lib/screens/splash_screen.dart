import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    if (authProvider.isAuthenticated) {
      if (authProvider.profile == null) {
        if (kDebugMode) {
          print("onboard: ${authProvider.profile?.fullName}");
        }
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OnboardingScreen(userId: authProvider.user!.id)));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 255 * 0.3), blurRadius: 30, spreadRadius: 5)],
              ),
              child: const Icon(Icons.psychology, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'AI Exam Engine',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Powered by Gemini 3',
              style: TextStyle(color: Colors.white.withValues(alpha: 255 * 0.7), fontSize: 16),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
