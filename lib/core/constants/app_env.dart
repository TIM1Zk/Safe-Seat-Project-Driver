import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Environment Configuration Manager
/// อ่านค่าตัวแปรสภาพแวดล้อมจากไฟล์ .env
class AppEnv {
  /// Supabase Project URL
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase Anon / Publishable Key
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Backend REST API Base URL (Default for Android Emulator: 10.0.2.2:3000)
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  /// Supabase Public Storage Base URL สำหรับรูปภาพ
  static String get supabaseStorageUrl =>
      '$supabaseUrl/storage/v1/object/public/images';
}
