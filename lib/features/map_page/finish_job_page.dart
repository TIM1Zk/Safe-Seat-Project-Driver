import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mobile_project/features/map_page/report_user_page.dart';

class FinishJobPage extends StatefulWidget {
  final dynamic requestId;
  final int? buddyTeamId;
  final bool isPubJob;
  final String? distance;
  final String? fare;

  const FinishJobPage({
    super.key,
    required this.requestId,
    required this.buddyTeamId,
    required this.isPubJob,
    this.distance,
    this.fare,
  });

  @override
  State<FinishJobPage> createState() => _FinishJobPageState();
}

class _FinishJobPageState extends State<FinishJobPage> {
  File? _selectedImage;
  bool _isCompleting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถเปิดกล้องได้: $e")),
      );
    }
  }

  Future<void> _completeJob() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาอัปโหลดรูปภาพหลักฐานการจอดรถก่อนเสร็จสิ้นงาน"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      // Prepare multipart form data
      final Map<String, dynamic> dataMap = {
        'request_id': widget.requestId.toString(),
        'buddy_team_id': widget.buddyTeamId?.toString() ?? '',
        'is_pub_job': widget.isPubJob.toString(),
      };

      if (_selectedImage != null) {
        dataMap['evidenceImage'] = await dio.MultipartFile.fromFile(
          _selectedImage!.path,
          filename: 'evidence_${widget.requestId}.jpg',
        );
      }

      final formData = dio.FormData.fromMap(dataMap);

      final response = await ApiService.post('/buddy-team/complete-job', data: formData);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ส่งงานและบันทึกหลักฐานเรียบร้อยแล้ว!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true indicating success
        }
      } else {
        throw Exception(response.data?['message'] ?? "เกิดข้อผิดพลาดในการส่งงาน");
      }
    } catch (e) {
      debugPrint("Error completing job: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ส่งงานล้มเหลว: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  void _showReportDialog() {
    if (widget.isPubJob) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ไม่สามารถรายงานลูกค้าเนื่องจากเป็นคำขอจากสถานบันเทิง (Pub)"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportUserPage(requestId: widget.requestId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Distance styling
    final distanceText = widget.distance ?? "0.0 km";
    
    // Estimate duration: ~1.5 mins per km, minimum 5 mins
    double distVal = 0.0;
    try {
      distVal = double.parse(distanceText.replaceAll(RegExp(r'[^0-9.]'), ''));
    } catch (_) {}
    final int estimatedMinutes = distVal > 0 ? (distVal * 1.5).round() : 15;
    final durationText = "$estimatedMinutes mins";

    final fareText = widget.fare ?? "0.00 บาท";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          "Finish Job",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.black12,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Request Evidence Section Header
              const Text(
                "Request Evidence",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please take a clear photo of the parked vehicle at the destination",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Upload Box
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black12,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
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
                              Icons.cloud_upload_outlined,
                              size: 64,
                              color: Colors.black87,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Upload",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 36),

              // 3. Ride Summary Section Header
              const Text(
                "Ride Summary",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.black12,
                height: 1.0,
                width: double.infinity,
              ),
              const SizedBox(height: 20),

              // 4. Ride Summary Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Row 1: Distance
                    Row(
                      children: [
                        const Icon(Icons.directions_car, color: Colors.black, size: 24),
                        const SizedBox(width: 16),
                        const Text(
                          "Distance",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.black12, height: 1),
                    ),
                    // Row 2: Duration
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: Colors.black, size: 24),
                        const SizedBox(width: 16),
                        const Text(
                          "Duration",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          durationText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.black12, height: 1),
                    ),
                    // Row 3: Total Fare
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.black, size: 24),
                        const SizedBox(width: 16),
                        const Text(
                          "Total Fare",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          fareText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // 5. Complete Job Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCompleting ? null : _completeJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E), // Green color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isCompleting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Complete Job",
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
              const SizedBox(height: 16),
              // 6. Report User Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _showReportDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.report_problem, color: Colors.redAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "รายงานผู้ใช้งาน (Report User)",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
