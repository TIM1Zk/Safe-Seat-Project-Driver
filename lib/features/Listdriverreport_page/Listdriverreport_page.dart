import 'package:flutter/material.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:intl/intl.dart';

class ListDriverReportPage extends StatefulWidget {
  final String username;

  const ListDriverReportPage({super.key, required this.username});

  @override
  State<ListDriverReportPage> createState() => _ListDriverReportPageState();
}

class _ListDriverReportPageState extends State<ListDriverReportPage> {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  String _selectedTab = 'ทั้งหมด'; // 'ทั้งหมด', 'กำลังดำเนินการ', 'เสร็จสิ้น'

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);
      // Fetching driver reports for this logged in driver
      final response = await ApiService.get(
        '/driver-reports?username=${widget.username}',
      );

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
            content: Text('โหลดข้อมูลรายงานล้มเหลว: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter reports based on the selected tab and 1-month date restriction
  List<dynamic> _getFilteredReports() {
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

    final recentReports = _reports.where((r) {
      if (r['reportdate'] == null) return true;
      try {
        final parsedDate = DateTime.parse(r['reportdate'].toString()).toLocal();
        return parsedDate.isAfter(oneMonthAgo) || parsedDate.isAtSameMomentAs(oneMonthAgo);
      } catch (e) {
        return true;
      }
    }).toList();

    if (_selectedTab == 'ทั้งหมด') {
      return recentReports;
    } else if (_selectedTab == 'กำลังดำเนินการ') {
      return recentReports
          .where((r) => r['reportstatus'] == 'กำลังดำเนินการ')
          .toList();
    } else if (_selectedTab == 'เสร็จสิ้น') {
      // Treat anything else as finished/resolved
      return recentReports
          .where((r) => r['reportstatus'] != 'กำลังดำเนินการ')
          .toList();
    }
    return recentReports;
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "รายงานปัญหาของฉัน",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selection filter bar
          _buildFilterTabs(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : filteredReports.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
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
    );
  }

  // Beautiful Tab Filters
  Widget _buildFilterTabs() {
    final tabs = ['ทั้งหมด', 'กำลังดำเนินการ', 'เสร็จสิ้น'];
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 5, left: 20, right: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            "ไม่มีประวัติการแจ้งรายงาน ($_selectedTab)",
            style: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Get Custom Icon based on report type
  IconData _getTypeIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('อุบัติเหตุ') ||
        lower.contains('ฉุกเฉิน') ||
        lower.contains('อันตราย')) {
      return Icons.warning_amber_rounded;
    } else if (lower.contains('ลูกค้า') ||
        lower.contains('ผู้โดยสาร') ||
        lower.contains('คน')) {
      return Icons.person_outline_rounded;
    } else if (lower.contains('ระบบ') ||
        lower.contains('แอพ') ||
        lower.contains('app') ||
        lower.contains('ใช้งาน')) {
      return Icons.phone_android_rounded;
    } else if (lower.contains('เงิน') ||
        lower.contains('จ่าย') ||
        lower.contains('wallet') ||
        lower.contains('รายได้')) {
      return Icons.account_balance_wallet_outlined;
    } else if (lower.contains('รถ') ||
        lower.contains('พาหนะ') ||
        lower.contains('เครื่องยนต์')) {
      return Icons.directions_car_filled_outlined;
    }
    return Icons.description_outlined;
  }

  // Modern and Sleek Card layout for each report
  Widget _buildReportCard(Map<String, dynamic> report) {
    final String type = report['reporttype'] ?? 'ทั่วไป';
    final String detail = report['reportdetail'] ?? 'ไม่มีรายละเอียดเพิ่มเติม';
    final String status = report['reportstatus'] ?? 'กำลังดำเนินการ';
    final int requestId = report['request_id'] ?? 0;

    // Parse Date
    String formattedDate = "ไม่ระบุวันที่";
    if (report['reportdate'] != null) {
      try {
        final DateTime parsed = DateTime.parse(report['reportdate']).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, HH:mm น.').format(parsed);
      } catch (e) {
        formattedDate = report['reportdate'].toString();
      }
    }

    final bool inProgress = status == 'กำลังดำเนินการ';

    return GestureDetector(
      onTap: () => _showReportDetails(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: inProgress
                ? Colors.orange.withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Type and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Type tag with icon
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTypeIcon(type),
                            color: Colors.black87,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: inProgress
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: inProgress ? Colors.orange : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: inProgress ? Colors.orange : Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Detail preview
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black87.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 15),

              // Divider
              Divider(color: Colors.black.withOpacity(0.06), height: 1),
              const SizedBox(height: 10),

              // Footer: Request ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Request ID badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "รหัสงาน: #$requestId",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Date Text
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.black45,
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

  // Interactive Bottom Sheet to display full report details
  void _showReportDetails(Map<String, dynamic> report) {
    final String type = report['reporttype'] ?? 'ทั่วไป';
    final String detail = report['reportdetail'] ?? 'ไม่มีรายละเอียดเพิ่มเติม';
    final String status = report['reportstatus'] ?? 'กำลังดำเนินการ';
    final int requestId = report['request_id'] ?? 0;
    final int index = report['reportindex'] ?? 0;
    final String? imagePath = report['reportimagepath'];

    String formattedDate = "ไม่ระบุวันที่";
    if (report['reportdate'] != null) {
      try {
        final DateTime parsed = DateTime.parse(report['reportdate']).toLocal();
        formattedDate = DateFormat('dd MMMM yyyy, HH:mm น.').format(parsed);
      } catch (e) {
        formattedDate = report['reportdate'].toString();
      }
    }

    final bool inProgress = status == 'กำลังดำเนินการ';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator bar
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 25),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Title and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "รายละเอียดการรายงาน",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Cards Grid-like
                  Row(
                    children: [
                      // Status Badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: inProgress
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "สถานะการดำเนินการ",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                status,
                                style: TextStyle(
                                  color: inProgress
                                      ? Colors.orange
                                      : Colors.green,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Type Badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ประเภทปัญหา",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                type,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Detail Body
                  const Text(
                    "คำอธิบายของปัญหา",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Text(
                      detail,
                      style: TextStyle(
                        color: Colors.black87.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Metadata section
                  _buildDetailRow(
                    Icons.confirmation_number_outlined,
                    "รหัสรายงาน",
                    "#${report['driverreportid'] ?? index}",
                  ),
                  _buildDetailRow(
                    Icons.local_taxi_rounded,
                    "รหัสงาน/การเรียกรถ",
                    "#$requestId",
                  ),
                  _buildDetailRow(
                    Icons.calendar_month_outlined,
                    "วันที่แจ้งเรื่อง",
                    formattedDate,
                  ),

                  // Report Image Attachment if available
                  if (imagePath != null && imagePath.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    const Text(
                      "ภาพแนบประกอบ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        imagePath,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            color: const Color(0xFFF8F9FA),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.black26,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "ไม่สามารถโหลดภาพประกอบได้",
                                    style: TextStyle(color: Colors.black26),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black38, size: 20),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
