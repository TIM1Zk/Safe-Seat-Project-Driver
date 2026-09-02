import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_project/core/theme/app_theme.dart';
import 'package:mobile_project/features/profile_page/profile_page.dart';
import 'package:mobile_project/features/edit_profile_page/controllers/edit_profile_controller.dart';
import 'package:mobile_project/features/edit_car_page/edit_car_page.dart';
import 'package:mobile_project/core/utils/session_manager.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  final String phoneno;
  const EditProfilePage({super.key, required this.username, required this.phoneno});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _phoneNo = "";

  late EditProfileController _controller;

  @override
  void initState() {
    super.initState();
    _phoneNo = widget.phoneno;
    _controller = EditProfileController(phone: widget.username);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    final profile = _controller.userProfile;
    if (profile != null) {
      if (_nameController.text.isEmpty) {
        _nameController.text = "${profile.firstName} ${profile.lastName}".trim();
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = profile.email;
      }
      if (_phoneNo.isEmpty) {
        _phoneNo = profile.phoneNo;
      }
    }
    
    if (_controller.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _controller.errorMessage = null; 
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    String firstName = fullName;
    String lastName = "";
    final parts = fullName.split(' ');
    if (parts.length > 1) {
      firstName = parts.first;
      lastName = parts.sublist(1).join(' ');
    }

    final email = _emailController.text.trim();

    final success = await _controller.updateProfile(
      phoneNo: _phoneNo,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );

    if (success && mounted) {
      await SessionManager.saveSession(widget.username, _phoneNo);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("บันทึกข้อมูลเรียบร้อยแล้ว!"),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            username: widget.username,
            phoneno: _phoneNo,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.isLoading && _nameController.text.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand));
            }

            final profile = _controller.userProfile;
            final carBrand = profile?.carBrand ?? "";
            final carModel = profile?.carModel ?? "";
            final carPlate = profile?.carPlate ?? "";
            final carBrandModel = "$carBrand $carModel".trim();

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Bar
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: AppTheme.textPrimary,
                                size: 18,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "แก้ไขข้อมูลบัญชี",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 1: ข้อมูลส่วนตัว (Personal Info Card)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.primaryBrand),
                                SizedBox(width: 8),
                                Text(
                                  "ข้อมูลส่วนตัว",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // ชื่อ - นามสกุล (Read-only)
                            const Text(
                              "ชื่อ - นามสกุล (อิงตามบัตรประชาชน)",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _nameController.text.isNotEmpty ? _nameController.text : "กำลังโหลด...",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // หมายเลขโทรศัพท์มือถือ (Read-only)
                            const Text(
                              "หมายเลขโทรศัพท์มือถือ",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _phoneNo.isNotEmpty ? _phoneNo : widget.phoneno,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ที่อยู่อีเมล (Editable)
                            const Text(
                              "ที่อยู่อีเมล",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: "เช่น yourname@gmail.com",
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryBrand, width: 1.8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.error),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.error, width: 1.8),
                                ),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B), size: 20),
                              ),
                              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              validator: (value) {
                                final email = value?.trim() ?? "";
                                if (email.isEmpty) {
                                  return "กรุณากรอกที่อยู่อีเมล";
                                }
                                final RegExp emailRegExp = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com)$',
                                  caseSensitive: false,
                                );
                                if (!emailRegExp.hasMatch(email)) {
                                  return "อีเมลต้องอยู่ในรูปแบบ @gmail.com หรือ @hotmail.com เท่านั้น";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: ข้อมูลของยานพาหนะ (Vehicle Info Card)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.directions_car_filled_rounded, size: 20, color: AppTheme.primaryBrand),
                                    SizedBox(width: 8),
                                    Text(
                                      "ข้อมูลยานพาหนะที่ลงทะเบียน",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditCarPage(
                                      username: widget.username,
                                      phoneno: widget.phoneno,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2340A7).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.drive_eta_rounded,
                                        color: Color(0xFF2340A7),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            carPlate.isNotEmpty ? carPlate : "ยังไม่มีข้อมูลทะเบียนรถ",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            carBrandModel.isNotEmpty ? carBrandModel : "กดเพื่อเพิ่มหรือแก้ไขข้อมูลรถยนต์",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditCarPage(
                                        username: widget.username,
                                        phoneno: widget.phoneno,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF2563EB)),
                                label: const Text(
                                  "แก้ไข / เปลี่ยนข้อมูลรถ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // บันทึกข้อมูล Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _controller.isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2340A7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: const Color(0xFF2340A7).withOpacity(0.3),
                          ),
                          child: _controller.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  "บันทึกการเปลี่ยนแปลง",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
