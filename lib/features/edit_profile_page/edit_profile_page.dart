import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
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

  void _showEditPhoneDialog() {
    final phoneController = TextEditingController(text: _phoneNo);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("แก้ไขหมายเลขโทรศัพท์"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                hintText: "กรอกหมายเลขโทรศัพท์มือถือ (10 หลัก)",
                counterText: "",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "กรุณากรอกหมายเลขโทรศัพท์";
                }
                if (value.contains(RegExp(r'\s'))) {
                  return "ต้องไม่มีเว้นวรรค หรือช่องว่าง";
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return "ต้องเป็นตัวเลขเท่านั้น";
                }
                if (value.length != 10) {
                  return "หมายเลขโทรศัพท์ต้องมีความยาว 10 ตัวอักษร";
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _phoneNo = phoneController.text.trim();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("ตกลง"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading && _nameController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final profile = _controller.userProfile;
          final carBrand = profile?.carBrand ?? "";
          final carModel = profile?.carModel ?? "";
          final carPlate = profile?.carPlate ?? "";
          final carBrandModel = "$carBrand $carModel".trim();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "แก้ไขข้อมูลบัญชี",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    const SizedBox(height: 24),

                    // ข้อมูลส่วนตัว
                    const Text(
                      "ข้อมูลส่วนตัว",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // ชื่อ
                    const Text(
                      "ชื่อ",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    TextFormField(
                      controller: _nameController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                      style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),

                    // หมายเลขโทรศัพท์มือถือ (แก้ไขไม่ได้)
                    const Text(
                      "หมายเลขโทรศัพท์มือถือ",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _phoneNo,
                        style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey, thickness: 1.0),
                    const SizedBox(height: 24),

                    // ที่อยู่อีเมล
                    const Text(
                      "ที่อยู่อีเมล",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 1.5),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
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
                          return "อีเมลต้องอยู่ในรูปแบบ user@gmail.com หรือ user@hotmail.com เท่านั้น";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // ข้อมูลของยานพาหนะ
                    const Text(
                      "ข้อมูลของยานพาหนะ",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  carPlate.isNotEmpty ? carPlate : "รวย 1234",
                                  style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  carBrandModel.isNotEmpty ? carBrandModel : "Lamborghini urus",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.black, thickness: 1.5),
                    const SizedBox(height: 12),
                    GestureDetector(
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
                      child: const Text(
                        "แก้ไข / เพิ่มยานพาหนะ",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // บันทึกข้อมูล Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _controller.isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: _controller.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Text(
                                "บันทึกข้อมูล",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
