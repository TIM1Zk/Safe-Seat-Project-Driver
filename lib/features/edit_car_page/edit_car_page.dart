import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_project/core/theme/app_theme.dart';
import 'package:mobile_project/features/profile_page/profile_page.dart';
import 'package:mobile_project/features/edit_car_page/controllers/edit_car_controller.dart';

class EditCarPage extends StatefulWidget {
  final String username;
  final String phoneno;
  const EditCarPage({super.key, required this.username, required this.phoneno});

  @override
  State<EditCarPage> createState() => _EditCarPageState();
}

class _EditCarPageState extends State<EditCarPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  String? _selectedFrontPath;
  String? _selectedSidePath;
  String? _fetchedFrontUrl;
  String? _fetchedSideUrl;

  late EditCarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditCarController(username: widget.username);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (_controller.driverCar != null && _brandController.text.isEmpty) {
      _brandController.text = _controller.driverCar!.carBrand;
      _modelController.text = _controller.driverCar!.carModel;
      _colorController.text = _controller.driverCar!.carColor;
      _plateController.text = _controller.driverCar!.carPlate;

      // Parse current images
      _fetchedFrontUrl = _controller.driverCar!.frontImagePath;
      _fetchedSideUrl = _controller.driverCar!.sideImagePath;
    }

    if (_controller.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AppTheme.error,
        ),
      );
      _controller.errorMessage = null;
    }
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _selectedFrontPath = pickedFile.path;
        } else {
          _selectedSidePath = pickedFile.path;
        }
      });
    }
  }

  void _showImageSourceDialog(bool isFront) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF2340A7)),
                  title: const Text("ถ่ายภาพจากกล้อง"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isFront);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF2340A7)),
                  title: const Text("เลือกจากแกลเลอรี"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isFront);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateCar() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.updateCarDetails(
      carBrand: _brandController.text.trim(),
      carModel: _modelController.text.trim(),
      carColor: _colorController.text.trim(),
      carPlate: _plateController.text.trim(),
      frontImagePath: _selectedFrontPath,
      sideImagePath: _selectedSidePath,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("บันทึกข้อมูลรถยนต์เรียบร้อยแล้ว!"),
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
            phoneno: widget.phoneno,
          ),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? "แก้ไขข้อมูลรถยนต์ไม่สำเร็จ"),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              if (_controller.isLoading && _brandController.text.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Custom Top App Bar ---
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
                            "แก้ไขข้อมูลยานพาหนะ",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Container 1: ข้อมูลทั่วไปของรถยนต์
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
                                Icon(Icons.directions_car_rounded, size: 20, color: AppTheme.primaryBrand),
                                SizedBox(width: 8),
                                Text(
                                  "ข้อมูลทั่วไปของรถยนต์",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // --- ยี่ห้อยานพาหนะคืออะไร? ---
                            _buildFormLabel("ยี่ห้อยานพาหนะ"),
                            _buildTextField(
                              controller: _brandController,
                              hintText: "ตัวอย่าง Toyota, Honda",
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9ก-๙\s\-]'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "กรุณากรอกยี่ห้อยานพาหนะ";
                                }
                                if (!RegExp(r'^[a-zA-Z0-9ก-๙\s\-]+$').hasMatch(value.trim())) {
                                  return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                                }
                                if (value.trim().length < 2 || value.trim().length > 50) {
                                  return "ต้องมีความยาวตั้งแต่ 2 - 50 ตัวอักษร";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // --- รุ่นรถของคุณคืออะไร? ---
                            _buildFormLabel("รุ่นรถของคุณ"),
                            _buildTextField(
                              controller: _modelController,
                              hintText: "ตัวอย่าง Civic, Camry, Yaris",
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9ก-๙\s\-]'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "กรุณากรอกรุ่นรถยนต์";
                                }
                                if (!RegExp(r'^[a-zA-Z0-9ก-๙\s\-]+$').hasMatch(value.trim())) {
                                  return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                                }
                                if (value.trim().length < 1 || value.trim().length > 50) {
                                  return "ต้องมีความยาวตั้งแต่ 1 - 50 ตัวอักษร";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // --- สีรถยนต์ & ทะเบียนรถยนต์ side-by-side ---
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFormLabel("สีของรถ"),
                                      _buildTextField(
                                        controller: _colorController,
                                        hintText: "ตัวอย่าง สีดำ, สีขาว",
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Zก-๙\s]'),
                                          ),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return "กรุณากรอกสีรถยนต์";
                                          }
                                          if (!RegExp(r'^[a-zA-Zก-๙\s]+$').hasMatch(value.trim())) {
                                            return "ต้องเป็นภาษาไทยหรืออังกฤษ";
                                          }
                                          if (value.trim().length < 2 || value.trim().length > 20) {
                                            return "ความยาว 2 - 20 ตัวอักษร";
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFormLabel("ป้ายทะเบียนรถ"),
                                      _buildTextField(
                                        controller: _plateController,
                                        hintText: "เช่น กข-1234",
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z0-9ก-๙\-]'),
                                          ),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return "กรุณากรอกทะเบียน";
                                          }
                                          if (!RegExp(r'^[a-zA-Z0-9ก-๙\-]+$').hasMatch(value.trim())) {
                                            return "รูปแบบไม่ถูกต้อง";
                                          }
                                          if (value.trim().length < 2 || value.trim().length > 10) {
                                            return "ความยาว 2 - 10 ตัวอักษร";
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Container 2: อัพโหลดรูปภาพยานพาหนะ
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
                                Icon(Icons.add_a_photo_rounded, size: 20, color: AppTheme.primaryBrand),
                                SizedBox(width: 8),
                                Text(
                                  "รูปภาพยานพาหนะ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showImageSourceDialog(true),
                                    child: CustomPaint(
                                      painter: DottedBorderPainter(color: const Color(0xFFCBD5E1), strokeWidth: 1.5, gap: 4),
                                      child: Container(
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: _buildImagePreview(_selectedFrontPath, _fetchedFrontUrl, "รูปด้านหน้ารถ"),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showImageSourceDialog(false),
                                    child: CustomPaint(
                                      painter: DottedBorderPainter(color: const Color(0xFFCBD5E1), strokeWidth: 1.5, gap: 4),
                                      child: Container(
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: _buildImagePreview(_selectedSidePath, _fetchedSideUrl, "รูปด้านข้างรถ"),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- Save Vehicle Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _controller.isLoading ? null : _updateCar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2340A7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _controller.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.save_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "บันทึกข้อมูลรถยนต์",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        filled: true,
        fillColor: const Color(0xFFE2E2E2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String? localPath, String? networkUrl, String label) {
    if (localPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(localPath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          networkUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildUploadPlaceholder(label),
        ),
      );
    } else {
      return _buildUploadPlaceholder(label);
    }
  }

  Widget _buildUploadPlaceholder(String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          size: 44,
          color: Colors.black87,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(15),
    );
    path.addRRect(rrect);

    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
