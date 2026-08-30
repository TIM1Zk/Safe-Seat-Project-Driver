import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mobile_project/core/utils/session_manager.dart';
import 'package:mobile_project/features/map_page/map_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // แสดงหน้าจอโหลดเดอร์อย่างน้อย 3 วินาทีเพื่อให้ดูพรีเมียม
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // ตรวจสอบว่าเคยเข้าสู่ระบบไว้หรือไม่
    final isLoggedIn = await SessionManager.isLoggedIn();
    if (isLoggedIn) {
      final username = await SessionManager.getUsername();
      final phoneno = await SessionManager.getPhoneNo();
      
      if (mounted && username != null && phoneno != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MapPage(),
          ),
        );
        return;
      }
    }

    // หากยังไม่เคยเข้าสู่ระบบ ให้นำไปหน้า Login
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF2340A7); // Primary Brand Blue #2340A7

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Gradient & Decorative Orbs (Light Theme)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Colors.white,
                  Color(0xFFF1F5F9),
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2340A7).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.08),
              ),
            ),
          ),

          // 2. Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon (Driver Themed)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2340A7).withOpacity(0.12),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.drive_eta_rounded,
                    size: 80,
                    color: Color(0xFF2340A7),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Safe Seat Driver",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "ระบบผู้ช่วยคู่หูคนขับอัจฉริยะ",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 60),

                // Sleek, modern glowing progress indicator
                Container(
                  width: 45,
                  height: 45,
                  padding: const EdgeInsets.all(4),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2340A7)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
