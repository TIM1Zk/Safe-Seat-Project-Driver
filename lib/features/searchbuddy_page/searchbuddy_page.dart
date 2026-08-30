import 'dart:async';
import 'package:mobile_project/core/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_project/core/network/api_service.dart';
import '../Mybuddy_page/my_buddy_page.dart';

class SearchbuddyPage extends StatefulWidget {
  final String currentUsername;
  const SearchbuddyPage({super.key, required this.currentUsername});

  @override
  State<SearchbuddyPage> createState() => _SearchbuddyPageState();
}

class _SearchbuddyPageState extends State<SearchbuddyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'ทั้งหมด';
  List<dynamic> _buddies = [];
  List<dynamic> _pendingRequests = []; 
  bool _isLoading = false;
  Timer? _debounce;
  Timer? _refreshTimer;

  final List<String> _categories = ['ทั้งหมด', 'ใกล้ฉัน', 'บัดดี้ล่าสุด'];

  @override
  void initState() {
    super.initState();
    _fetchBuddies();
    _fetchPendingRequests();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchPendingRequests();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final response = await ApiService.get('/buddy-team/pending/${widget.currentUsername}');
      if (response.statusCode == 200) {
        setState(() {
          _pendingRequests = response.data is List ? response.data : [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching pending requests: $e");
    }
  }

  Future<bool> _acceptRequest(int requestId) async {
    try {
      final response = await ApiService.put('/buddy-team/accept/$requestId', data: {});
      if (response.statusCode == 200) {
        await _fetchPendingRequests();
        _fetchBuddies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ยอมรับคำขอเป็นบัดดี้สำเร็จ!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => MyBuddyPage(currentUsername: widget.currentUsername))
          ).then((_) => _fetchPendingRequests());
        }
        return true;
      }
    } catch (e) {
      debugPrint("Error accepting request: $e");
    }
    return false;
  }

  Future<bool> _rejectRequest(int requestId) async {
    try {
      final response = await ApiService.put('/buddy-team/reject/$requestId', data: {});
      if (response.statusCode == 200) {
        await _fetchPendingRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ปฏิเสธคำขอเป็นบัดดี้แล้ว')),
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint("Error rejecting request: $e");
    }
    return false;
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  void _showRequestsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text("คำขอจับคู่บัดดี้ (Buddy Requests)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
              const SizedBox(height: 4),
              const Text("คำขอจะหมดอายุภายใน 5 นาที", style: TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: _pendingRequests.isEmpty
                    ? const Center(child: Text("ไม่มีคำขอจับคู่ในขณะนี้", style: TextStyle(color: Colors.black54, fontSize: 15)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _pendingRequests.length,
                        itemBuilder: (context, index) {
                          final req = _pendingRequests[index];
                          final sender = req['sender'] ?? {};
                          final name = sender['firstname'] != null 
                              ? "${sender['firstname']} ${sender['lastname'] ?? ''}" 
                              : sender['username'] ?? 'ไม่ระบุชื่อ';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: NetworkImage(ImageUtils.getProfileImageUrl(sender['regisimagepath'])),
                                  onBackgroundImageError: (_, __) {},
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "@${sender['username'] ?? 'unknown'}",
                                        style: const TextStyle(
                                          color: Colors.black45,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        await _acceptRequest(req['buddyteamid']);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF059669),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () async {
                                        await _rejectRequest(req['buddyteamid']);
                                        setModalState(() {});
                                        if (_pendingRequests.isEmpty) Navigator.pop(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchBuddies({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      if (_selectedCategory == 'บัดดี้ล่าสุด') {
        final response = await ApiService.get('/buddy-team/recent/${widget.currentUsername}');
        if (response.statusCode == 200) {
          List<dynamic> list = response.data is List ? response.data : [];
          if (query.isNotEmpty) {
            list = list.where((b) {
              final name = "${b['firstname'] ?? ''} ${b['lastname'] ?? ''} ${b['username'] ?? ''}".toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();
          }
          setState(() => _buddies = list);
        }
        return;
      }

      final categoryApi = _selectedCategory == 'ใกล้ฉัน' ? 'nearby' : 'all';
      Map<String, dynamic> params = {
        if (query.isNotEmpty) 'search': query,
        if (categoryApi != 'all') 'category': categoryApi,
        'exclude': widget.currentUsername,
      };
      final position = await _determinePosition();
      if (position != null) {
        params['lat'] = position.latitude.toString();
        params['lng'] = position.longitude.toString();
        if (_selectedCategory == 'ใกล้ฉัน') {
          params['radius'] = '2';
        }
      }
      final response = await ApiService.get('/users', queryParameters: params);
      if (response.statusCode == 200) {
        setState(() => _buddies = response.data is List ? response.data : []);
      }
    } catch (e) {
      debugPrint("Error fetching buddies: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _searchError;

  String? _validateSearchPhone(String value) {
    if (value.isEmpty) return null;
    if (value.contains(RegExp(r'\s'))) {
      return 'ต้องไม่มีเว้นวรรค หรือช่องว่าง';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'ต้องเป็นตัวเลขเท่านั้น';
    }
    if (value.length != 10) {
      return 'ต้องมีความยาว 10 ตัวอักษร';
    }
    return null;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final error = _validateSearchPhone(query);
    setState(() => _searchError = error);

    if (error != null) {
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () => _fetchBuddies(query: query));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "ค้นหาบัดดี้ (Find Buddy)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "จับคู่คนขับใกล้คุณเพื่อเริ่มรับงาน",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildIconBtn(Icons.people_outline, () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => MyBuddyPage(currentUsername: widget.currentUsername))
                      ).then((_) => _fetchPendingRequests());
                    }),
                    const SizedBox(width: 10),
                    _buildNotificationBtn(),
                  ],
                ),
              ),

              // 2. Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchBar(),
              ),

              const SizedBox(height: 14),

              // 3. Category Filter Chips
              _buildCategoryChips(),

              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),

              // 4. Buddies List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2340A7)))
                    : _buddies.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: _buddies.length,
                            itemBuilder: (context, index) {
                              return _buildBuddyCard(_buddies[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category);
                _fetchBuddies(query: _searchController.text);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2340A7) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2340A7) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF2340A7), size: 20),
      ),
    );
  }

  Widget _buildNotificationBtn() {
    return GestureDetector(
      onTap: _showRequestsSheet,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_none, color: Color(0xFF2340A7), size: 20),
          ),
          if (_pendingRequests.isNotEmpty)
            Positioned(
              right: 0, 
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '${_pendingRequests.length}', 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _searchError != null ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
              width: _searchError != null ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
            decoration: InputDecoration(
              hintText: "ค้นหาด้วยหมายเลขโทรศัพท์ (10 หลัก)...",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF2340A7), size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchError = null);
                        _fetchBuddies();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 14),
                const SizedBox(width: 4),
                Text(
                  _searchError!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBuddyCard(Map<String, dynamic> buddy) {
    final name = buddy['firstname'] != null ? "${buddy['firstname']} ${buddy['lastname'] ?? ''}" : buddy['username'] ?? 'ไม่ระบุชื่อ';
    final image = ImageUtils.getProfileImageUrl(buddy['regisimagepath']);
    final distanceStr = buddy['distance'] != null ? "${buddy['distance']} km" : "ใกล้คุณ";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: NetworkImage(image),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        distanceStr,
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "@${buddy['username'] ?? ''}",
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _sendRequest(buddy['username']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2340A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "ส่งคำขอจับคู่",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_search_rounded, size: 64, color: Colors.black26),
          SizedBox(height: 12),
          Text("ไม่พบรายชื่อบัดดี้", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("ลองค้นหาด้วยหมายเลขโทรศัพท์ 10 หลักใหม่อีกครั้ง", style: TextStyle(color: Colors.black45, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _sendRequest(String receiverUsername) async {
    try {
      double lat = 0.0;
      double lng = 0.0;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        debugPrint("Error fetching location for request: $e");
      }

      final response = await ApiService.post('/buddy-team', data: {
        'sender_id': widget.currentUsername, 
        'receiver_id': receiverUsername,
        'lat': lat,
        'lng': lng,
      });
      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งคำขอสำเร็จแล้ว! กรุณารอการตอบรับภายใน 5 นาที'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error sending request: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่งคำขอล้มเหลว: $e')));
      }
    }
  }
}
