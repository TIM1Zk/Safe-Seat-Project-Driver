import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mobile_project/features/profile_page/profile_page.dart';
import 'package:mobile_project/core/utils/session_manager.dart';
import 'package:mobile_project/features/map_page/map_page.dart';
import 'data/services/auth_service.dart';

import 'package:geolocator/geolocator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController usernamecontroller;
  late final TextEditingController passwordcontroller;
  bool isloading = false;

  @override
  void initState() {
    super.initState();
    usernamecontroller = TextEditingController();
    passwordcontroller = TextEditingController();
  }

  @override
  void dispose() {
    usernamecontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isloading = true);

    try {
      double? lat;
      double? lng;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (e) {
        debugPrint("Could not get location: $e");
      }

      final data = await _authService.login(
        usernamecontroller.text.trim(),
        passwordcontroller.text.trim(),
        lat,
        lng,
      );

      if (data != null) {
        // Save session locally for auto-login
        await SessionManager.saveSession(data.username, data.phoneno);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MapPage(),
            ),
          );
        }
      } else {
        throw 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isloading = false);
    }
  }

  String? _validatePhoneNo(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกหมายเลขโทรศัพท์';
    }
    if (value.contains(RegExp(r'\s'))) {
      return 'ต้องไม่มีเว้นวรรค หรือช่องว่าง';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'ต้องเป็นตัวเลขเท่านั้น';
    }
    if (value.length != 10) {
      return 'ต้องมีความยาว 10 ตัวอักษร';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.contains(RegExp(r'\s'))) {
      return 'ต้องไม่มีเว้นวรรค หรือช่องว่าง';
    }
    if (value.length < 8 || value.length > 30) {
      return 'ต้องมีความยาวตั้งแต่ 8 - 30 ตัวอักษร';
    }
    if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(value)) {
      return 'ต้องเป็นอักษรอังกฤษ ตัวเลข และอักขระพิเศษ [!#_.] เท่านั้น';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[!#_.]').hasMatch(value);
    if (!hasLetter || !hasDigit || !hasSpecial) {
      return 'ต้องเป็นอักษรอังกฤษตัวเลข รวมอักขระพิเศษ[!#_.]';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF7CE5FF); // Frosted Blue

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Gradient & Decorative Orbs (Light Theme matching other pages)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA),
                  Colors.white,
                  Color(0xFFF1F3F5),
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
                color: accentColor.withOpacity(0.15),
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
                color: accentColor.withOpacity(0.08),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Header ---
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.drive_eta_rounded,
                              size: 70,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "Safe Seat Driver",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "พรีเมียมแพลตฟอร์มสำหรับคนขับมืออาชีพ",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),

                    // --- Glassmorphic Form ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.08),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                _buildGlassField(
                                  controller: usernamecontroller,
                                  label: "หมายเลขโทรศัพท์มือถือ (phoneNo)",
                                  icon: Icons.phone_android_rounded,
                                  accentColor: accentColor,
                                  keyboardType: TextInputType.phone,
                                  validator: _validatePhoneNo,
                                ),
                                const SizedBox(height: 20),
                                _buildGlassField(
                                  controller: passwordcontroller,
                                  label: "รหัสผ่าน (Password)",
                                  icon: Icons.lock_outline_rounded,
                                  accentColor: accentColor,
                                  obscureText: true,
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 40),

                                // Login Button with Glowing Effect
                                Container(
                                  width: double.infinity,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isloading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: isloading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
                                            "เข้าสู่ระบบ",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Footer ---
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "ยังไม่เป็นสมาชิก? สมัครขับตอนนี้",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54, size: 22),
            filled: true,
            fillColor: Colors.black.withOpacity(0.03),
            contentPadding: const EdgeInsets.all(18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1.5,
              ),
            ),
          ),
          validator: validator ?? ((value) => value!.isEmpty ? "กรุณากรอกข้อมูล" : null),
        ),
      ],
    );
  }
}
