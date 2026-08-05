import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ServiceSummaryPage extends StatefulWidget {
  final String username;

  const ServiceSummaryPage({super.key, required this.username});

  @override
  State<ServiceSummaryPage> createState() => _ServiceSummaryPageState();
}

enum FilterPeriod { today, week, month, all }

class _ServiceSummaryPageState extends State<ServiceSummaryPage> {
  bool _isLoading = true;
  FilterPeriod _selectedPeriod = FilterPeriod.week;

  double _totalEarnings = 0.0;
  int _completedRidesCount = 0;
  double _avgEarningPerRide = 0.0;
  int _totalOnlineMinutes = 0;

  List<Map<String, dynamic>> _allRawTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];
  List<double> _dailyEarnings = [0, 0, 0, 0, 0, 0, 0]; // จันทร์ - อาทิตย์

  @override
  void initState() {
    super.initState();
    _loadEarningData();
  }

  Future<void> _loadEarningData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. ดึงทีมบัดดี้ของคนขับคนนี้
      final teamRes = await supabase
          .from('buddyteam')
          .select('buddyteamid')
          .or('leaderid.ilike.${widget.username},followerid.ilike.${widget.username}');

      final teamIds = (teamRes as List).map((t) => t['buddyteamid'] as int).toList();

      List<dynamic> allCompletedReqs = [];

      if (teamIds.isNotEmpty) {
        // 2. ดึงงานจาก requestbyuser
        final userReqs = await supabase
            .from('requestbyuser')
            .select('*')
            .inFilter('buddy_team_id', teamIds)
            .or('requeststatus.eq.completed,requeststatus.eq.เสร็จสิ้น,requeststatus.eq.Finish');

        // 3. ดึงงานจาก requestbypub
        final pubReqs = await supabase
            .from('requestbypub')
            .select('*')
            .inFilter('buddy_team_id', teamIds)
            .or('requeststatus.eq.completed,requeststatus.eq.เสร็จสิ้น,requeststatus.eq.Finish');

        allCompletedReqs = [...userReqs, ...pubReqs];
      }

      // เรียงลำดับจากใหม่สุดไปเก่าสุด
      allCompletedReqs.sort((a, b) {
        final dateA = DateTime.parse(a['reqdatetime'] ?? DateTime.now().toIso8601String());
        final dateB = DateTime.parse(b['reqdatetime'] ?? DateTime.now().toIso8601String());
        return dateB.compareTo(dateA);
      });

      List<Map<String, dynamic>> parsedTrips = [];

      if (allCompletedReqs.isNotEmpty) {
        for (var req in allCompletedReqs) {
          final requestFee = double.tryParse(req['requestfee']?.toString() ?? '0.0') ?? 0.0;
          final driverShare = double.parse((requestFee * 0.40).toStringAsFixed(2));
          final rawDate = req['reqdatetime'] ?? DateTime.now().toIso8601String();
          final parsedDate = DateTime.parse(rawDate).toLocal();
          final isPub = req['pub_id'] != null;

          final locationName = isPub 
              ? (req['custname']?.toString() ?? "ผับพาร์ทเนอร์") 
              : (req['dropoffaddress'] ?? req['pickupaddress'] ?? "จุดส่งผู้โดยสาร");

          final distanceVal = double.tryParse(req['reqdistance']?.toString() ?? '0') ?? 4.5;
          final durationVal = ((distanceVal * 3).round()).clamp(10, 60);

          parsedTrips.add({
            'id': req['requestid'] ?? req['pubrequestid'] ?? 999,
            'dateTime': parsedDate,
            'time': DateFormat('HH:mm').format(parsedDate),
            'dateFormatted': DateFormat('dd/MM/yyyy HH:mm').format(parsedDate),
            'location': locationName,
            'pickup': req['pickupname'] ?? req['pickupaddress'] ?? "จุดนัดหมาย",
            'dropoff': req['dropoffname'] ?? req['dropoffaddress'] ?? "จุดหมายปลายทาง",
            'distance': "${distanceVal.toStringAsFixed(1)} km",
            'distanceNum': distanceVal,
            'duration': "$durationVal นาที",
            'durationMins': durationVal,
            'earning': driverShare > 0 ? driverShare : requestFee,
            'totalFee': requestFee > 0 ? requestFee : 350.0,
            'isLadyMode': req['isladymode'] == true || req['isladymode']?.toString() == 'true',
            'clientName': req['custname']?.toString() ?? req['username']?.toString() ?? 'คุณลูกค้า',
            'paymentMethod': (req['paymentmethod'] == 2 || req['paymentmethod'].toString().toLowerCase().contains('wallet'))
                ? 'App Wallet'
                : 'เงินสด (Cash)',
          });
        }
      }

      _allRawTrips = parsedTrips;
      _applyFilter();
    } catch (e) {
      debugPrint("Error loading earnings data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    List<Map<String, dynamic>> filtered = [];

    for (var trip in _allRawTrips) {
      final tripDate = trip['dateTime'] as DateTime;
      if (_selectedPeriod == FilterPeriod.today) {
        if (tripDate.isAfter(todayStart) || tripDate.isAtSameMomentAs(todayStart)) {
          filtered.add(trip);
        }
      } else if (_selectedPeriod == FilterPeriod.week) {
        if (tripDate.isAfter(weekStart) || tripDate.isAtSameMomentAs(weekStart)) {
          filtered.add(trip);
        }
      } else if (_selectedPeriod == FilterPeriod.month) {
        if (tripDate.isAfter(monthStart) || tripDate.isAtSameMomentAs(monthStart)) {
          filtered.add(trip);
        }
      } else {
        filtered.add(trip);
      }
    }

    double total = 0.0;
    int totalMins = 0;
    List<double> daily = [0, 0, 0, 0, 0, 0, 0];

    for (var trip in filtered) {
      final earning = trip['earning'] as double;
      total += earning;
      totalMins += (trip['durationMins'] as int);

      final tripDate = trip['dateTime'] as DateTime;
      int weekdayIndex = tripDate.weekday - 1; // จันทร์ = 0, อาทิตย์ = 6
      if (weekdayIndex >= 0 && weekdayIndex < 7) {
        daily[weekdayIndex] += earning;
      }
    }

    setState(() {
      _filteredTrips = filtered;
      _totalEarnings = total;
      _completedRidesCount = filtered.length;
      _avgEarningPerRide = _completedRidesCount > 0 ? (total / _completedRidesCount) : 0.0;
      _totalOnlineMinutes = totalMins > 0 ? totalMins : (_completedRidesCount * 30);
      _dailyEarnings = daily;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int onlineHrs = _totalOnlineMinutes ~/ 60;
    final int onlineMins = _totalOnlineMinutes % 60;
    final String onlineText = "${onlineHrs} ชม. ${onlineMins} นาที";
    final double hourlyRate = onlineHrs > 0 ? (_totalEarnings / (onlineHrs + (onlineMins / 60))) : _totalEarnings;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : RefreshIndicator(
                  onRefresh: _loadEarningData,
                  color: Colors.black,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Bar
                        Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black,
                                size: 24,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            const Text(
                              "สรุปการให้บริการ",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.black),
                              onPressed: _loadEarningData,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 2. Filter Selector Bar (วันนี้ / สัปดาห์นี้ / เดือนนี้ / ทั้งหมด)
                        _buildFilterSelector(),
                        const SizedBox(height: 20),

                        // Total Earning Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1E1E), Color(0xFF3A3A3A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "รายได้สุทธิรวม",
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "฿${_totalEarnings.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3. Bar Chart Section
                        _buildBarChart(),
                        const SizedBox(height: 24),

                        // 4. Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.access_time,
                                title: "เวลาบริการ",
                                value: onlineText,
                                subtitle: "฿${hourlyRate.toStringAsFixed(0)} / ชม.",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.directions_car,
                                title: "จำนวนเที่ยว",
                                value: "$_completedRidesCount เที่ยว",
                                subtitle: "เสร็จสิ้นสมบูรณ์",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.bar_chart,
                                title: "เฉลี่ย/เที่ยว",
                                value: "฿${_avgEarningPerRide.toStringAsFixed(0)}",
                                subtitle: "บาทต่อเที่ยว",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // 5. Recent Trips Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ประวัติงานย้อนหลัง (${_filteredTrips.length})",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const Text(
                              "แตะเพื่อดูใบเสร็จ",
                              style: TextStyle(color: Colors.black45, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(height: 1.5, color: Colors.black12),
                        const SizedBox(height: 16),

                        // 6. Trips List
                        _filteredTrips.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredTrips.length,
                                itemBuilder: (context, index) {
                                  final trip = _filteredTrips[index];
                                  return _buildTripCard(trip);
                                },
                              ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildFilterChip("วันนี้", FilterPeriod.today),
          _buildFilterChip("สัปดาห์นี้", FilterPeriod.week),
          _buildFilterChip("เดือนนี้", FilterPeriod.month),
          _buildFilterChip("ทั้งหมด", FilterPeriod.all),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String title, FilterPeriod period) {
    final bool isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != period) {
            setState(() {
              _selectedPeriod = period;
            });
            _applyFilter();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    double maxVal = _dailyEarnings.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 100.0;
    final double yMax = ((maxVal / 50).ceil() * 50).toDouble();
    final List<String> weekdays = ["จ", "อ", "พ", "พฤ", "ศ", "ส", "อา"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "กราฟสรุปรายได้รายวัน (บาท)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.only(right: 8, top: 12, bottom: 8),
          child: Row(
            children: [
              // Y Axis
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  int labelVal = (yMax - (index * (yMax / 4))).round();
                  return SizedBox(
                    width: 32,
                    child: Text(
                      "$labelVal",
                      style: const TextStyle(color: Colors.black45, fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              // Bars
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) => Container(
                        height: 1,
                        color: Colors.black.withOpacity(0.06),
                      )),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        double earning = _dailyEarnings[index];
                        double heightFactor = (earning / yMax).clamp(0.0, 1.0);

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (earning > 0)
                              Text(
                                "฿${earning.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: 110 * heightFactor,
                              decoration: BoxDecoration(
                                color: earning > 0 ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              weekdays[index],
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black54, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final bool isLadyMode = trip['isLadyMode'] == true;

    return GestureDetector(
      onTap: () => _showTripDetailBottomSheet(trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            // เวลา
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip['time'] ?? '00:00',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  trip['dateFormatted']?.toString().split(' ')[0] ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 36, color: Colors.black12),
            const SizedBox(width: 12),
            // Trip Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip['location'] ?? 'จุดส่งผู้โดยสาร',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${trip['distance']} • ${trip['duration']}",
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      if (isLadyMode) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Lady",
                            style: TextStyle(
                              color: Color(0xFFFF1493),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // รายได้
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "เสร็จสิ้น",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "+฿${(trip['earning'] as double).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTripDetailBottomSheet(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ใบเสร็จทริป #${trip['id']}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "เสร็จสิ้นสมบูรณ์",
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailRow("วัน-เวลาให้บริการ", trip['dateFormatted'] ?? ''),
            _buildDetailRow("ลูกค้า", trip['clientName'] ?? 'คุณลูกค้า'),
            _buildDetailRow("สถานที่รับ", trip['pickup'] ?? ''),
            _buildDetailRow("สถานที่ส่ง", trip['dropoff'] ?? ''),
            _buildDetailRow("ระยะทาง / เวลา", "${trip['distance']} (${trip['duration']})"),
            _buildDetailRow("รูปแบบการชำระเงิน", trip['paymentMethod'] ?? 'เงินสด'),
            if (trip['isLadyMode'] == true)
              _buildDetailRow("โหมดบริการ", "Lady Mode (สำหรับผู้หญิง)", textColor: const Color(0xFFFF1493)),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailRow("ค่าบริการรวมทั้งสิ้น", "฿${(trip['totalFee'] as double).toStringAsFixed(2)}", isBold: true),
            _buildDetailRow("รายได้สุทธิของคนขับ", "+฿${(trip['earning'] as double).toStringAsFixed(2)}", isBold: true, textColor: const Color(0xFF2E7D32)),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("ปิดหน้ารายละเอียด", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: textColor ?? Colors.black,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              "ยังไม่มีข้อมูลทริปการบริการในช่วงเวลานี้",
              style: TextStyle(color: Colors.black45, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
