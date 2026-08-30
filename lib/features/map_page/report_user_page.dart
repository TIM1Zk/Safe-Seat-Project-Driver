import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:dio/dio.dart' as dio;

class ReportUserPage extends StatefulWidget {
  final dynamic requestId;

  const ReportUserPage({
    super.key,
    required this.requestId,
  });

  @override
  State<ReportUserPage> createState() => _ReportUserPageState();
}

class _ReportUserPageState extends State<ReportUserPage> {
  String _selectedReason = "Behavior";
  final TextEditingController _detailController = TextEditingController();
  File? _evidenceImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _evidenceImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ไม่สามารถเปิดกล้องได้: $e")),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    final detailText = _detailController.text.trim();

    // 0. Validate Report Reason - Selected
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาเลือกหัวข้อปัญหาที่พบ"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 1. Validate Report Detail - Not empty and minimum length (at least 5 characters)
    if (detailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณากรอกรายละเอียดเหตุการณ์"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (detailText.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณากรอกรายละเอียดเหตุการณ์อย่างน้อย 5 ตัวอักษร"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. Validate Report Detail - Length (1 - 200 chars)
    if (detailText.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("รายละเอียดเหตุการณ์ต้องมีความยาวไม่เกิน 200 ตัวอักษร"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 3. Validate Report Detail - Block dangerous special characters but allow Thai, English, Numbers & spaces
    final dangerousCharsRegex = RegExp(r'[<>{}\\|`~\$\^]');
    if (dangerousCharsRegex.hasMatch(detailText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("รายละเอียดต้องเป็นตัวอักษรภาษาไทยและอังกฤษเท่านั้น (ห้ามใช้อักขระพิเศษ)"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 4. Validate Report Picture - Not empty
    if (_evidenceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาแนบรูปภาพประกอบการรายงาน"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 5. Validate Report Picture - File extension (JPG, PNG)
    final path = _evidenceImage!.path.toLowerCase();
    if (!path.endsWith('.jpg') && !path.endsWith('.jpeg') && !path.endsWith('.png')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("นามสกุลไฟล์รูปภาพต้องเป็น JPG หรือ PNG เท่านั้น"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 6. Validate Report Picture - File size (Max 10 MB)
    final fileSizeInBytes = await _evidenceImage!.length();
    if (fileSizeInBytes > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ขนาดไฟล์รูปภาพต้องไม่เกิน 10 MB"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Map reason to TH database expectation if needed, or keep it English matching UI
      // In the backend, we write whatever reporttype is sent.
      final Map<String, dynamic> dataMap = {
        'reporttype': _selectedReason,
        'reportdetail': _detailController.text.trim(),
        'request_id': widget.requestId.toString(),
      };

      if (_evidenceImage != null) {
        dataMap['reportImage'] = await dio.MultipartFile.fromFile(
          _evidenceImage!.path,
          filename: 'report_${widget.requestId}.jpg',
        );
      }

      final formData = dio.FormData.fromMap(dataMap);
      final response = await ApiService.post('/user-reports', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ส่งรายงานพฤติกรรมเรียบร้อยแล้ว"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true indicating success
        }
      } else {
        throw Exception(response.data?['message'] ?? "เกิดข้อผิดพลาดในการส่งรายงาน");
      }
    } catch (e) {
      debugPrint("Error submitting report: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ส่งรายงานล้มเหลว: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Report Incident Title
              Center(
                child: Column(
                  children: [
                    const Text(
                      "รายงานปัญหาเกี่ยวกับผู้ใช้",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 2,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. What happened? Section
              const Text(
                "เกิดอะไรขึ้น?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Options
              _buildReasonOption("Behavior", "พฤติกรรมไม่เหมาะสม", Icons.report_problem_outlined),
              const SizedBox(height: 12),
              _buildReasonOption("Wrong Location", "หมุดสถานที่ผิดพลาด", Icons.cancel_outlined),
              const SizedBox(height: 12),
              _buildReasonOption("Safety issue", "ความปลอดภัยขณะปฏิบัติงาน", Icons.shield_outlined),
              const SizedBox(height: 28),

              // 3. Tell us more Section
              const Text(
                "ระบุรายละเอียดเพิ่มเติม",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "การระบุข้อมูลโดยละเอียดจะช่วยให้ทีมงานตรวจสอบได้รวดเร็วยิ่งขึ้น",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _detailController,
                  maxLines: 5,
                  maxLength: 200,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: "อธิบายรายละเอียดของเหตุการณ์...",
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 4. Add evidence Section
              const Text(
                "แนบหลักฐานการแจ้งเรื่อง",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: CustomPaint(
                  painter: DashedBorderPainter(color: Colors.black26),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _evidenceImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _evidenceImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _evidenceImage = null;
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 36,
                                color: Colors.black54,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "ถ่ายภาพ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 5. Submit Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "ส่งรายงาน",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
      ),
    );
  }

  Widget _buildReasonOption(String key, String displayText, IconData icon) {
    final bool isSelected = _selectedReason == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = key;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2340A7).withOpacity(0.08) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF2340A7) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2340A7) : const Color(0xFF1E293B),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF007AFF) : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF007AFF),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw dashed border around evidence upload container
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    // Rounded rectangle path
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    ));

    // Calculate dashed effect manually
    for (double i = 0; i < 4; i++) {
      // Draw dashes along border
    }
    
    // Simple custom dash pattern drawer using path segments
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
