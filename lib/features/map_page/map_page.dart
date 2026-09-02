import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/src/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:mobile_project/core/utils/session_manager.dart';
import 'package:mobile_project/features/profile_page/profile_page.dart';
import 'package:mobile_project/features/view_wallet_balance/view_wallet_balance.dart';
import 'package:mobile_project/features/Listdriverreport_page/Listdriverreport_page.dart';
import 'package:mobile_project/features/searchbuddy_page/searchbuddy_page.dart';
import 'package:mobile_project/features/map_page/finish_job_page.dart';
import 'package:mobile_project/features/map_page/report_user_page.dart';
import 'package:mobile_project/features/service_summary/service_summary_page.dart';
import 'package:mobile_project/core/utils/location_helper.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  bool isSatelliteMode = false;
  bool isMapReady = false;
  bool isOnline = false;
  bool _isLeader = true;
  bool _isLoadingLeaderStatus = true;
  int? _buddyTeamId;
  String? _currentUsername;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  RealtimeChannel? _teamChannel;
  RealtimeChannel? _activeJobChannel;
  StreamSubscription<List<Map<String, dynamic>>>? _teamStatusSubscription;
  bool _isJobOfferOpen = false;
  // ข้อมูลลูกค้าและรถยนต์สำหรับงานที่เด้งเข้ามา
  String? _clientName;
  String? _clientProfileImage;
  String? _clientPhone;
  String? _carDetails;
  String? _carSubdetails;
  String? _jobFee;
  String? _paymentMethod;
  String? _gearType;
  String? _jobDistance;
  dynamic _activeRequestId;
  bool _isLadyMode = false;

  // Active job states
  bool _hasActiveJob = false;
  bool _isJobSheetCollapsed = false;
  String _currentJobStatus = 'going to pickup';
  bool _isPubJob = false;
  String? _pickupName;
  String? _dropoffName;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _jobDuration;

  Position? _currentPosition;
  String _currentAddress = "กำลังดึงข้อมูลที่อยู่พิกัด GPS ปัจจุบัน...";

  // Buddy Partner (Follower/Leader) Live GPS
  double? _buddyLat;
  double? _buddyLng;
  String? _buddyName;

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  String? _selectedPlaceName;
  String? _selectedPlaceAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocation();
    _checkLeaderStatus();
    _startLocationUpdater();

    // ตั้งค่าสถานะแผนที่พร้อมในบิลด์ถัดไป
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isMapReady = true;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        "[SafeSeat] App resumed: syncing online and active job state from DB",
      );
      _checkLeaderStatus();
      if (_buddyTeamId != null) {
        _fetchActiveJobForTeam(_buddyTeamId!);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationUpdateTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _teamChannel?.unsubscribe();
    _activeJobChannel?.unsubscribe();
    _teamStatusSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  List<dynamic> _mySkills = [];

  Future<void> _checkLeaderStatus() async {
    try {
      String? username = await SessionManager.getUsername();
      if (username != null) {
        if (mounted) setState(() => _currentUsername = username);

        // โหลดข้อมูลสกิลของตนเองจาก /users/$username
        try {
          final profileRes = await ApiService.get('/users/$username');
          if (profileRes.statusCode == 200 && profileRes.data != null) {
            final profData = profileRes.data;
            if (profData != null && profData['driverskills'] != null) {
              if (profData['driverskills'] is List) {
                _mySkills = profData['driverskills'];
              }
            }
          }
        } catch (e) {
          debugPrint("Error fetching driver profile skills: $e");
        }

        final response = await ApiService.get('/buddy-team/active/$username');
        if (response.statusCode == 200 &&
            response.data != null &&
            response.data.toString().isNotEmpty &&
            response.data.toString() != "null") {
          final data = response.data;
          if (data is Map && data.isNotEmpty) {
            String leaderId = data['leaderid'].toString().toLowerCase();
            int? teamId;
            if (data['buddyteamid'] != null) {
              teamId = int.tryParse(data['buddyteamid'].toString());
            }
            final status = data['teamstatus']?.toString();
            final bool isCurrentlyOnline =
                (status == 'Ready' || status == 'Busy');

            if (mounted) {
              setState(() {
                _isLeader = (leaderId == username.toLowerCase());
                _buddyTeamId = teamId;
                isOnline = isCurrentlyOnline;
              });
              if (_buddyTeamId != null) {
                _setupRealtimeListeners(_buddyTeamId!);
                _fetchActiveJobForTeam(_buddyTeamId!);
              }
            }
          } else {
            if (mounted) {
              setState(() {
                _buddyTeamId = null;
                _buddyLat = null;
                _buddyLng = null;
                _buddyName = null;
                _isLeader = true;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _buddyTeamId = null;
              _buddyLat = null;
              _buddyLng = null;
              _buddyName = null;
              _isLeader = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking leader status: $e");
      if (mounted) {
        setState(() {
          _buddyTeamId = null;
          _buddyLat = null;
          _buddyLng = null;
          _buddyName = null;
          _isLeader = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLeaderStatus = false);
    }
  }

  void _setupRealtimeListeners(int teamId) {
    final supabase = Supabase.instance.client;
    debugPrint(
      "[SafeSeat debug] Setting up Realtime listeners for teamId: $teamId",
    );

    // 1. Listen for Broadcast (New Job Offers, Accepts, and Status Updates)
    _teamChannel = supabase.channel('team_room_$teamId');
    _teamChannel!
        .onBroadcast(
          event: 'new_job_dispatched',
          callback: (payload) {
            debugPrint(
              "[SafeSeat debug] Received broadcast new_job_dispatched with payload: $payload",
            );
            if (payload != null) {
              _showNewJobOfferDialog(payload);
            }
          },
        )
        .onBroadcast(
          event: 'job_accepted',
          callback: (payload) {
            debugPrint(
              "[SafeSeat debug] Received broadcast job_accepted with payload: $payload",
            );
            if (payload != null && mounted) {
              _closeJobOfferDialog();

              final innerPayload =
                  (payload.containsKey('payload') && payload['payload'] is Map)
                  ? Map<String, dynamic>.from(payload['payload'] as Map)
                  : payload;

              final reqId = innerPayload['requestid'];
              final jobData = innerPayload['job'];
              final isPub =
                  innerPayload['isPubJob'] == true ||
                  (jobData != null && jobData['pub_id'] != null);

              if (jobData != null) {
                _fetchJobOfferDetails(jobData, isPub);
              }

              setState(() {
                _hasActiveJob = true;
                _activeRequestId = reqId;
                _isPubJob = isPub;
                _currentJobStatus = 'going to pickup';

                _pickupName = "จุดนัดหมายลูกค้า";
                _dropoffName = "จุดหมายปลายทาง";

                if (jobData != null) {
                  _pickupLat =
                      double.tryParse(
                        jobData['pickuplatitude']?.toString() ?? '',
                      ) ??
                      _currentPosition?.latitude ??
                      13.7563;
                  _pickupLng =
                      double.tryParse(
                        jobData['pickuplongitude']?.toString() ?? '',
                      ) ??
                      _currentPosition?.longitude ??
                      100.5018;
                  _dropoffLat =
                      double.tryParse(
                        jobData['dropofflatitude']?.toString() ?? '',
                      ) ??
                      (_pickupLat! - 0.02);
                  _dropoffLng =
                      double.tryParse(
                        jobData['dropofflongitude']?.toString() ?? '',
                      ) ??
                      (_pickupLng! + 0.02);
                }

                _isJobOfferOpen = false;
                _updateJobMarkers();
              });
            }
          },
        )
        .onBroadcast(
          event: 'job_denied',
          callback: (payload) {
            debugPrint(
              "[SafeSeat debug] Received broadcast job_denied with payload: $payload",
            );
            if (mounted) {
              setState(() {
                _isJobOfferOpen = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('มีการปฏิเสธข้อเสนองานแล้ว')),
              );
            }
          },
        )
        .onBroadcast(
          event: 'job_status_updated',
          callback: (payload) {
            debugPrint(
              "[SafeSeat debug] Received broadcast job_status_updated with payload: $payload",
            );
            if (payload != null && mounted) {
              final innerPayload =
                  (payload.containsKey('payload') && payload['payload'] is Map)
                  ? Map<String, dynamic>.from(payload['payload'] as Map)
                  : payload;

              final newStatus = innerPayload['status']?.toString();

              setState(() {
                if (newStatus == 'arrived' || newStatus == 'ถึงจุดนัดหมาย') {
                  _currentJobStatus = 'arrived';
                } else if (newStatus == 'in progress' ||
                    newStatus == 'กำลังเดินทาง') {
                  _currentJobStatus = 'in progress';
                } else if (newStatus == 'completed' ||
                    newStatus == 'เสร็จสิ้น') {
                  _clearJobState();
                  _initLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("งานนี้เดินทางเสร็จสิ้นแล้ว!"),
                    ),
                  );
                }
              });
            }
          },
        )
        .onBroadcast(
          event: 'buddy_location',
          callback: (payload) {
            if (payload != null && mounted) {
              final innerPayload =
                  (payload.containsKey('payload') && payload['payload'] is Map)
                  ? Map<String, dynamic>.from(payload['payload'] as Map)
                  : payload;

              final sender = innerPayload['sender']?.toString();
              if (sender != _currentUsername) {
                final lat = double.tryParse(innerPayload['lat']?.toString() ?? '');
                final lng = double.tryParse(innerPayload['lng']?.toString() ?? '');
                final role = innerPayload['role']?.toString();

                if (lat != null && lng != null) {
                  setState(() {
                    _buddyLat = lat;
                    _buddyLng = lng;
                    _buddyName = role ?? "บัดดี้ร่วมทาง";
                  });
                  if (!_hasActiveJob) {
                    if (_currentPosition != null) {
                      _addDriverMarkerAt(_currentPosition!.latitude, _currentPosition!.longitude, showSnackBar: false);
                    }
                  } else {
                    _updateJobMarkers();
                  }
                }
              }
            }
          },
        )
        .onBroadcast(
          event: 'team_status_changed',
          callback: (payload) {
            debugPrint(
              "[SafeSeat debug] Received broadcast team_status_changed with payload: $payload",
            );
            if (payload != null && mounted) {
              final innerPayload =
                  (payload.containsKey('payload') && payload['payload'] is Map)
                  ? Map<String, dynamic>.from(payload['payload'] as Map)
                  : payload;

              final status = innerPayload['status']?.toString();
              setState(() {
                if (status == 'Ready') {
                  isOnline = true;
                  if (_hasActiveJob) {
                    _clearJobState();
                    _activeJobChannel?.unsubscribe();
                    _activeJobChannel = null;
                    _initLocation();
                  }
                } else if (status == 'Offline') {
                  isOnline = false;
                  if (_hasActiveJob) {
                    _clearJobState();
                    _activeJobChannel?.unsubscribe();
                    _activeJobChannel = null;
                    _initLocation();
                  }
                }
              });
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint(
            "[SafeSeat debug] Channel team_room_$teamId status: $status, error: $error",
          );
        });

    // On initialization, fetch the current active job if the team is already busy
    _fetchActiveJobForTeam(teamId);

    // 2. Listen for Team Status changes (if partner accepts job or toggles online status)
    _teamStatusSubscription = supabase
        .from('buddyteam')
        .stream(primaryKey: ['buddyteamid'])
        .eq('buddyteamid', teamId)
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) {
              final team = data.first;
              final status = team['teamstatus']?.toString();

              if (status == 'Busy') {
                _closeJobOfferDialog();
                _fetchActiveJobForTeam(teamId);
              }

              // Sync local isOnline state with DB teamstatus
              if (mounted) {
                setState(() {
                  if (status == 'Ready') {
                    isOnline = true;
                    if (_hasActiveJob) {
                      _clearJobState();
                      _activeJobChannel?.unsubscribe();
                      _activeJobChannel = null;
                      _initLocation();
                    }
                  } else if (status == 'Offline') {
                    isOnline = false;
                    if (_hasActiveJob) {
                      _clearJobState();
                      _activeJobChannel?.unsubscribe();
                      _activeJobChannel = null;
                      _initLocation();
                    }
                  }
                });
              }
            }
          },
          onError: (error) {
            debugPrint(
              "[SafeSeat debug] Realtime stream error on buddyteam: $error",
            );
          },
        );
  }

  void _setupActiveJobListener(dynamic requestId, bool isPub) {
    _activeJobChannel?.unsubscribe();

    final supabase = Supabase.instance.client;
    _activeJobChannel = supabase.channel('active_job_$requestId');
    _activeJobChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: isPub ? 'requestbypub' : 'requestbyuser',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requestid',
            value: requestId,
          ),
          callback: (payload) {
            final updatedJob = payload.newRecord;
            if (updatedJob != null && mounted) {
              final dbStatus = updatedJob['requeststatus']?.toString();
              setState(() {
                if (dbStatus == 'arrived' || dbStatus == 'ถึงจุดนัดหมาย') {
                  _currentJobStatus = 'arrived';
                } else if (dbStatus == 'in progress' ||
                    dbStatus == 'กำลังเดินทาง') {
                  _currentJobStatus = 'in progress';
                } else if (dbStatus == 'completed' || dbStatus == 'เสร็จสิ้น') {
                  _clearJobState();
                  _activeJobChannel?.unsubscribe();
                  _activeJobChannel = null;
                  _initLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("งานนี้เดินทางเสร็จสิ้นแล้ว!"),
                    ),
                  );
                }
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchActiveJobForTeam(int teamId) async {
    try {
      final supabase = Supabase.instance.client;
      var activeJobs = await supabase
          .from('requestbyuser')
          .select('*')
          .eq('buddy_team_id', teamId)
          .not('requeststatus', 'in', '("completed","เสร็จสิ้น")')
          .maybeSingle();

      bool isPub = false;
      if (activeJobs == null) {
        activeJobs = await supabase
            .from('requestbypub')
            .select('*')
            .eq('buddy_team_id', teamId)
            .not('requeststatus', 'in', '("completed","เสร็จสิ้น")')
            .maybeSingle();
        if (activeJobs != null) {
          isPub = true;
        }
      }

      if (activeJobs != null) {
        final jobData = activeJobs;

        await _fetchJobOfferDetails(jobData, isPub);

        final reqId = jobData['requestid'];
        _setupActiveJobListener(reqId, isPub);

        if (mounted) {
          setState(() {
            _hasActiveJob = true;
            _activeRequestId = reqId;
            _isPubJob = isPub;

            final dbStatus = jobData['requeststatus']?.toString();
            if (dbStatus == 'going to pickup' || dbStatus == 'กำลังไปรับ') {
              _currentJobStatus = 'going to pickup';
            } else if (dbStatus == 'arrived' || dbStatus == 'ถึงจุดนัดหมาย') {
              _currentJobStatus = 'arrived';
            } else if (dbStatus == 'in progress' ||
                dbStatus == 'กำลังเดินทาง') {
              _currentJobStatus = 'in progress';
            }

            _pickupName = "จุดนัดหมายลูกค้า";
            _dropoffName = "จุดหมายปลายทาง";
            _pickupLat =
                double.tryParse(jobData['pickuplatitude']?.toString() ?? '') ??
                _currentPosition?.latitude ??
                13.7563;
            _pickupLng =
                double.tryParse(jobData['pickuplongitude']?.toString() ?? '') ??
                _currentPosition?.longitude ??
                100.5018;
            _dropoffLat =
                double.tryParse(jobData['dropofflatitude']?.toString() ?? '') ??
                (_pickupLat! - 0.02);
            _dropoffLng =
                double.tryParse(
                  jobData['dropofflongitude']?.toString() ?? '',
                ) ??
                (_pickupLng! + 0.02);

            _isJobOfferOpen = false;
            _updateJobMarkers();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _clearJobState();
            _updateJobMarkers();
          });
        }
      }
    } catch (e) {
      debugPrint("[SafeSeat] Error fetching active job: $e");
    }
  }

  void _clearJobState() {
    _hasActiveJob = false;
    _activeRequestId = null;
    _pickupLat = null;
    _pickupLng = null;
    _dropoffLat = null;
    _dropoffLng = null;
    _pickupName = null;
    _dropoffName = null;
    _jobDuration = null;
    _polylines = [];
    if (_currentPosition != null) {
      _markers = [
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 56,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFF2563EB), width: 3),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Color(0xFF2563EB),
              size: 30,
            ),
          ),
        ),
      ];
    } else {
      _markers = [];
    }
  }

  void _startLocationUpdater() {
    _locationUpdateTimer?.cancel();
    _positionStreamSubscription?.cancel();

    // 1. Timer สำหรับตรวจสอบ leader status และ sync พิกัดสำรองทุกๆ 10 วินาที
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (_buddyTeamId == null) {
        await _checkLeaderStatus();
      }
    });

    // 2. Real-time Location Stream ดักจับการเคลื่อนที่และการเปลี่ยนพิกัดทันที (รวมถึง Emulator)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter:
          0, // รับทุกการขยับแม้ 0 เมตร (ดีมากสำหรับการทดสอบบน Emulator)
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            if (!mounted) return;

            setState(() {
              _currentPosition = position;
              _currentAddress =
                  "พิกัด: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
            });

            // ถ้าไม่มีงานค้าง ให้ขยับ Driver Marker บนแผนที่ตามพิกัดสด
            if (!_hasActiveJob) {
              _addDriverMarkerAt(
                position.latitude,
                position.longitude,
                showSnackBar: false,
              );
            } else {
              _updateJobMarkers();
            }

            // Broadcast พิกัดสดของตัวเองให้บัดดี้ (Leader <-> Follower) ทันที
            if (_teamChannel != null) {
              try {
                _teamChannel!.sendBroadcastMessage(
                  event: 'buddy_location',
                  payload: {
                    'sender': _currentUsername ?? '',
                    'lat': position.latitude,
                    'lng': position.longitude,
                    'role': _isLeader ? 'Leader' : 'Follower',
                  },
                );
              } catch (e) {
                debugPrint("Failed to broadcast buddy live location: $e");
              }
            }

            // ส่งพิกัดขึ้น Supabase ทันทีเมื่อเป็น Leader และมี buddyTeamId
            if (_isLeader && _buddyTeamId != null) {
              try {
                await Supabase.instance.client
                    .from('buddyteam')
                    .update({
                      'currentloclat': position.latitude,
                      'currentloclng': position.longitude,
                    })
                    .eq('buddyteamid', _buddyTeamId!);
              } catch (e) {
                debugPrint(
                  "Failed to update real-time team location to Supabase: $e",
                );
              }
            }
          },
          onError: (e) {
            debugPrint("Error in location stream: $e");
          },
        );
  }

  Future<void> _forceUpdateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAddress =
              "พิกัด: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
        });
        _moveToCoordinates(position.latitude, position.longitude, zoom: 15);
        _addDriverMarkerAt(
          position.latitude,
          position.longitude,
          showSnackBar: false,
        );
      }

      if (_isLeader && _buddyTeamId != null) {
        await Supabase.instance.client
            .from('buddyteam')
            .update({
              'currentloclat': position.latitude,
              'currentloclng': position.longitude,
            })
            .eq('buddyteamid', _buddyTeamId!);
        debugPrint("Forced GPS update to DB successful.");
      }
    } catch (e) {
      debugPrint("Failed to force update team location: $e");
    }
  }

  /// ตรวจสอบว่าคนขับมีทักษะตรงกับประเภทรถที่ต้องการหรือไม่
  /// คืนค่า true = ทักษะตรง สามารถรับงานได้
  /// คืนค่า false = ทักษะไม่ตรง ห้ามแสดง popup
  bool _hasSkillForCarType(int? reqType) {
    // ถ้าไม่มี requiredcartype หรือเป็นค่าที่ไม่รู้จัก ถือว่ารับได้ (Auto default)
    if (reqType == null || reqType == 3) {
      // Auto (3) = ทุกคนรับได้
      return true;
    }

    // ถ้าไม่มีข้อมูลสกิล ถือว่าขับได้แค่ Auto เท่านั้น
    if (_mySkills.isEmpty) {
      debugPrint("[SafeSeat Client] No skills data, defaulting to Auto-only driver");
      return false; // ไม่มีสกิล = ขับ EV/Manual ไม่ได้
    }

    final skillsText = _mySkills.map((s) => s.toString().toLowerCase()).join(' ');

    if (reqType == 1) {
      // EV - ต้องมีสกิล EV
      return skillsText.contains('ev') || skillsText.contains('electric') || skillsText.contains('ไฟฟ้า');
    } else if (reqType == 2) {
      // Manual - ต้องมีสกิล Manual
      return skillsText.contains('manual') || skillsText.contains('ธรรมดา') || skillsText.contains('กระปุก');
    }

    return true;
  }

  /// แปลง requiredcartype จาก payload (อาจเป็น int, String, หรือ null) เป็น int?
  int? _parseCarType(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _fetchJobOfferDetails(
    Map<String, dynamic> payload,
    bool isPub,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      if (isPub) {
        final note = payload['note']?.toString() ?? '';

        setState(() {
          _clientName = payload['custname']?.toString() ?? 'ลูกค้าทั่วไป';
          _clientProfileImage = null;
          _clientPhone = payload['phoneno']?.toString() ?? '';
          _isLadyMode =
              payload['isladymode'] == true ||
              payload['isladymode']?.toString() == 'true';

          // ดึงข้อมูลรุ่นรถและทะเบียนจาก note หากมีรูปแบบ [รุ่นรถ: ... | ทะเบียน: ...]
          String parsedCarInfo = "";
          String customNote = note;
          if (note.contains('[รุ่นรถ:') && note.contains(']')) {
            final match = RegExp(
              r'\[รุ่นรถ:\s*(.*?)\s*\|\s*ทะเบียน:\s*(.*?)\]',
            ).firstMatch(note);
            if (match != null) {
              final carModel = match.group(1) ?? '';
              final carPlate = match.group(2) ?? '';
              parsedCarInfo = "$carModel ทะเบียน $carPlate".trim();
              customNote = note.replaceAll(match.group(0)!, '').trim();
            }
          }

          final carType = payload['requiredcartype']?.toString() ?? '';
          if (parsedCarInfo.isNotEmpty) {
            _carDetails = parsedCarInfo;
          } else if (carType == '1') {
            _carDetails = "รถยนต์ไฟฟ้า (EV)";
          } else if (carType == '2') {
            _carDetails = "รถยนต์เกียร์ธรรมดา (Manual)";
          } else {
            _carDetails = "รถยนต์เกียร์ออโต้ (Auto)";
          }

          final phoneEmer = payload['phoneemer']?.toString() ?? '';
          _carSubdetails = customNote.isNotEmpty
              ? "หมายเหตุ: $customNote"
              : "เบอร์ติดต่อฉุกเฉิน: ${phoneEmer.isNotEmpty ? phoneEmer : 'ไม่มี'}";

          final fee = payload['requestfee'];
          if (fee != null) {
            final feeDouble = double.tryParse(fee.toString());
            _jobFee = feeDouble != null
                ? "${feeDouble.toStringAsFixed(2)} บาท"
                : "${fee.toString()} บาท";
          } else {
            _jobFee = "0.00 บาท";
          }

          final payMethod = payload['paymentmethod'];
          if (payMethod == 2 ||
              payMethod.toString().toLowerCase().contains('wallet')) {
            _paymentMethod = "App Wallet";
          } else {
            _paymentMethod = "เงินสด (Cash)";
          }
        });

        // ตรวจสอบระบบเกียร์และทักษะของคนขับก่อนเปิด Popup เสมอ
        final requiredCarType = payload['requiredcartype'];
        String currentGearType = "Auto Gear";
        if (requiredCarType == 1 || note.toLowerCase().contains('ev') || note.toLowerCase().contains('electric') || note.contains('ไฟฟ้า')) {
          currentGearType = "รถยนต์ไฟฟ้า (EV)";
        } else if (requiredCarType == 2 || note.toLowerCase().contains('manual') || note.toLowerCase().contains('ธรรมดา')) {
          currentGearType = "Manual Gear";
        } else if (requiredCarType == 3 || note.toLowerCase().contains('auto') || note.toLowerCase().contains('ออโต้')) {
          currentGearType = "Auto Gear";
        }

        // ตรวจสอบทักษะคนขับ — ถ้าไม่ตรงกับประเภทรถ ไม่แสดง popup
        final parsedReqType = _parseCarType(requiredCarType);
        if (!_hasSkillForCarType(parsedReqType)) {
          debugPrint("[SafeSeat Client] Suppressed Pub job dialog: skill mismatch (reqType=$parsedReqType, skills=$_mySkills)");
          return;
        }

        final dist = payload['reqdistance'];
        String jobDist = "0.0 km";
        if (dist != null) {
          final distDouble = double.tryParse(dist.toString());
          jobDist = distDouble != null ? "${distDouble.toStringAsFixed(2)} km" : "${dist.toString()} km";
        }

        setState(() {
          _gearType = currentGearType;
          _jobDistance = jobDist;
          _activeRequestId = payload['requestid'];
          _isJobOfferOpen = true;
        });
        return;
      }

      final userId = payload['user_id']?.toString() ?? '';
      final userCarId = payload['user_car_id'];

      // 1. ดึงข้อมูล User (ลูกค้า)
      Map<String, dynamic>? userData;
      if (userId.isNotEmpty) {
        final userRes = await supabase
            .from('User')
            .select('name, profileimagepath, phoneno')
            .eq('phoneno', userId)
            .maybeSingle();
        userData = userRes;
      }

      // 2. ดึงข้อมูลรถยนต์ (usercar) พร้อมประเภทรถ cartype
      Map<String, dynamic>? carData;
      if (userCarId != null) {
        final carRes = await supabase
            .from('usercar')
            .select('carbrand, carcolor, carmodel, carplate, car_type, cartype:car_type(cartypename)')
            .eq('usercarid', userCarId)
            .maybeSingle();
        carData = carRes;
      }

      // ตรวจสอบระบบเกียร์ / ประเภทรถ และกรองทักษะคนขับก่อน setState
      final note = payload['note']?.toString() ?? '';
      final requiredCarType = payload['requiredcartype'] ?? carData?['car_type'];
      final cartypeName = carData?['cartype']?['cartypename']?.toString() ?? '';

      String calculatedGearType = "Auto Gear";
      if (requiredCarType == 1 || cartypeName.toLowerCase() == 'ev' || note.toLowerCase().contains('ev') || note.toLowerCase().contains('electric') || note.contains('ไฟฟ้า')) {
        calculatedGearType = "รถยนต์ไฟฟ้า (EV)";
      } else if (requiredCarType == 2 || cartypeName.toLowerCase() == 'manual' || note.toLowerCase().contains('manual') || note.toLowerCase().contains('ธรรมดา')) {
        calculatedGearType = "Manual Gear";
      } else if (requiredCarType == 3 || cartypeName.toLowerCase() == 'auto' || note.toLowerCase().contains('auto') || note.toLowerCase().contains('ออโต้')) {
        calculatedGearType = "Auto Gear";
      } else {
        calculatedGearType = "Auto / Manual / EV";
      }

      // ตรวจสอบทักษะคนขับ — ถ้าไม่ตรงกับประเภทรถ ไม่แสดง popup
      final parsedUserReqType = _parseCarType(requiredCarType);
      if (!_hasSkillForCarType(parsedUserReqType)) {
        debugPrint("[SafeSeat Client] Suppressed User job dialog: skill mismatch (reqType=$parsedUserReqType, skills=$_mySkills)");
        return;
      }

      setState(() {
        _clientName = userData?['name']?.toString() ?? 'ลูกค้าทั่วไป';
        _clientProfileImage = userData?['profileimagepath']?.toString();
        _clientPhone = userData?['phoneno']?.toString() ?? userId;
        _isLadyMode =
            payload['isladymode'] == true ||
            payload['isladymode']?.toString() == 'true';

        if (carData != null) {
          final brand = carData['carbrand']?.toString() ?? '';
          final model = carData['carmodel']?.toString() ?? '';
          _carDetails = "$brand $model".trim();
          if (_carDetails!.isEmpty) _carDetails = "รถยนต์ส่วนบุคคล";

          final color = carData['carcolor']?.toString() ?? '';
          final plate = carData['carplate']?.toString() ?? '';
          _carSubdetails =
              "${color.isNotEmpty ? 'สี$color' : ''} ทะเบียน ${plate.isNotEmpty ? plate : 'ไม่ระบุ'}"
                  .trim();
        } else {
          _carDetails = "รถยนต์ส่วนบุคคล";
          _carSubdetails = "ไม่ทราบรายละเอียดรถ";
        }

        final fee = payload['requestfee'];
        if (fee != null) {
          final feeDouble = double.tryParse(fee.toString());
          _jobFee = feeDouble != null
              ? "${feeDouble.toStringAsFixed(2)} บาท"
              : "${fee.toString()} บาท";
        } else {
          _jobFee = "0.00 บาท";
        }

        final payMethod = payload['paymentmethod'];
        if (payMethod == 2 ||
            payMethod.toString().toLowerCase().contains('wallet')) {
          _paymentMethod = "App Wallet";
        } else {
          _paymentMethod = "เงินสด (Cash)";
        }

        _gearType = calculatedGearType;

        final dist = payload['reqdistance'];
        if (dist != null) {
          final distDouble = double.tryParse(dist.toString());
          _jobDistance = distDouble != null
              ? "${distDouble.toStringAsFixed(2)} km"
              : "${dist.toString()} km";
        } else {
          _jobDistance = "0.0 km";
        }

        _activeRequestId = payload['requestid'];
        _isJobOfferOpen = true;
      });
    } catch (e) {
      debugPrint("Error fetching job offer details: $e");
    }
  }

  void _showNewJobOfferDialog(Map<String, dynamic> payload) {
    if (!isOnline) {
      debugPrint("Driver is offline. Ignoring job offer.");
      return;
    }
    if (_isJobOfferOpen) return; // Prevent multiple dialogs

    // Extract the actual payload if it is wrapped in Supabase Realtime envelope
    Map<String, dynamic> actualPayload = payload;
    if (payload.containsKey('payload') && payload['payload'] is Map) {
      actualPayload = Map<String, dynamic>.from(payload['payload'] as Map);
    }
    debugPrint("[SafeSeat debug] actualPayload extracted: $actualPayload");

    // ตรวจสอบทักษะคนขับก่อนแสดง popup — ถ้าไม่ตรงกับประเภทรถ ไม่แสดง
    final reqType = _parseCarType(actualPayload['requiredcartype']);
    if (!_hasSkillForCarType(reqType)) {
      debugPrint("[SafeSeat Client] Ignored job offer: skill mismatch (reqType=$reqType, skills=$_mySkills)");
      return;
    }

    final isPub =
        actualPayload['isPubJob'] == true || actualPayload['pub_id'] != null;
    setState(() {
      _isPubJob = isPub;
    });

    _fetchJobOfferDetails(actualPayload, isPub);
  }

  void _closeJobOfferDialog() {
    if (_isJobOfferOpen && mounted) {
      setState(() {
        _isJobOfferOpen = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("บัดดี้ของคุณรับงานนี้แล้ว กำลังเข้าสู่โหมดนำทาง"),
        ),
      );
    }
  }

  void _triggerLadyModeTestJob() {
    final payloadData = {
      'requestid': 999,
      'custname': 'คุณอารียา (ทดสอบ Lady Mode)',
      'phoneno': '081-234-5678',
      'isladymode': true,
      'isPubJob': true,
      'requiredcartype': '1',
      'requestfee': '350',
      'paymentmethod': 'เงินสด',
      'reqdistance': '4.5',
      'pickupname': 'สยามพารากอน (Siam Paragon)',
      'dropoffname': 'คอนโดมิเนียม สุขุมวิท 24',
    };

    // ส่งสัญญาณ Broadcast ผ่าน Supabase Realtime ให้เด้งพร้อมกันทั้งทีม (ทุกเครื่องที่อยู่ในทีมเดียวกัน)
    _teamChannel?.send(
      type: RealtimeListenTypes.broadcast,
      event: 'new_job_dispatched',
      payload: payloadData,
    );

    // แสดงป๊อบอัพรับงานบนเครื่องปัจจุบัน
    _showNewJobOfferDialog(payloadData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "ส่งสัญญาณทดสอบรับงาน Lady Mode ไปยังทุกคนในทีมเรียบร้อยแล้ว",
        ),
        backgroundColor: Color(0xFFFF1493),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<Map<String, dynamic>> _getOSRMRouteWithInfo(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final url =
          "https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson";
      final dio = Dio();
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final double distanceMeters =
              (route['distance'] as num?)?.toDouble() ?? 0.0;
          final double durationSeconds =
              (route['duration'] as num?)?.toDouble() ?? 0.0;

          List<LatLng> points = [];
          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            points = coords.map((c) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();
          }

          return {
            'points': points,
            'distanceKm': distanceMeters / 1000.0,
            'durationMin': (durationSeconds / 60.0).ceil(),
          };
        }
      }
    } catch (e) {
      debugPrint("[SafeSeat OSRM] Error fetching route: $e");
    }
    // Fallback to straight line if OSRM fails
    return {
      'points': [start, end],
      'distanceKm': null,
      'durationMin': null,
    };
  }

  Future<void> _updateJobMarkers() async {
    if (!_hasActiveJob) {
      if (mounted) {
        setState(() {
          _polylines = [];
          List<Marker> idleMarkers = [];
          if (_currentPosition != null) {
            idleMarkers.add(
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 56,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: Color(0xFF2563EB),
                    size: 30,
                  ),
                ),
              ),
            );
          }

          // Buddy Marker (รถคันที่ 2: Follower / Leader - แสดงเฉพาะเมื่อมีทีมบัดดี้แล้ว)
          if (_buddyTeamId != null && _buddyLat != null && _buddyLng != null) {
            final isBuddyLeader = _buddyName?.toLowerCase().contains('leader') ?? false;
            final buddyColor = isBuddyLeader ? const Color(0xFFD97706) : const Color(0xFF10B981);

            idleMarkers.add(
              Marker(
                point: LatLng(_buddyLat!, _buddyLng!),
                width: 60,
                height: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: buddyColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _buddyName ?? "Buddy",
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: buddyColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: buddyColor, width: 2.5),
                      ),
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        color: buddyColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          _markers = idleMarkers;
        });
      }
      return;
    }

    List<Marker> jobMarkers = [];
    List<Polyline> jobPolylines = [];

    // 1. Driver Marker (ตำแหน่งคนขับของเครื่องนี้ - สีน้ำเงินแบรนด์คงที่ #2563EB)
    if (_currentPosition != null) {
      jobMarkers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 56,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFF2563EB), width: 3),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Color(0xFF2563EB),
              size: 30,
            ),
          ),
        ),
      );
    }

    // 1.1 Buddy Marker (รถคันที่ 2 ของบัดดี้ร่วมทีม - แสดงเฉพาะเมื่อมีทีม)
    if (_buddyTeamId != null && _buddyLat != null && _buddyLng != null) {
      final isBuddyLeader = _buddyName?.toLowerCase().contains('leader') ?? false;
      final buddyColor = isBuddyLeader ? const Color(0xFFD97706) : const Color(0xFF10B981);

      jobMarkers.add(
        Marker(
          point: LatLng(_buddyLat!, _buddyLng!),
          width: 60,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: buddyColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _buddyName ?? "Buddy",
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: buddyColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: buddyColor, width: 2.5),
                ),
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  color: buddyColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Pickup Marker (จุดรับ 🟠 #F97316 Amber/Orange)
    if (_pickupLat != null && _pickupLng != null) {
      jobMarkers.add(
        Marker(
          point: LatLng(_pickupLat!, _pickupLng!),
          width: 56,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF97316), // จุดรับสีส้ม #F97316
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.sports_bar_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      );
    }

    // 3. Dropoff Marker (จุดส่ง 🟢 #10B981)
    if (_dropoffLat != null && _dropoffLng != null) {
      jobMarkers.add(
        Marker(
          point: LatLng(_dropoffLat!, _dropoffLng!),
          width: 56,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF10B981), // จุดส่ง #10B981
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = jobMarkers;
    });

    // (Do not force move camera every location tick so user can freely pan/zoom map)

    // Generate route line (polylines) using OSRM
    List<LatLng> driverToPickup = [];
    int? driverToPickupMin;
    double? driverToPickupKm;
    if (_currentPosition != null && _pickupLat != null && _pickupLng != null) {
      final info = await _getOSRMRouteWithInfo(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(_pickupLat!, _pickupLng!),
      );
      driverToPickup = (info['points'] as List<LatLng>?) ?? [];
      driverToPickupKm = info['distanceKm'] as double?;
      driverToPickupMin = info['durationMin'] as int?;
    }

    List<LatLng> pickupToDropoff = [];
    int? pickupToDropoffMin;
    double? pickupToDropoffKm;
    if (_pickupLat != null &&
        _pickupLng != null &&
        _dropoffLat != null &&
        _dropoffLng != null) {
      final info = await _getOSRMRouteWithInfo(
        LatLng(_pickupLat!, _pickupLng!),
        LatLng(_dropoffLat!, _dropoffLng!),
      );
      pickupToDropoff = (info['points'] as List<LatLng>?) ?? [];
      pickupToDropoffKm = info['distanceKm'] as double?;
      pickupToDropoffMin = info['durationMin'] as int?;
    }

    if (driverToPickup.isNotEmpty) {
      jobPolylines.add(
        Polyline(
          points: driverToPickup,
          color: const Color(0xFF2563EB), // #2563EB Accent Blue
          strokeWidth: 5.0,
        ),
      );
    }

    if (pickupToDropoff.isNotEmpty) {
      jobPolylines.add(
        Polyline(
          points: pickupToDropoff,
          color: const Color(0xFF2340A7), // #2340A7 Primary Brand Polyline
          strokeWidth: 5.0,
        ),
      );
    }

    if (mounted && _hasActiveJob) {
      setState(() {
        _polylines = jobPolylines;

        // คำนวณระยะทางและเวลาตามสถานะปัจจุบัน
        if (_currentJobStatus == 'going to pickup') {
          if (driverToPickupKm != null) {
            _jobDistance = "${driverToPickupKm.toStringAsFixed(2)} km";
          }
          if (driverToPickupMin != null) {
            _jobDuration = "$driverToPickupMin Min";
          }
        } else {
          // ช่วงกำลังเดินทางไปส่งลูกค้า
          if (pickupToDropoffKm != null) {
            _jobDistance = "${pickupToDropoffKm.toStringAsFixed(2)} km";
          }
          if (pickupToDropoffMin != null) {
            _jobDuration = "$pickupToDropoffMin Min";
          }
        }
      });
    }
  }

  Future<void> _acceptTeamJob(dynamic requestId) async {
    debugPrint(
      "[SafeSeat debug] _acceptTeamJob called with requestId: $requestId, _buddyTeamId: $_buddyTeamId",
    );
    // หากเป็นงานจำลอง (999) ให้เปิดหน้างานจำลองทันทีโดยไม่ต้องส่งไปหลังบ้าน
    if (requestId == 999) {
      if (mounted) {
        setState(() {
          _hasActiveJob = true;
          _activeRequestId = requestId;
          _currentJobStatus = 'going to pickup';
          _pickupName = "ผับคุณหนูนิ่มประจำเชียงใหม่";
          _dropoffName = "บ้านพักคุณหนูนิ่ม";
          _pickupLat = 18.8972;
          _pickupLng = 99.0112;
          _dropoffLat = 18.8852;
          _dropoffLng = 99.0134;
          _updateJobMarkers();
        });

        // บรอดแคสต์บอกเครื่องบัดดี้ในทีมว่ากดรับงานแล้ว ให้เข้าสู่โหมดนำทางพร้อมกัน
        _teamChannel?.send(
          type: RealtimeListenTypes.broadcast,
          event: 'job_accepted',
          payload: {
            'requestid': requestId,
            'job': {
              'custname': _clientName ?? 'คุณอารียา (ทดสอบ Lady Mode)',
              'phoneno': _clientPhone ?? '081-234-5678',
              'isladymode': true,
              'isPubJob': true,
              'requestfee': '350',
              'paymentmethod': 'เงินสด',
              'reqdistance': '4.5',
              'pickuplatitude': 18.8972,
              'pickuplongitude': 99.0112,
              'dropofflatitude': 18.8852,
              'dropofflongitude': 99.0134,
            },
            'isPubJob': true,
          },
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('รับงานจำลองสำเร็จ!')));
      }
      return;
    }

    try {
      if (_buddyTeamId == null) {
        debugPrint("[SafeSeat debug] _buddyTeamId is null! Cannot accept job.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'รับงานล้มเหลว: ไม่พบข้อมูลทีมคนขับในเครื่อง (buddyTeamId is null)',
              ),
            ),
          );
        }
        return;
      }

      final response = await ApiService.post(
        '/buddy-team/accept-job',
        data: {
          'request_id': requestId,
          'buddy_team_id': _buddyTeamId,
          'is_pub_job': _isPubJob,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'รับงานสำเร็จ')),
          );

          final jobData = response.data['job'];

          setState(() {
            _hasActiveJob = true;
            _activeRequestId = requestId;
            _currentJobStatus = 'going to pickup';

            _pickupName = "จุดนัดหมายลูกค้า";
            _dropoffName = "จุดหมายปลายทาง";

            if (jobData != null) {
              _pickupLat =
                  double.tryParse(
                    jobData['pickuplatitude']?.toString() ?? '',
                  ) ??
                  _currentPosition?.latitude ??
                  13.7563;
              _pickupLng =
                  double.tryParse(
                    jobData['pickuplongitude']?.toString() ?? '',
                  ) ??
                  _currentPosition?.longitude ??
                  100.5018;
              _dropoffLat =
                  double.tryParse(
                    jobData['dropofflatitude']?.toString() ?? '',
                  ) ??
                  (_pickupLat! - 0.02);
              _dropoffLng =
                  double.tryParse(
                    jobData['dropofflongitude']?.toString() ?? '',
                  ) ??
                  (_pickupLng! + 0.02);
            } else {
              _pickupLat = _currentPosition?.latitude ?? 13.7563;
              _pickupLng = _currentPosition?.longitude ?? 100.5018;
              _dropoffLat = (_currentPosition?.latitude ?? 13.7563) - 0.02;
              _dropoffLng = (_currentPosition?.longitude ?? 100.5018) + 0.02;
            }

            _setupActiveJobListener(requestId, _isPubJob);
            _updateJobMarkers();
          });

          // Broadcast to buddy that job has been accepted
          _teamChannel?.send(
            type: RealtimeListenTypes.broadcast,
            event: 'job_accepted',
            payload: {
              'requestid': requestId,
              'job': jobData,
              'isPubJob': _isPubJob,
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ??
                    'รับงานไม่สำเร็จ (อาจมีคนรับไปแล้ว)',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์'),
          ),
        );
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      debugPrint("[SafeSeat Mapbox] Checking location services...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "โปรดเปิด GPS และยอมรับสิทธิ์ในการระบุพิกัด";
        });
        return;
      }

      debugPrint("[SafeSeat Mapbox] Checking permission status...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("[SafeSeat Mapbox] Requesting permission...");
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // ดึงตำแหน่งสดของเครื่องโดยตรง (ไม่ใช้แคชเก่า getLastKnownPosition)
        Position position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (e) {
          debugPrint(
            "[SafeSeat Mapbox] Timeout/Error fetching live position: $e",
          );
          position = Position(
            longitude: 100.5018,
            latitude: 13.7563,
            timestamp: DateTime.now(),
            accuracy: 100,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }

        String address =
            "พิกัด: " +
            position.latitude.toStringAsFixed(5) +
            ", " +
            position.longitude.toStringAsFixed(5);

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _currentAddress = address;
          });

          // ย้ายกล้องไปที่ตำแหน่งจริงของเครื่องทันที
          _moveToCoordinates(position.latitude, position.longitude, zoom: 15);
          _addDriverMarkerAt(
            position.latitude,
            position.longitude,
            showSnackBar: false,
          );
        }
      } else {
        setState(() {
          _currentAddress = "ไม่ได้สิทธิ์การเข้าถึงตำแหน่งที่อยู่";
        });
      }
    } catch (e) {
      debugPrint("[SafeSeat Mapbox] Error in _initLocation: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "เกิดข้อผิดพลาดในการโหลดตำแหน่ง";
        });
      }
    }
  }

  void _moveToCoordinates(double lat, double lon, {double zoom = 15}) {
    if (!isMapReady) return;
    _mapController.move(LatLng(lat, lon), zoom);
  }

  void _addDriverMarkerAt(
    double lat,
    double lon, {
    bool showSnackBar = true,
  }) async {
    final address =
        "พิกัด: " + lat.toStringAsFixed(5) + ", " + lon.toStringAsFixed(5);

    setState(() {
      _currentAddress = address;

      List<Marker> currentMarkers = [
        Marker(
          point: LatLng(lat, lon),
          width: 56,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFF2563EB), width: 3),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Color(0xFF2563EB),
              size: 30,
            ),
          ),
        ),
      ];

      if (_buddyTeamId != null && _buddyLat != null && _buddyLng != null) {
        final isBuddyLeader = _buddyName?.toLowerCase().contains('leader') ?? false;
        final buddyColor = isBuddyLeader ? const Color(0xFFD97706) : const Color(0xFF10B981);

        currentMarkers.add(
          Marker(
            point: LatLng(_buddyLat!, _buddyLng!),
            width: 60,
            height: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: buddyColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _buddyName ?? "Buddy",
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: buddyColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: buddyColor, width: 2.5),
                  ),
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: buddyColor,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      _markers = currentMarkers;
    });

    _moveToCoordinates(lat, lon, zoom: 15);
  }

  void _showMarkerDetails(String name, String address) {
    setState(() {
      _selectedPlaceName = name;
      _selectedPlaceAddress = address;
    });
  }

  void _zoomIn() {
    _moveToCoordinates(
      _mapController.camera.center.latitude,
      _mapController.camera.center.longitude,
      zoom: _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _moveToCoordinates(
      _mapController.camera.center.latitude,
      _mapController.camera.center.longitude,
      zoom: _mapController.camera.zoom - 1,
    );
  }

  Widget _buildOnlineOfflineButton() {
    // กำหนดสีปุ่มตามสถานะของสิทธิ์และการออนไลน์
    Color buttonColor;
    String buttonText;

    if (_isLoadingLeaderStatus) {
      buttonColor = const Color(0xFF1E1F22).withOpacity(0.5);
      buttonText = "LOADING...";
    } else if (!_isLeader) {
      // สำหรับผู้ตาม (Follower) จะไม่สามารถกดปุ่มได้ ปุ่มจะแสดงเป็นสีเทาแสดงผลสถานะออนไลน์/ออฟไลน์ตามหัวหน้า
      buttonColor = Colors.grey.withOpacity(0.5);
      buttonText = isOnline ? "ONLINE (BUDDY)" : "OFFLINE (BUDDY)";
    } else {
      // สำหรับหัวหน้าทีม (Leader) แสดงสีตามปกติ
      buttonColor = isOnline
          ? const Color(0xFF22C55E)
          : const Color(0xFF1E1F22);
      buttonText = isOnline ? "ONLINE" : "OFFLINE";
    }

    return GestureDetector(
      onTap: () async {
        if (_isLoadingLeaderStatus) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("กำลังโหลดสถานะหัวหน้าทีม...")),
          );
          return;
        }

        if (!_isLeader) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("เฉพาะหัวหน้าทีมเท่านั้นที่สามารถกด Online ได้"),
            ),
          );
          return;
        }

        if (!isOnline) {
          // กำลังจะเปิด Online
          if (_buddyTeamId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "กรุณาจับคู่เพื่อนร่วมทางก่อนเข้าสู่สถานะออนไลน์",
                ),
              ),
            );
            String? username = await SessionManager.getUsername();
            if (username != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchbuddyPage(currentUsername: username),
                ),
              );
            }
            return;
          }
        }

        final newOnlineState = !isOnline;

        // Update database teamstatus & Broadcast
        if (_buddyTeamId != null) {
          final targetStatus = newOnlineState ? 'Ready' : 'Offline';
          try {
            await Supabase.instance.client
                .from('buddyteam')
                .update({'teamstatus': targetStatus})
                .eq('buddyteamid', _buddyTeamId!);
          } catch (e) {
            debugPrint("Failed to update team status in DB: $e");
          }

          try {
            await _teamChannel?.sendBroadcastMessage(
              event: 'team_status_changed',
              payload: {'status': targetStatus, 'sender': _currentUsername},
            );
          } catch (e) {
            debugPrint("Failed to broadcast team status: $e");
          }
        }

        setState(() {
          isOnline = newOnlineState;
        });
        if (isOnline) {
          _forceUpdateLocation();
        }
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power_settings_new, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddyButton() {
    return GestureDetector(
      onTap: () async {
        String? username = await SessionManager.getUsername();
        if (username != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchbuddyPage(currentUsername: username),
            ),
          );
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.people_alt_outlined,
          color: Colors.black,
          size: 26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ใช้แผนที่มาตรฐานของ OpenStreetMap
    final String openMapUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

    return Scaffold(
      body: Stack(
        children: [
          // 1. แผนที่ Fullscreen
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                13.7563,
                100.5018,
              ), // กรุงเทพฯ เป็นค่าเริ่มต้น
              initialZoom: 12.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: openMapUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.mobile_project',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),

          // ป้ายบอกสถานะบทบาทในทีม (Leader / Follower)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLoadingLeaderStatus
                      ? Colors.grey
                      : (_buddyTeamId == null
                            ? Colors.grey
                            : (_isLeader
                                  ? const Color(0xFF2340A7)
                                  : const Color(0xFFD97706))),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLoadingLeaderStatus
                        ? Icons.hourglass_empty
                        : (_buddyTeamId == null
                              ? Icons.link_off
                              : (_isLeader
                                    ? Icons.stars
                                    : Icons.supervised_user_circle)),
                    color: _isLoadingLeaderStatus
                        ? Colors.grey
                        : (_buddyTeamId == null
                              ? Colors.grey
                              : (_isLeader
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFD97706))),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLoadingLeaderStatus
                        ? "กำลังตรวจสอบบทบาท..."
                        : (_buddyTeamId == null
                              ? "ยังไม่ได้จับคู่"
                              : (_isLeader
                                    ? "Leader (หัวหน้าทีม)"
                                    : "Follower (บัดดี้)")),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. ป้ายแสดงรายละเอียด Marker เมื่อถูกสัมผัสแตะ
          if (_selectedPlaceName != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF2340A7), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedPlaceName!,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedPlaceAddress != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _selectedPlaceAddress!,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _selectedPlaceName = null;
                          _selectedPlaceAddress = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // 3. ปุ่มเข็มทิศ / ตำแหน่งปัจจุบัน (ขวาล่างด้านบนปุ่ม Offline/การรับงาน)
          Positioned(
            bottom: _isJobOfferOpen
                ? 410
                : (_hasActiveJob ? (_isJobSheetCollapsed ? 120 : 410) : 120),
            right: 20,
            child: GestureDetector(
              onTap: () {
                if (_currentPosition != null) {
                  _addDriverMarkerAt(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    showSnackBar: true,
                  );
                } else {
                  _initLocation();
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: 0.785398, // หมุนเอียง 45 องศาให้ชี้บนขวา
                  child: const Icon(
                    Icons.navigation,
                    color: Color(0xFF2340A7),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // ปุ่มศูนย์ความปลอดภัย (แสดงเมื่อมีงานเสนอเข้ามา หรือมีงานปัจจุบัน)
          if (_isJobOfferOpen || _hasActiveJob)
            Positioned(
              bottom: _isJobOfferOpen
                  ? 410
                  : (_hasActiveJob ? (_isJobSheetCollapsed ? 120 : 410) : 120),
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Color(0xFF2340A7), size: 18),
                    SizedBox(width: 6),
                    Text(
                      "ศูนย์ความปลอดภัย",
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. แถบปุ่ม Offline/Online และ ปุ่มค้นหา Buddy หรือ Bottom Sheet รับงานใหม่ หรือ Bottom Sheet งานปัจจุบัน
          if (!_isJobOfferOpen && !_hasActiveJob)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOnlineOfflineButton(),
                  const SizedBox(width: 16),
                  _buildBuddyButton(),
                ],
              ),
            )
          else if (_hasActiveJob)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _isLadyMode
                      ? const Color(0xFFFFF5F7)
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: _isLadyMode
                      ? Border.all(color: const Color(0xFFFFB6C1), width: 1.5)
                      : Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: _isLadyMode
                          ? const Color(0xFFFF1493).withOpacity(0.15)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ขีดสำหรับลากดึง/แตะเพื่อย่อ-ขยาย
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isJobSheetCollapsed = !_isJobSheetCollapsed;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _isLadyMode
                                ? const Color(0xFFFF69B4)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // แถบหัวข้อสถานะ พร้อมปุ่มย่อ/ขยาย
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isJobSheetCollapsed = !_isJobSheetCollapsed;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isLadyMode
                                  ? const Color(0xFFFFE4E1)
                                  : const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _currentJobStatus == 'going to pickup'
                                  ? Icons.directions_car_rounded
                                  : (_currentJobStatus == 'arrived'
                                        ? Icons.access_time_filled_rounded
                                        : Icons.navigation_rounded),
                              color: _isLadyMode
                                  ? const Color(0xFFFF1493)
                                  : const Color(0xFF2340A7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _currentJobStatus == 'going to pickup'
                                  ? "กำลังไปรับลูกค้า"
                                  : (_currentJobStatus == 'arrived'
                                        ? "ถึงจุดนัดหมายแล้ว (รอลูกค้า)"
                                        : "กำลังเดินทางไปส่งลูกค้า"),
                              style: TextStyle(
                                color: _isLadyMode
                                    ? const Color(0xFFBE185D)
                                    : const Color(0xFF1E293B),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isJobSheetCollapsed
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF64748B),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLadyMode) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFB6C1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.female, color: Color(0xFFFF1493), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Lady Mode (สำหรับผู้หญิง)",
                              style: TextStyle(
                                color: Color(0xFFFF1493),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!_isJobSheetCollapsed) ...[
                      const SizedBox(height: 16),

                      // ข้อมูลลูกค้า
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFE2E8F0),
                              backgroundImage:
                                  (_clientProfileImage != null &&
                                      _clientProfileImage!.isNotEmpty)
                                  ? NetworkImage(_clientProfileImage!)
                                  : null,
                              child:
                                  (_clientProfileImage == null ||
                                      _clientProfileImage!.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      size: 26,
                                      color: Color(0xFF94A3B8),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _clientName ?? "คุณลูกค้า",
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                debugPrint("Calling customer: $_clientPhone");
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2340A7),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2340A7).withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (_isPubJob) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "ไม่สามารถรายงานลูกค้าเนื่องจากเป็นคำขอจากสถานบันเทิง (Pub)",
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                if (_activeRequestId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportUserPage(
                                        requestId: _activeRequestId,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("ไม่พบข้อมูลคำขอที่จะรายงาน"),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: const Icon(
                                  Icons.report_problem_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // เส้นทางจุดเริ่มต้นและจุดหมายปลายทาง
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.radio_button_checked_rounded,
                                  color: Color(0xFFF97316),
                                  size: 20,
                                ),
                                Container(
                                  width: 2,
                                  height: 40,
                                  color: const Color(0xFFCBD5E1),
                                ),
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickupName ?? "จุดรับผู้โดยสาร",
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${(_jobDistance ?? '0.0').replaceAll(RegExp(r'\s*km', caseSensitive: false), '')} กม. • ประมาณ ${_jobDuration ?? '15 นาที'}",
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _dropoffName ?? "จุดส่งผู้โดยสาร",
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ปุ่มกดแสดงสถานะ (สไลด์เพื่อยืนยัน)
                      SlideActionBtn(
                        text: _currentJobStatus == 'going to pickup'
                            ? "ถึงจุดนัดหมาย"
                            : (_currentJobStatus == 'arrived'
                                  ? "เริ่มเดินทาง"
                                  : "สิ้นสุดการเดินทาง"),
                        onConfirmed: () async {
                          if (_currentJobStatus == 'going to pickup') {
                            try {
                              await Supabase.instance.client
                                  .from(
                                    _isPubJob
                                        ? 'requestbypub'
                                        : 'requestbyuser',
                                  )
                                  .update({'requeststatus': 'ถึงจุดนัดหมาย'})
                                  .eq('requestid', _activeRequestId);

                              _teamChannel?.send(
                                type: RealtimeListenTypes.broadcast,
                                event: 'job_status_updated',
                                payload: {'status': 'ถึงจุดนัดหมาย'},
                              );
                            } catch (e) {
                              debugPrint("Error updating request status: $e");
                            }
                            setState(() {
                              _currentJobStatus = 'arrived';
                            });
                          } else if (_currentJobStatus == 'arrived') {
                            try {
                              await Supabase.instance.client
                                  .from(
                                    _isPubJob
                                        ? 'requestbypub'
                                        : 'requestbyuser',
                                  )
                                  .update({'requeststatus': 'กำลังเดินทาง'})
                                  .eq('requestid', _activeRequestId);

                              _teamChannel?.send(
                                type: RealtimeListenTypes.broadcast,
                                event: 'job_status_updated',
                                payload: {'status': 'กำลังเดินทาง'},
                              );
                            } catch (e) {
                              debugPrint("Error updating request status: $e");
                            }
                            setState(() {
                              _currentJobStatus = 'in progress';
                            });
                          } else if (_currentJobStatus == 'in progress') {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FinishJobPage(
                                  requestId: _activeRequestId,
                                  buddyTeamId: _buddyTeamId,
                                  isPubJob: _isPubJob,
                                  distance: _jobDistance,
                                  fare: _jobFee,
                                  paymentMethod: _paymentMethod,
                                ),
                              ),
                            );

                            if (result == true) {
                              try {
                                _teamChannel?.send(
                                  type: RealtimeListenTypes.broadcast,
                                  event: 'job_status_updated',
                                  payload: {'status': 'เสร็จสิ้น'},
                                );
                              } catch (e) {
                                debugPrint(
                                  "Error broadcasting job completion: $e",
                                );
                              }

                              setState(() {
                                _clearJobState();
                                _currentPosition = null;
                                _initLocation();
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: _isLadyMode
                      ? const Color(0xFFFFF5F7)
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: _isLadyMode
                      ? Border.all(color: const Color(0xFFFFB6C1), width: 1.5)
                      : Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: _isLadyMode
                          ? const Color(0xFFFF1493).withOpacity(0.18)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ขีดสำหรับลากดึง
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _isLadyMode
                            ? const Color(0xFFFF69B4)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // หัวข้อ
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isLadyMode
                                      ? const Color(0xFFFFE4E1)
                                      : const Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  color: _isLadyMode
                                      ? const Color(0xFFFF1493)
                                      : const Color(0xFF2340A7),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isLadyMode
                                    ? "🌸 มีงานใหม่ (Lady Mode)!"
                                    : "มีงานใหม่เข้ามา!",
                                style: TextStyle(
                                  color: _isLadyMode
                                      ? const Color(0xFFBE185D)
                                      : const Color(0xFF1E293B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                color: Color(0xFF2563EB),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _jobDistance ?? "0.0 km",
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isLadyMode) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFB6C1)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.female, color: Color(0xFFFF1493), size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Lady Mode (สำหรับผู้หญิงเท่านั้น)",
                                style: TextStyle(
                                  color: Color(0xFFFF1493),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Card 1: ข้อมูลลูกค้า
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage:
                                (_clientProfileImage != null &&
                                    _clientProfileImage!.isNotEmpty)
                                ? NetworkImage(_clientProfileImage!)
                                : null,
                            child:
                                (_clientProfileImage == null ||
                                    _clientProfileImage!.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Color(0xFF94A3B8),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _clientName ?? "ลูกค้าทั่วไป",
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              debugPrint("Calling customer: $_clientPhone");
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2340A7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2340A7).withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 2: รายละเอียดรถ, ราคา, เกียร์ ในกล่องเดียว
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // ข้อมูลรถยนต์
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.directions_car_rounded,
                                  color: Color(0xFF2340A7),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _carDetails ?? "รถยนต์ส่วนบุคคล",
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _carSubdetails ?? "ไม่ทราบรายละเอียดรถ",
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),

                          // ข้อมูลราคา/วิธีการจ่ายเงิน + ข้อมูลเกียร์
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ราคา
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFF059669),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _jobFee ?? "0.00 บาท",
                                        style: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _paymentMethod ?? "App Wallet",
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // เกียร์
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      (_gearType != null && _gearType!.contains("EV"))
                                          ? Icons.electric_car_rounded
                                          : Icons.settings_rounded,
                                      color: const Color(0xFF2340A7),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _gearType ?? "Auto Gear",
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ปุ่มกด Accept / Denial
                    Row(
                      children: [
                        // ปุ่มปฏิเสธ
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              if (_teamChannel != null) {
                                try {
                                  _teamChannel!.sendBroadcastMessage(
                                    event: 'job_denied',
                                    payload: {
                                      'requestid': _activeRequestId,
                                      'denied_by': _currentUsername ?? '',
                                    },
                                  );
                                } catch (e) {
                                  debugPrint("Failed to broadcast job_denied: $e");
                                }
                              }
                              setState(() {
                                _isJobOfferOpen = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              backgroundColor: const Color(0xFFFEF2F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "ปฏิเสธ",
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ปุ่มรับงาน
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_activeRequestId != null) {
                                _acceptTeamJob(_activeRequestId);
                              }
                              setState(() {
                                _isJobOfferOpen = false;
                              });
                            },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              "รับงานทันที",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2340A7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // แท็บ Home ในปัจจุบัน
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2340A7), // Primary Brand #2340A7
        unselectedItemColor: const Color(0xFF94A3B8), // Slate 400
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        onTap: (index) async {
          if (index == 0) return; // อยู่หน้า Home แล้วไม่ต้องทำอะไร
          String? username = await SessionManager.getUsername();
          if (username == null) return;

          if (index == 1) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletBalancePage(username: username),
                ),
              );
            }
          } else if (index == 2) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceSummaryPage(username: username),
                ),
              );
            }
          } else if (index == 3) {
            String? phoneNo = await SessionManager.getPhoneNo();
            if (phoneNo != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfilePage(username: username, phoneno: phoneNo),
                ),
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class SlideActionBtn extends StatefulWidget {
  final String text;
  final VoidCallback onConfirmed;
  const SlideActionBtn({
    super.key,
    required this.text,
    required this.onConfirmed,
  });

  @override
  State<SlideActionBtn> createState() => _SlideActionBtnState();
}

class _SlideActionBtnState extends State<SlideActionBtn> {
  double _dragPosition = 0.0;
  final double _buttonHeight = 60.0;
  final double _sliderWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDragDistance = constraints.maxWidth - _sliderWidth;

        return Container(
          height: _buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFD6D6D6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Text in the center
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 40.0,
                  ), // give space for the green button
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Slideable button
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition += details.primaryDelta!;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDragDistance)
                        _dragPosition = maxDragDistance;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition >= maxDragDistance * 0.8) {
                      setState(() {
                        _dragPosition = maxDragDistance;
                      });
                      widget.onConfirmed();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0.0;
                          });
                        }
                      });
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: _sliderWidth,
                    height: _buttonHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF33),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
