import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:mobile_project/core/theme/app_theme.dart';
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
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        final rawStr = r['reportdate'].toString();
        final isoStr = (!rawStr.endsWith('Z') && !rawStr.contains('+')) ? '${rawStr}Z' : rawStr;
        final parsedDate = DateTime.parse(isoStr).toLocal();
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
                      "รายงานปัญหาของฉัน",
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

              // Tab selection filter bar
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
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
        ),
      ),
    );
  }

  // Beautiful Tab Filters
  Widget _buildFilterTabs() {
    final tabs = ['ทั้งหมด', 'กำลังดำเนินการ', 'เสร็จสิ้น'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2340A7)
                      : Colors.transparent,
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
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary,
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
              Icons.article_outlined,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "ไม่มีประวัติการแจ้งรายงาน ($_selectedTab)",
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "เมื่อคุณส่งรายงานปัญหา ข้อมูลจะแสดงที่นี่",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
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
        final rawStr = report['reportdate'].toString();
        final isoStr = (!rawStr.endsWith('Z') && !rawStr.contains('+')) ? '${rawStr}Z' : rawStr;
        final DateTime parsed = DateTime.parse(isoStr).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, HH:mm น.').format(parsed);
      } catch (e) {
        formattedDate = report['reportdate'].toString();
      }
    }

    final bool inProgress = status == 'กำลังดำเนินการ';

    return GestureDetector(
      onTap: () => _showReportDetails(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: inProgress
                ? const Color(0xFFFED7AA)
                : const Color(0xFFE2E8F0),
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
                            color: const Color(0xFF2340A7).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTypeIcon(type),
                            color: const Color(0xFF2340A7),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type,
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
                  const SizedBox(width: 10),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: inProgress
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: inProgress ? const Color(0xFFD97706) : const Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Detail preview
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

              // Divider
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),

              // Footer: Request ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Request ID badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                  // Date Text
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
        final rawStr = report['reportdate'].toString();
        final isoStr = (!rawStr.endsWith('Z') && !rawStr.contains('+')) ? '${rawStr}Z' : rawStr;
        final DateTime parsed = DateTime.parse(isoStr).toLocal();
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
                  // Handle indicator bar
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

                  // Title and Close Button
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
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Info Cards Grid-like
                  Row(
                    children: [
                      // Status Badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: inProgress
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: inProgress
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "สถานะการดำเนินการ",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: inProgress
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF059669),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Type Badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ประเภทปัญหา",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type,
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

                  // Detail Header
                  const Text(
                    "รายละเอียดที่แจ้งรายงาน",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Detail Body Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
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

                  // Metadata Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.confirmation_number_outlined,
                          "รหัสรายงาน",
                          "$index",
                        ),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildDetailRow(
                          Icons.local_taxi_rounded,
                          "รหัสงาน",
                          "$requestId",
                        ),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildDetailRow(
                          Icons.calendar_month_outlined,
                          "วันที่แจ้งเรื่อง",
                          formattedDate,
                        ),
                      ],
                    ),
                  ),

                  // Attached Image if available
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
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "ไม่สามารถโหลดภาพหลักฐานได้",
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
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
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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
