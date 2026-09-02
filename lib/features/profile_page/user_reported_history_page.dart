import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:mobile_project/core/theme/app_theme.dart';

class UserReportedHistoryPage extends StatefulWidget {
  final String username;

  const UserReportedHistoryPage({super.key, required this.username});

  @override
  State<UserReportedHistoryPage> createState() => _UserReportedHistoryPageState();
}

class _UserReportedHistoryPageState extends State<UserReportedHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  String _selectedFilter = 'ทั้งหมด'; // 'ทั้งหมด', 'กำลังตรวจสอบ', 'ตรวจสอบแล้ว'

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);
      // Fetch user reports submitted in the system
      final response = await ApiService.get('/user-reports');

      if (response.statusCode == 200) {
        setState(() {
          _reports = response.data;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load reports");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดข้อมูลประวัติการรายงานล้มเหลว: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  List<dynamic> _getFilteredReports() {
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

    final recentReports = _reports.where((r) {
      if (r['reportdate'] == null) return true;
      try {
        final rawStr = r['reportdate'].toString();
        final isoStr = (!rawStr.endsWith('Z') && !rawStr.contains('+')) ? '${rawStr}Z' : rawStr;
        final parsedDate = DateTime.parse(isoStr).toLocal();
        return parsedDate.isAfter(oneMonthAgo) || parsedDate.isAtSameMomentAs(oneMonthAgo);
      } catch (e) {
        return true;
      }
    }).toList();

    if (_selectedFilter == 'ทั้งหมด') {
      return recentReports;
    } else if (_selectedFilter == 'กำลังตรวจสอบ') {
      return recentReports.where((r) {
        final status = (r['reportstatus'] ?? '').toString();
        return status == 'กำลังดำเนินการ' || status == 'รอดำเนินการ' || status == 'Pending';
      }).toList();
    } else {
      // ตรวจสอบแล้ว / เสร็จสิ้น
      return recentReports.where((r) {
        final status = (r['reportstatus'] ?? '').toString();
        return status != 'กำลังดำเนินการ' && status != 'รอดำเนินการ' && status != 'Pending';
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
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
                      "ประวัติการส่งรายงาน",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
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
                        child: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary, size: 18),
                      ),
                      onPressed: _loadReports,
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              _buildFilterTabs(),
              const SizedBox(height: 10),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBrand),
                        ),
                      )
                    : filteredReports.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            color: AppTheme.primaryBrand,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = filteredReports[index];
                                return _buildReportCard(report);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['ทั้งหมด', 'กำลังตรวจสอบ', 'ตรวจสอบแล้ว'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedFilter == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = tab;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2340A7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2340A7).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "ไม่มีประวัติการส่งรายงาน ($_selectedFilter)",
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "รายงานที่คุณส่งเข้ามาจะปรากฏในหน้านี้",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final String type = report['reporttype'] ?? 'ทั่วไป';
    final String detail = report['reportdetail'] ?? 'ไม่มีรายละเอียดเพิ่มเติม';
    final String status = report['reportstatus'] ?? 'กำลังดำเนินการ';
    final int requestId = report['request_id'] ?? 0;

    String formattedDate = "ไม่ระบุวันที่";
    if (report['reportdate'] != null) {
      try {
        final rawStr = report['reportdate'].toString();
        final isoStr = (!rawStr.endsWith('Z') && !rawStr.contains('+')) ? '${rawStr}Z' : rawStr;
        final DateTime parsed = DateTime.parse(isoStr).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, HH:mm น.').format(parsed);
      } catch (e) {
        formattedDate = report['reportdate'].toString();
      }
    }

    final bool inProgress = status == 'กำลังดำเนินการ' || status == 'รอดำเนินการ' || status == 'Pending';

    String typeThai = type;
    if (type.toLowerCase() == 'behavior') typeThai = 'พฤติกรรมไม่เหมาะสม';
    if (type.toLowerCase() == 'wrong location') typeThai = 'หมุดสถานที่ผิดพลาด';
    if (type.toLowerCase() == 'safety issue') typeThai = 'ความปลอดภัย';

    return GestureDetector(
      onTap: () => _showReportDetails(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: inProgress ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2340A7).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF2340A7),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            typeThai,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: inProgress
                          ? const Color(0xFFFEF3C7)
                          : (status == 'ไม่อนุมัติ'
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFD1FAE5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: inProgress
                            ? const Color(0xFFD97706)
                            : (status == 'ไม่อนุมัติ' ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "รหัสงาน: $requestId",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    final String type = report['reporttype'] ?? 'ทั่วไป';
    final String detail = report['reportdetail'] ?? 'ไม่มีรายละเอียดเพิ่มเติม';
    final String status = report['reportstatus'] ?? 'กำลังดำเนินการ';
    final int requestId = report['request_id'] ?? 0;
    final int index = report['userreportid'] ?? 0;
    final String? imagePath = report['reportimagepath'];

    String formattedDate = "ไม่ระบุวันที่";
    if (report['reportdate'] != null) {
      try {
        final rawStr = report['reportdate'].toString();
        final isoStr = (!rawStr.endsWith('Z') && !rawStr.contains('+')) ? '${rawStr}Z' : rawStr;
        final DateTime parsed = DateTime.parse(isoStr).toLocal();
        formattedDate = DateFormat('dd MMMM yyyy, HH:mm น.').format(parsed);
      } catch (e) {
        formattedDate = report['reportdate'].toString();
      }
    }

    final bool inProgress = status == 'กำลังดำเนินการ' || status == 'รอดำเนินการ' || status == 'Pending';

    String typeThai = type;
    if (type.toLowerCase() == 'behavior') typeThai = 'พฤติกรรมไม่เหมาะสม';
    if (type.toLowerCase() == 'wrong location') typeThai = 'หมุดสถานที่ผิดพลาด';
    if (type.toLowerCase() == 'safety issue') typeThai = 'ความปลอดภัย';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "รายละเอียดการรายงาน",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: inProgress
                                ? const Color(0xFFFEF3C7)
                                : (status == 'ไม่อนุมัติ' ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: inProgress
                                  ? const Color(0xFFFDE68A)
                                  : (status == 'ไม่อนุมัติ' ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "สถานะการตรวจสอบ",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: inProgress
                                      ? const Color(0xFFD97706)
                                      : (status == 'ไม่อนุมัติ' ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ประเภทการแจ้งเหตุ",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                typeThai,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "รายละเอียดที่แจ้งรายงาน",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      detail,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.confirmation_number_outlined, "รหัสรายงาน", "$index"),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildDetailRow(Icons.local_taxi_rounded, "รหัสงาน", "$requestId"),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildDetailRow(Icons.calendar_month_outlined, "วันที่แจ้งเรื่อง", formattedDate),
                      ],
                    ),
                  ),
                  if (imagePath != null && imagePath.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "ภาพแนบหลักฐาน",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imagePath.startsWith('http') 
                            ? imagePath 
                            : 'https://qbionbozkvlekpakvstg.supabase.co/storage/v1/object/public/images/$imagePath',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            color: const Color(0xFFF8FAFC),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
                                  SizedBox(width: 10),
                                  Text("ไม่สามารถโหลดภาพหลักฐานได้", style: TextStyle(color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2340A7), size: 18),
        const SizedBox(width: 10),
        Text(
          "$label:",
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
