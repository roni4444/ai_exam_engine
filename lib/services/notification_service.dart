import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/onesignal_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  String? _playerId;

  String? get playerId => _playerId;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize OneSignal
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      OneSignal.initialize(OneSignalConfig.appId);

      // Request notification permissions (iOS)
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification opened handler
      OneSignal.Notifications.addClickListener(_onNotificationOpened);

      // Set up notification received handler (foreground)
      OneSignal.Notifications.addForegroundWillDisplayListener(_onForegroundNotification);

      // Get the OneSignal player ID
      final status = await OneSignal.User.getOnesignalId();
      _playerId = status;

      if (kDebugMode) {
        print('OneSignal Player ID: $_playerId');
      }

      // Set external user ID (optional - for linking with your backend)
      // OneSignal.login("your_user_id");

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('OneSignal initialization error: $e');
      }
    }
  }

  void _onNotificationOpened(OSNotificationClickEvent event) {
    if (kDebugMode) {
      print('Notification opened: ${event.notification.title}');
      print('Additional data: ${event.notification.additionalData}');
    }

    // Handle navigation based on additional data
    final data = event.notification.additionalData;
    if (data != null) {
      _handleNotificationAction(data);
    }
  }

  void _onForegroundNotification(OSNotificationWillDisplayEvent event) {
    if (kDebugMode) {
      print('Foreground notification: ${event.notification.title}');
    }

    // Display the notification even when app is in foreground
    event.notification.display();
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    // Handle navigation based on notification data
    final action = data['action'] as String?;

    switch (action) {
      case 'chapter_analysis_complete':
        // Navigate to review screen
        break;
      case 'question_generation_complete':
        // Navigate to questions review
        break;
      case 'grading_complete':
        // Navigate to results
        break;
      default:
        // Default action
        break;
    }
  }

  // Send local notification (appears immediately)
  Future<void> showNotification({required String title, required String body, Map<String, dynamic>? additionalData}) async {
    try {
      // OneSignal doesn't have a direct "local notification" API
      // Instead, you would typically trigger notifications from your backend
      // For immediate local-like behavior, you can use tags to send to specific users

      if (kDebugMode) {
        print('Notification: $title - $body');
      }

      // Alternative: Show in-app message
      // This would require implementing a custom in-app notification UI
    } catch (e) {
      if (kDebugMode) {
        print('Show notification error: $e');
      }
    }
  }

  // Trigger notification from backend (recommended approach)
  Future<void> sendNotificationViaBackend({required String title, required String body, Map<String, dynamic>? data, List<String>? playerIds}) async {
    // This would call your backend API which then uses OneSignal REST API
    // Example implementation in your backend:
    /*
    POST https://onesignal.com/api/v1/notifications
    Headers:
      Authorization: Basic YOUR_REST_API_KEY
      Content-Type: application/json

    Body:
    {
      "app_id": "YOUR_APP_ID",
      "include_player_ids": playerIds or ["ALL"],
      "headings": {"en": title},
      "contents": {"en": body},
      "data": data
    }
    */
  }

  // Specific notification methods for exam workflow

  Future<void> notifyChapterAnalysisComplete({required int chaptersFound, required int conceptsFound}) async {
    await showNotification(
      title: '✅ Chapter Analysis Complete',
      body: 'Found $chaptersFound chapters with $conceptsFound concepts',
      additionalData: {'action': 'chapter_analysis_complete', 'chapters': chaptersFound, 'concepts': conceptsFound},
    );
  }

  Future<void> notifyQuestionGenerationProgress({required int current, required int total}) async {
    if (current % 5 == 0 || current == total) {
      await showNotification(
        title: '📝 Generating Questions',
        body: 'Progress: $current/$total questions generated',
        additionalData: {'action': 'question_generation_progress', 'current': current, 'total': total},
      );
    }
  }

  Future<void> notifyQuestionGenerationComplete({required int totalQuestions}) async {
    await showNotification(
      title: '🎉 Questions Ready',
      body: '$totalQuestions questions generated successfully',
      additionalData: {'action': 'question_generation_complete', 'total': totalQuestions},
    );
  }

  Future<void> notifyGradingProgress({required String studentName, required int current, required int total}) async {
    await showNotification(
      title: '⚡ Grading in Progress',
      body: '$studentName: $current/$total answers graded',
      additionalData: {'action': 'grading_progress', 'student': studentName, 'current': current, 'total': total},
    );
  }

  Future<void> notifyGradingComplete({required String studentName, required int score, required int maxScore}) async {
    await showNotification(
      title: '✨ Grading Complete',
      body: '$studentName scored $score/$maxScore',
      additionalData: {'action': 'grading_complete', 'student': studentName, 'score': score, 'maxScore': maxScore},
    );
  }

  Future<void> notifyAllGradingComplete({required int studentsGraded}) async {
    await showNotification(
      title: '🏆 All Grading Complete',
      body: 'Results ready for $studentsGraded students',
      additionalData: {'action': 'all_grading_complete', 'students': studentsGraded},
    );
  }

  Future<void> notifyError({required String title, required String message}) async {
    await showNotification(title: '⚠️ $title', body: message, additionalData: {'action': 'error'});
  }

  // User management
  Future<void> setExternalUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      if (kDebugMode) {
        print('External user ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Set external user ID error: $e');
      }
    }
  }

  Future<void> removeExternalUserId() async {
    try {
      await OneSignal.logout();
      if (kDebugMode) {
        print('External user ID removed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Remove external user ID error: $e');
      }
    }
  }

  // Tags for user segmentation
  Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      if (kDebugMode) {
        print('User tags set: $tags');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Set tags error: $e');
      }
    }
  }

  Future<void> removeUserTag(String key) async {
    try {
      OneSignal.User.removeTag(key);
      if (kDebugMode) {
        print('Tag removed: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Remove tag error: $e');
      }
    }
  }

  // Subscription management
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      if (enabled) {
        await OneSignal.Notifications.requestPermission(true);
      }
      // Note: OneSignal doesn't have a direct "disable" method
      // Users must disable notifications through device settings
      if (kDebugMode) {
        print('Notifications enabled: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Set notifications enabled error: $e');
      }
    }
  }

  Future<bool> getNotificationPermissionStatus() async {
    try {
      final permission = await OneSignal.Notifications.permission;
      return permission;
    } catch (e) {
      if (kDebugMode) {
        print('Get permission status error: $e');
      }
      return false;
    }
  }

  // In-App Messaging (optional)
  Future<void> addInAppMessageTrigger(String key, String value) async {
    try {
      OneSignal.InAppMessages.addTrigger(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('Add trigger error: $e');
      }
    }
  }

  void pauseInAppMessages(bool pause) {
    OneSignal.InAppMessages.paused(pause);
  }
}
