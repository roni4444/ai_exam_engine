import 'package:flutter_dotenv/flutter_dotenv.dart';

class OneSignalConfig {
  static String get appId => dotenv.env['ONESIGNAL_APP_ID'] ?? '';
  static String get restApiKey => dotenv.env['ONESIGNAL_REST_API_KEY'] ?? '';
}
