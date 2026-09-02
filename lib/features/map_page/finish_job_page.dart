import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mobile_project/features/map_page/report_user_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FinishJobPage extends StatefulWidget {
  final dynamic requestId;
  final int? buddyTeamId;
  final bool isPubJob;
  final String? distance;
  final String? fare;
  final String? paymentMethod;

  const FinishJobPage({
    super.key,
    required this.requestId,
    required this.buddyTeamId,
    required this.isPubJob,
    this.distance,
    this.fare,
    this.paymentMethod,
  });

  @override
  State<FinishJobPage> createState() => _FinishJobPageState();
}

class _FinishJobPageState extends State<FinishJobPage> {
  File? _selectedImage;
  bool _isCompleting = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isCashPayment {
    // หากเป็นงานจากสถานบันเทิง (Pub) ไม่ต้องแสดง QR Code เรียกเก็บเงิน
    if (widget.isPubJob) {
      return false;
    }
    final method = widget.paymentMethod?.toLowerCase() ?? '';
    if (method.contains('wallet')) {
      return false;
    }
    return true; // Default is Cash
  }

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

  void _showQrDialog(BuildContext context, String fareText, double numFare) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header PromptPay / Grab style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003D6B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "PromptPay",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "สแกนเพื่อจ่าย",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: "SAFESEAT_PAY_${widget.requestId}_${numFare.toStringAsFixed(2)}",
                        version: QrVersions.auto,
                        size: 200.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF003D6B),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Order #${widget.requestId}",
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "ยอดชำระเงินทั้งหมด",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fareText,
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ให้ลูกค้ายกกล้องหรือแอปธนาคารสแกน QR Code นี้เพื่อโอนชำระเงินสดทันที",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2340A7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "ปิดหน้านี้",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    double numFare = 0.0;
    try {
      numFare = double.parse(fareText.replaceAll(RegExp(r'[^0-9.]'), ''));
    } catch (_) {}

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
              // --- QR CODE PAYMENT SECTION (For Cash / PromptPay, like Grab) ---
              if (_isCashPayment) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "ชำระเงินสด / QR Code",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "ให้ลูกค้าสแกนเพื่อชำระเงิน (PromptPay)",
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF22C55E)),
                            ),
                            child: const Text(
                              "เงินสด",
                              style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // White QR Box
                      GestureDetector(
                        onTap: () => _showQrDialog(context, fareText, numFare),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Promptpay Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF003D6B),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "PromptPay",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "พร้อมเพย์",
                                    style: TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              QrImageView(
                                data: "SAFESEAT_PAY_${widget.requestId}_${numFare.toStringAsFixed(2)}",
                                version: QrVersions.auto,
                                size: 160.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF003D6B),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.fullscreen, size: 16, color: Color(0xFF64748B)),
                                  SizedBox(width: 4),
                                  Text(
                                    "แตะเพื่อขยาย QR Code",
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Amount to Collect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "ยอดที่ต้องเรียกเก็บจากลูกค้า",
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            fareText,
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

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
                    // Row 3: Payment Method
                    Row(
                      children: [
                        Icon(
                          _isCashPayment ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Payment Method",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.paymentMethod ?? (_isCashPayment ? "เงินสด (Cash)" : "App Wallet"),
                          style: const TextStyle(
                            fontSize: 16,
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
                    // Row 4: Total Fare
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
                            color: Color(0xFF059669),
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
