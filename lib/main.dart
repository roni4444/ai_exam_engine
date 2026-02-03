import 'package:ai_exam_engine/providers/candidate_provider.dart';
import 'package:ai_exam_engine/providers/exam_blueprint_provider.dart';
import 'package:ai_exam_engine/providers/gemini_provider.dart';
import 'package:ai_exam_engine/providers/question_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/supabase_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    // await analytics.logAppOpen();
    // final remoteConfig = FirebaseRemoteConfig.instance;
    // await remoteConfig.setConfigSettings(
    //   RemoteConfigSettings(fetchTimeout: const Duration(minutes: 1), minimumFetchInterval: const Duration(minutes: 1)),
    // );
    // await remoteConfig.fetchAndActivate();
    // final url = remoteConfig.getString("SUPABASE_URL");
    // final key = remoteConfig.getString("SUPABASE_ANON_KEY");
    // if (url.isEmpty || key.isEmpty) {
    //   throw Exception("Supabase credentials are empty! Check Firebase Console.");
    // }
    await Supabase.initialize(
      url: "https://hrxpntqefhfatgoagrsu.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyeHBudHFlZmhmYXRnb2FncnN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMDgyMTAsImV4cCI6MjA4MjU4NDIxMH0.ejIyIACpojXC3EGXpx59cyLY0ClJqL7LHCS_80rErA0",
      debug: kDebugMode,
    );
    final firebaseAppCheck = FirebaseAppCheck.instance;
    if (kDebugMode) {
      await firebaseAppCheck.activate(providerWeb: ReCaptchaV3Provider("6Lc9w00sAAAAAMH511AZ5XnxjUN-1Nm1xahEQCMN"));
    }
    runApp(const MyApp());
  } catch (e, s) {
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text('Initialization Error', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Failed to initialize app: $e', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 24),
                  Text('Tack: ${s.toString()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 24),
                  const Text(
                    'Please check your configuration data',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SupabaseProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => ExamBlueprintProvider()),
        ChangeNotifierProvider(create: (_) => CandidateProvider()),
        ChangeNotifierProvider(create: (_) => GeminiProvider()),
        ChangeNotifierProvider(create: (_) => QuestionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'AI Exam Engine',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme.copyWith(textTheme: GoogleFonts.interTextTheme(themeProvider.lightTheme.textTheme)),
            darkTheme: themeProvider.darkTheme.copyWith(textTheme: GoogleFonts.interTextTheme(themeProvider.darkTheme.textTheme)),
            themeMode: themeProvider.effectiveThemeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
