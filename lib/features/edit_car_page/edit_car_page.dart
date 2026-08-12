import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
          backgroundColor: Colors.redAccent,
        ),
      );
      _controller.errorMessage = null;
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black),
                title: const Text('เลือกจากคลังภาพ (Gallery)'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (image != null) {
                    setState(() {
                      if (isFront) {
                        _selectedFrontPath = image.path;
                      } else {
                        _selectedSidePath = image.path;
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.black),
                title: const Text('ถ่ายภาพใหม่ (Camera)'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (image != null) {
                    setState(() {
                      if (isFront) {
                        _selectedFrontPath = image.path;
                      } else {
                        _selectedSidePath = image.path;
                      }
                    });
                  }
                },
              ),
            ],
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
          backgroundColor: const Color(0xFF2ECD65),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.isLoading && _brandController.text.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          "แก้ไขยานพาหนะ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44), // alignment helper
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.black.withOpacity(0.01)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- รายละเอียดยานพาหนะ ---
                    const Text(
                      "รายละเอียดยานพาหนะ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- ยี่ห้อยานพาหนะคืออะไร? ---
                    _buildFormLabel("ยี่ห้อยานพาหนะคืออะไร?"),
                    _buildTextField(
                      controller: _brandController,
                      hintText: "ตัวอย่าง Toyota",
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z\u0E00-\u0E7F]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณากรอกยี่ห้อยานพาหนะ";
                        }
                        if (value.contains(' ')) {
                          return "ต้องไม่เว้นวรรค หรือช่องว่าง";
                        }
                        if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F]+$').hasMatch(value)) {
                          return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                        }
                        if (value.length < 3 || value.length > 50) {
                          return "ต้องมีความยาวตั้งแต่ 3 - 50 ตัวอักษร";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- รุ่นรถของคุณคืออะไร? ---
                    _buildFormLabel("รุ่นรถของคุณคืออะไร?"),
                    _buildTextField(
                      controller: _modelController,
                      hintText: "ตัวอย่าง Supra",
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z\u0E00-\u0E7F]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณากรอกรุ่นรถยนต์";
                        }
                        if (value.contains(' ')) {
                          return "ต้องไม่เว้นวรรค หรือช่องว่าง";
                        }
                        if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F]+$').hasMatch(value)) {
                          return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                        }
                        if (value.length < 3 || value.length > 50) {
                          return "ต้องมีความยาวตั้งแต่ 3 - 50 ตัวอักษร";
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
                              _buildFormLabel("สีรถของคุณ"),
                              _buildTextField(
                                controller: _colorController,
                                hintText: "ตัวอย่าง สีดำ",
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\u0E00-\u0E7F]'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "กรุณากรอกสีรถยนต์";
                                  }
                                  if (value.contains(' ')) {
                                    return "ต้องไม่เว้นวรรค หรือช่องว่าง";
                                  }
                                  if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F]+$').hasMatch(value)) {
                                    return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                                  }
                                  if (value.length < 2 || value.length > 20) {
                                    return "ต้องมีความยาวตั้งแต่ 2 - 20 ตัวอักษร";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel("ป้ายทะเบียนรถ"),
                              _buildTextField(
                                controller: _plateController,
                                hintText: "ตัวอย่าง กข-1234",
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9\u0E00-\u0E7F\-]'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "กรุณากรอกทะเบียนรถยนต์";
                                  }
                                  if (!RegExp(r'^[a-zA-Z0-9\u0E00-\u0E7F\-]+$').hasMatch(value)) {
                                    return "ต้องเป็นภาษาไทย ภาษาอังกฤษ ตัวเลข หรือ (-) เท่านั้น";
                                  }
                                  if (value.length < 2 || value.length > 10) {
                                    return "ต้องมีความยาวตั้งแต่ 2 - 10 ตัวอักษร";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- อัพโหลดรูปภาพยานพาหนะ ---
                    const Text(
                      "อัพโหลดรูปภาพยานพาหนะ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(true),
                            child: CustomPaint(
                              painter: DottedBorderPainter(color: Colors.black, strokeWidth: 1.5, gap: 4),
                              child: Container(
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: _buildImagePreview(_selectedFrontPath, _fetchedFrontUrl, "ด้านหน้า"),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(false),
                            child: CustomPaint(
                              painter: DottedBorderPainter(color: Colors.black, strokeWidth: 1.5, gap: 4),
                              child: Container(
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: _buildImagePreview(_selectedSidePath, _fetchedSideUrl, "ด้านข้าง"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // --- Save Vehicle Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _controller.isLoading ? null : _updateCar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECD65),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                  Icon(Icons.check_circle_outline, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    "Save Vehicle",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
