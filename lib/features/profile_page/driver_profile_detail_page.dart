import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_project/core/theme/app_theme.dart';
import 'package:mobile_project/core/utils/image_utils.dart';
import 'package:mobile_project/features/edit_profile_page/edit_profile_page.dart';

class DriverProfileDetailPage extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const DriverProfileDetailPage({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    final firstName = profileData['firstname'] ?? profileData['first_name'];
    final lastName = profileData['lastname'] ?? profileData['last_name'];
    final name = firstName != null
        ? "$firstName ${lastName ?? ''}"
        : profileData['username'] ?? 'Unknown';

    // Format Join Date
    String joinDate = "ก.ค. 2025";
    if (profileData['created_at'] != null) {
      try {
        DateTime parsed = DateTime.parse(profileData['created_at']);
        // Format to Thai short month and year (CE + 543 for BE, or keep CE)
        joinDate = "${_getThaiMonth(parsed.month)} ${parsed.year + 543}";
      } catch (_) {}
    }

    // Get Car Plate
    String carPlate = "";
    if (profileData['drivercar'] != null && profileData['drivercar']['carplate'] != null) {
      carPlate = profileData['drivercar']['carplate'];
    }

    final subtitleText = "เข้าร่วมเมื่อ $joinDate" + (carPlate.isNotEmpty ? " • ทะเบียน $carPlate" : "");

    // Review statistics extraction
    final stats = profileData['review_stats'] ?? {};
    final int reviewCount = stats['count'] ?? 0;
    final double averageRating = (stats['average'] != null) ? double.tryParse(stats['average'].toString()) ?? 0.0 : 0.0;
    final dist = stats['distribution'] ?? {};
    
    final int count5 = int.tryParse(dist['5']?.toString() ?? '0') ?? 0;
    final int count4 = int.tryParse(dist['4']?.toString() ?? '0') ?? 0;
    final int count3 = int.tryParse(dist['3']?.toString() ?? '0') ?? 0;
    final int count2 = int.tryParse(dist['2']?.toString() ?? '0') ?? 0;
    final int count1 = int.tryParse(dist['1']?.toString() ?? '0') ?? 0;

    final double pct5 = reviewCount > 0 ? count5 / reviewCount : 0.0;
    final double pct4 = reviewCount > 0 ? count4 / reviewCount : 0.0;
    final double pct3 = reviewCount > 0 ? count3 / reviewCount : 0.0;
    final double pct2 = reviewCount > 0 ? count2 / reviewCount : 0.0;
    final double pct1 = reviewCount > 0 ? count1 / reviewCount : 0.0;

    final List<dynamic> reviewsList = profileData['reviews'] ?? [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
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
                      "โปรไฟล์ของฉัน",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                              username: profileData['username'] ?? '',
                              phoneno: profileData['phoneno'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2340A7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2340A7).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Profile Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2340A7).withOpacity(0.2), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: profileData['regisimagepath'] != null
                              ? NetworkImage(ImageUtils.getProfileImageUrl(profileData['regisimagepath']))
                              : null,
                          child: profileData['regisimagepath'] == null
                              ? const Icon(Icons.person, size: 36, color: Color(0xFF2340A7))
                              : null,
                        ),
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
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitleText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2.1 Driver Skills Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.drive_eta_rounded, size: 20, color: Color(0xFF2340A7)),
                          SizedBox(width: 8),
                          Text(
                            "ความสามารถในการขับขี่ (Driver Skills)",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildDriverSkillChips(profileData['driverskills']),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Rating Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "การให้คะแนน $reviewCount ครั้งล่าสุด",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Left Rating Score
                          Column(
                            children: [
                              Text(
                                averageRating.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "คะแนนคนขับ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Right Progress Bars
                          Expanded(
                            child: Column(
                              children: [
                                _buildRatingRow(5, count5, pct5),
                                const SizedBox(height: 6),
                                _buildRatingRow(4, count4, pct4),
                                const SizedBox(height: 6),
                                _buildRatingRow(3, count3, pct3),
                                const SizedBox(height: 6),
                                _buildRatingRow(2, count2, pct2),
                                const SizedBox(height: 6),
                                _buildRatingRow(1, count1, pct1),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. รีวิวที่ได้รับ (Reviews) Title
                const Text(
                  "รีวิวและข้อเสนอแนะที่ได้รับ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Reviews List or Empty State
                if (reviewsList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.visibility_outlined, size: 18, color: AppTheme.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              "มีเพียงคุณเท่านั้นที่เห็นหน้านี้",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "ผู้โดยสารแนะนำให้คุณปรับปรุงในเรื่องต่อไปนี้",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rate_review_outlined,
                            size: 44,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "ยังไม่มีรายงานและข้อเสนอแนะ",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "เมื่อให้บริการโดยสารมากขึ้น คุณจะได้รับข้อเสนอแนะเกี่ยวกับการปรับปรุงบริการของตัวเอง",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...reviewsList.map((rev) {
                    final int rate = rev['reviewrate'] ?? 5;
                    final String comment = rev['reviewcomment'] ?? 'ไม่มีความคิดเห็น';
                    String dateStr = '';
                    if (rev['reviewdate'] != null) {
                      try {
                        DateTime dt = DateTime.parse(rev['reviewdate']);
                        dateStr = "${dt.day} ${_getThaiMonth(dt.month)} ${dt.year + 543}";
                      } catch (_) {}
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < rate ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              const Spacer(),
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(int starCount, int reviewCount, double percentage) {
    return Row(
      children: [
        Text(
          "$starCount",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: const Color(0xFFD1D1D6),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            "$reviewCount",
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDriverSkillChips(dynamic rawSkills) {
    List<String> skills = [];
    if (rawSkills != null) {
      if (rawSkills is List) {
        skills = rawSkills.map((e) => e.toString()).toList();
      } else if (rawSkills is String && rawSkills.trim().isNotEmpty) {
        try {
          final decoded = rawSkills.trim();
          if (decoded.startsWith('[') && decoded.endsWith(']')) {
            // handle JSON string
            final list = decoded
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll('"', '')
                .split(',');
            skills = list.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          } else {
            skills = [decoded];
          }
        } catch (_) {
          skills = [rawSkills.toString()];
        }
      }
    }

    if (skills.isEmpty) {
      skills = ["ขับขี่ทั่วไป"];
    }

    return skills.map((skill) {
      IconData icon = Icons.check_circle_outline_rounded;
      String label = skill;
      
      final lower = skill.toLowerCase();
      if (lower.contains('ev') || lower.contains('electric') || lower.contains('ไฟฟ้า')) {
        icon = Icons.electric_car_rounded;
        if (!label.contains('ไฟฟ้า') && !label.contains('EV')) label = 'รถยนต์ไฟฟ้า ($skill)';
      } else if (lower.contains('auto') || lower.contains('ออโต้')) {
        icon = Icons.bolt_rounded;
        if (!label.contains('เกียร์')) label = 'เกียร์ออโต้ ($skill)';
      } else if (lower.contains('manual') || lower.contains('ธรรมดา') || lower.contains('กระปุก')) {
        icon = Icons.tune_rounded;
        if (!label.contains('เกียร์')) label = 'เกียร์ธรรมดา ($skill)';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2340A7).withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2340A7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getThaiMonth(int month) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
