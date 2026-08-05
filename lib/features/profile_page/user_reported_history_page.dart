import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_project/core/network/api_service.dart';

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
            backgroundColor: Colors.redAccent,
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
        final parsedDate = DateTime.parse(r['reportdate'].toString()).toLocal();
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "ประวัติการรายงานผู้ใช้",
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
          // Filter Tabs
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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

  Widget _buildFilterTabs() {
    final tabs = ['ทั้งหมด', 'กำลังตรวจสอบ', 'ตรวจสอบแล้ว'];
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 5, left: 20, right: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(15),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
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
            Icons.history_outlined,
            size: 80,
            color: Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            "ไม่มีประวัติการรายงานผู้ใช้ ($_selectedFilter)",
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

  Widget _buildReportCard(Map<String, dynamic> report) {
    final String type = report['reporttype'] ?? 'ทั่วไป';
    final String detail = report['reportdetail'] ?? 'ไม่มีรายละเอียดเพิ่มเติม';
    final String status = report['reportstatus'] ?? 'กำลังดำเนินการ';
    final int requestId = report['request_id'] ?? 0;

    String formattedDate = "ไม่ระบุวันที่";
    if (report['reportdate'] != null) {
      try {
        final DateTime parsed = DateTime.parse(report['reportdate']).toLocal();
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
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: inProgress ? Colors.orange.withOpacity(0.2) : Colors.black.withOpacity(0.06),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        typeThai,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: inProgress
                          ? Colors.orange.withOpacity(0.1)
                          : (status == 'ไม่อนุมัติ'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: inProgress
                            ? Colors.orange
                            : (status == 'ไม่อนุมัติ' ? Colors.red : Colors.green),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: inProgress
                            ? Colors.orange
                            : (status == 'ไม่อนุมัติ' ? Colors.red : Colors.green),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
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
              Divider(color: Colors.black.withOpacity(0.06), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        final DateTime parsed = DateTime.parse(report['reportdate']).toLocal();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "รายละเอียดการรายงานผู้ใช้",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: inProgress ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "สถานะการตรวจสอบ",
                                style: TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                status,
                                style: TextStyle(
                                  color: inProgress ? Colors.orange : Colors.green,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ประเภทการแจ้งเหตุ",
                                style: TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                typeThai,
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
                  const Text(
                    "รายละเอียดที่แจ้งรายงาน",
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
                  _buildDetailRow(Icons.confirmation_number_outlined, "รหัสรายงาน", "#$index"),
                  _buildDetailRow(Icons.local_taxi_rounded, "รหัสงาน", "#$requestId"),
                  _buildDetailRow(Icons.calendar_month_outlined, "วันที่แจ้งเรื่อง", formattedDate),
                  if (imagePath != null && imagePath.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    const Text(
                      "ภาพแนบหลักฐาน",
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
                        imagePath.startsWith('http') 
                            ? imagePath 
                            : 'https://qbionbozkvlekpakvstg.supabase.co/storage/v1/object/public/images/$imagePath',
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
                                  Icon(Icons.broken_image_outlined, color: Colors.black26),
                                  SizedBox(width: 10),
                                  Text("ไม่สามารถโหลดภาพหลักฐานได้", style: TextStyle(color: Colors.black26)),
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
            style: TextStyle(color: Colors.black54, fontSize: 13),
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
