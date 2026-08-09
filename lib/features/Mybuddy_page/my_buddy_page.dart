import 'dart:async';
import 'package:mobile_project/core/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_service.dart';

class MyBuddyPage extends StatefulWidget {
  final String currentUsername;
  const MyBuddyPage({super.key, required this.currentUsername});

  @override
  State<MyBuddyPage> createState() => _MyBuddyPageState();
}

class _MyBuddyPageState extends State<MyBuddyPage> {
  Map<String, dynamic>? _buddyTeam;
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchActiveBuddy();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchActiveBuddy();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveBuddy() async {
    try {
      final response = await ApiService.get('/buddy-team/active/${widget.currentUsername}');
      if (response.statusCode == 200) {
        if (response.data == null || 
            response.data.toString().isEmpty || 
            response.data.toString() == "null" ||
            (response.data is Map && (response.data as Map).isEmpty)) {
          if (_buddyTeam != null && mounted) {
            _pollingTimer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('บัดดี้ของคุณออกจากทีมแล้ว')),
            );
            Navigator.pop(context);
          } else if (mounted) {
            setState(() {
              _buddyTeam = null;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _buddyTeam = response.data;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching active buddy: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveTeam() async {
    if (_buddyTeam == null) return;
    
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.black)),
    );

    try {
      final response = await ApiService.put('/buddy-team/reject/${_buddyTeam!['buddyteamid']}', data: {});
      
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        if (mounted) {
          _pollingTimer?.cancel();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ออกจากทีมล้มเหลว: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการออกจากทีม: $e')),
        );
      }
      debugPrint("Error leaving team: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? buddyProfile;
    if (_buddyTeam != null) {
      if (_buddyTeam!['leaderid'].toString().toLowerCase() == widget.currentUsername.toLowerCase()) {
        buddyProfile = _buddyTeam!['follower'];
      } else {
        buddyProfile = _buddyTeam!['leader'];
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "ทีมบัดดี้ของฉัน (My Buddy)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : _buddyTeam == null
                        ? _buildNoBuddyView()
                        : _buildBuddyDetailsView(buddyProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoBuddyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.group_off_rounded, size: 72, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              "ยังไม่มีทีมบัดดี้ในขณะนี้",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "ไปที่หน้าค้นหาและเลือกบัดดี้ใกล้คุณเพื่อเริ่มรับงานคู่",
              style: TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddyDetailsView(Map<String, dynamic>? profile) {
    if (profile == null) return const SizedBox();

    final isLeader = _buddyTeam?['leaderid']?.toString().toLowerCase() == profile['username']?.toString().toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: NetworkImage(ImageUtils.getProfileImageUrl(profile['regisimagepath'])),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(height: 16),
                Text(
                  "${profile['firstname']} ${profile['lastname']}",
                  style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLeader ? const Color(0xFFF59E0B) : const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLeader ? "Leader (หัวหน้าทีม)" : "Follower (ผู้ช่วย/ผู้ตาม)",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "@${profile['username']}",
                  style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(Icons.chat_bubble_outline_rounded, "แชท", Colors.black, () {}),
                    const SizedBox(width: 24),
                    _buildActionButton(Icons.phone_outlined, "โทร", Colors.black, () {}),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("ยกเลิกทีมบัดดี้?"),
                    content: const Text("คุณแน่ใจหรือไม่ว่าต้องการออกจากทีมบัดตี้นี้?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("ยกเลิก", style: TextStyle(color: Colors.black54)),
                      ),
                      TextButton(
                        onPressed: _leaveTeam,
                        child: const Text("ออกจากทีม", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("ออกจากทีมบัดดี้ (Leave Team)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
