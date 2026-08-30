import 'package:mobile_project/core/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_project/features/Listdriverreport_page/Listdriverreport_page.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:mobile_project/core/utils/session_manager.dart';
import 'package:mobile_project/features/profile_page/driver_profile_detail_page.dart';
import 'package:mobile_project/features/service_summary/service_summary_page.dart';
import 'package:mobile_project/features/profile_page/user_reported_history_page.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  final String phoneno;
  const ProfilePage({super.key, required this.username, required this.phoneno});

  Future<Map<String, dynamic>?> getProfileData() async {
    try {
      final response = await ApiService.get('/users/$username');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<Map<String, dynamic>?>(
          future: getProfileData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const Center(
                child: Text(
                  "ไม่พบข้อมูลโปรไฟล์",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              );
            }

            final data = snapshot.data!;
            final firstName = data['firstname'] ?? data['first_name'];
            final lastName = data['lastname'] ?? data['last_name'];
            final name = firstName != null
                ? "$firstName ${lastName ?? ''}"
                : data['username'] ?? username;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Bar (Back Arrow and Title)
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black,
                            size: 26,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 2, color: Colors.grey.withOpacity(0.2)),
                    const SizedBox(height: 24),

                    // 2. Profile Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DriverProfileDetailPage(profileData: data),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5E7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFFD1D1D6),
                              backgroundImage: data['regisimagepath'] != null
                                  ? NetworkImage(
                                      ImageUtils.getProfileImageUrl(
                                        data['regisimagepath'],
                                      ),
                                    )
                                  : null,
                              child: data['regisimagepath'] == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 36,
                                      color: Color(0xFF5856D6),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${(data['review_stats'] != null && data['review_stats']['average'] != null) ? double.tryParse(data['review_stats']['average'].toString())?.toStringAsFixed(1) ?? '0.0' : '0.0'}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2340A7).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatSkillsBadge(data['driverskills']),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2340A7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black38,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ServiceSummaryPage(username: username),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5E7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "ภาพรวม",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Text(
                              "รายสัปดาห์",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      data['acceptance_rate']?.toString() ?? "100.0%",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "อัตราการรับ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      data['cancellation_rate']?.toString() ?? "0.0%",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "อัตราการยกเลิก",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. บัญชีของฉัน (My Account)
                    const Text(
                      "บัญชีของฉัน",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _buildGridItem(
                          Icons.chat_bubble_outline,
                          "กล่องข้อความ",
                          () {},
                        ),
                        _buildGridItem(
                          Icons.calendar_month_outlined,
                          "ตารางรายการ",
                          () {},
                        ),
                        _buildGridItem(
                          Icons.lightbulb_outline,
                          "สิ่งที่น่าสนใจ",
                          () {},
                        ),
                        _buildGridItem(
                          Icons.error_outline,
                          "ศูนย์ความช่วยเหลือ",
                          () {},
                        ),
                        _buildGridItem(
                          Icons.report_problem_outlined,
                          "ประวัติโดนรายงาน",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ListDriverReportPage(username: username),
                              ),
                            );
                          },
                        ),
                        _buildGridItem(
                          Icons.assignment_late_outlined,
                          "ประวัติส่งรายงาน",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserReportedHistoryPage(username: username),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 5. ศึกษาวิธีการใช้งาน (Learn to Use)
                    const Text(
                      "ศึกษาวิธีการใช้งาน",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Combined Insights and Academy/Blog Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Top section (Insights)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "เช็กข้อมูลเชิงลึกเกี่ยวกับรูปแบบการขับขี่ของคุณ",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "ดูรายงาน",
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 64,
                                  color: Color(0xFF007AFF),
                                ),
                              ],
                            ),
                          ),
                          // Bottom section (Academy & Blog)
                          Material(
                            color: const Color(0xFF707074),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.school,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  title: const Text(
                                    "Academy",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "แหล่งรวมบทเรียนต่างๆ",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap: () {},
                                ),
                                const Divider(
                                  color: Colors.white24,
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.article_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  title: const Text(
                                    "Driver Blog",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "บทความที่เป็นประโยชน์สำหรับพาร์ทเนอร์",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Logout Button (Bottom)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await SessionManager.clearSession();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "ออกจากระบบ",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
    );
  }

  Widget _buildGridItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSkillsBadge(dynamic rawSkills) {
    List<String> list = [];
    if (rawSkills != null) {
      if (rawSkills is List) {
        list = rawSkills.map((e) => e.toString()).toList();
      } else if (rawSkills is String && rawSkills.trim().isNotEmpty) {
        final decoded = rawSkills.trim();
        if (decoded.startsWith('[') && decoded.endsWith(']')) {
          list = decoded
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          list = [decoded];
        }
      }
    }

    if (list.isEmpty) {
      return "ขับขี่ทั่วไป";
    }

    // Map common skills to clean short names
    List<String> cleanSkills = [];
    for (var s in list) {
      final low = s.toLowerCase();
      if (low.contains('ev') || low.contains('electric') || low.contains('ไฟฟ้า')) {
        if (!cleanSkills.contains('EV')) cleanSkills.add('EV');
      } else if (low.contains('auto') || low.contains('ออโต้')) {
        if (!cleanSkills.contains('Auto')) cleanSkills.add('Auto');
      } else if (low.contains('manual') || low.contains('ธรรมดา') || low.contains('กระปุก')) {
        if (!cleanSkills.contains('Manual')) cleanSkills.add('Manual');
      } else {
        cleanSkills.add(s);
      }
    }
    return cleanSkills.join(' • ');
  }
}
