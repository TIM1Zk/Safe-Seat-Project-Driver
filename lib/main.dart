import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_project/features/login_page/login_page.dart';
import 'package:mobile_project/features/loading_screen/loading_screen.dart';
import 'package:mobile_project/core/network/api_service.dart';

// ฟังก์ชัน main ตัวนอกสุดต้องเป็น async
Future<void> main() async {
  // 1. ต้องมีบรรทัดนี้เพื่อให้เรียกใช้ Plugin ต่างๆ ได้ถูกต้อง
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: 'https://qbionbozkvlekpakvstg.supabase.co',
    anonKey: 'sb_publishable_PoMKHC0nz4vb9OmOxZsbkw_aU_K2xts',
  );

  // 3. Initialize API Service configuration
  ApiService.init(baseUrl: 'http://10.0.2.2:3000/api');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safe Seat Project',
      theme: ThemeData(
        fontFamily: 'Kanit',
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2340A7), // Primary Brand #2340A7
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // App Background #F8FAFC
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2340A7),
          primary: const Color(0xFF2340A7),
          secondary: const Color(0xFF2563EB), // Accent Blue #2563EB
          surface: Colors.white,
          error: const Color(0xFFDC2626), // Error Red #DC2626
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2340A7),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2340A7),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const LoadingScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/loading': (context) => const LoadingScreen(),
      },
    );
  }
}
