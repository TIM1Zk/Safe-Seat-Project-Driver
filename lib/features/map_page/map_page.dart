
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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  bool isSatelliteMode = false;
  bool isMapReady = false;
  bool isOnline = false;
  bool _isLeader = true;
  bool _isLoadingLeaderStatus = true;
  int? _buddyTeamId;
  Timer? _locationUpdateTimer;
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
  String _currentJobStatus = 'going to pickup';
  bool _isPubJob = false;
  String? _pickupName;
  String? _dropoffName;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;

  Position? _currentPosition;
  String _currentAddress = "กำลังดึงข้อมูลที่อยู่พิกัด GPS ปัจจุบัน...";


  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  String? _selectedPlaceName;
  String? _selectedPlaceAddress;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _locationUpdateTimer?.cancel();
    _teamChannel?.unsubscribe();
    _activeJobChannel?.unsubscribe();
    _teamStatusSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLeaderStatus() async {
    try {
      String? username = await SessionManager.getUsername();
      if (username != null) {
        final response = await ApiService.get('/buddy-team/active/$username');
        if (response.statusCode == 200 && response.data != null && response.data.toString().isNotEmpty && response.data.toString() != "null") {
          final data = response.data;
          if (data is Map && data.isNotEmpty) {
            String leaderId = data['leaderid'].toString().toLowerCase();
            int? teamId;
            if (data['buddyteamid'] != null) {
              teamId = int.tryParse(data['buddyteamid'].toString());
            }
            if (mounted) {
              setState(() {
                _isLeader = (leaderId == username.toLowerCase());
                _buddyTeamId = teamId;
              });
              if (_buddyTeamId != null) {
                _setupRealtimeListeners(_buddyTeamId!);
              }
            }
          } else {
             if (mounted) setState(() => _isLeader = true);
          }
        } else {
           if (mounted) setState(() => _isLeader = true);
        }
      }
    } catch (e) {
       debugPrint("Error checking leader status: $e");
       if (mounted) setState(() => _isLeader = true);
    } finally {
       if (mounted) setState(() => _isLoadingLeaderStatus = false);
    }
  }

  void _setupRealtimeListeners(int teamId) {
    final supabase = Supabase.instance.client;
    debugPrint("[SafeSeat debug] Setting up Realtime listeners for teamId: $teamId");
    
    // 1. Listen for Broadcast (New Job Offers, Accepts, and Status Updates)
    _teamChannel = supabase.channel('team_room_$teamId');
    _teamChannel!.onBroadcast(
      event: 'new_job_dispatched',
      callback: (payload) {
        debugPrint("[SafeSeat debug] Received broadcast new_job_dispatched with payload: $payload");
        if (payload != null) {
          _showNewJobOfferDialog(payload);
        }
      },
    ).onBroadcast(
      event: 'job_accepted',
      callback: (payload) {
        debugPrint("[SafeSeat debug] Received broadcast job_accepted with payload: $payload");
        if (payload != null && mounted) {
          _closeJobOfferDialog();
          
          final innerPayload = (payload.containsKey('payload') && payload['payload'] is Map)
              ? Map<String, dynamic>.from(payload['payload'] as Map)
              : payload;
              
          final reqId = innerPayload['requestid'];
          final jobData = innerPayload['job'];
          final isPub = innerPayload['isPubJob'] == true || (jobData != null && jobData['pub_id'] != null);
          
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
              _pickupLat = double.tryParse(jobData['pickuplatitude']?.toString() ?? '') ?? _currentPosition?.latitude ?? 13.7563;
              _pickupLng = double.tryParse(jobData['pickuplongitude']?.toString() ?? '') ?? _currentPosition?.longitude ?? 100.5018;
              _dropoffLat = double.tryParse(jobData['dropofflatitude']?.toString() ?? '') ?? (_pickupLat! - 0.02);
              _dropoffLng = double.tryParse(jobData['dropofflongitude']?.toString() ?? '') ?? (_pickupLng! + 0.02);
            }
            
            _isJobOfferOpen = false;
            _updateJobMarkers();
          });
        }
      },
    ).onBroadcast(
      event: 'job_status_updated',
      callback: (payload) {
        debugPrint("[SafeSeat debug] Received broadcast job_status_updated with payload: $payload");
        if (payload != null && mounted) {
          final innerPayload = (payload.containsKey('payload') && payload['payload'] is Map)
              ? Map<String, dynamic>.from(payload['payload'] as Map)
              : payload;
              
          final newStatus = innerPayload['status']?.toString();
          
          setState(() {
            if (newStatus == 'arrived' || newStatus == 'ถึงจุดนัดหมาย') {
              _currentJobStatus = 'arrived';
            } else if (newStatus == 'in progress' || newStatus == 'กำลังเดินทาง') {
              _currentJobStatus = 'in progress';
            } else if (newStatus == 'completed' || newStatus == 'เสร็จสิ้น') {
              _hasActiveJob = false;
              _activeRequestId = null;
              _polylines = [];
              _initLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("งานนี้เดินทางเสร็จสิ้นแล้ว!")),
              );
            }
          });
        }
      },
    ).subscribe((status, [error]) {
      debugPrint("[SafeSeat debug] Channel team_room_$teamId status: $status, error: $error");
    });

    // On initialization, fetch the current active job if the team is already busy
    _fetchActiveJobForTeam(teamId);

    // 2. Listen for Team Status changes (if partner accepts job or toggles online status)
    _teamStatusSubscription = supabase
        .from('buddyteam')
        .stream(primaryKey: ['buddyteamid'])
        .eq('buddyteamid', teamId)
        .listen((List<Map<String, dynamic>> data) {
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
                _hasActiveJob = false;
                _activeRequestId = null;
                _polylines = [];
                _activeJobChannel?.unsubscribe();
                _activeJobChannel = null;
                _initLocation();
              }
            } else if (status == 'Offline') {
              isOnline = false;
              if (_hasActiveJob) {
                _hasActiveJob = false;
                _activeRequestId = null;
                _polylines = [];
                _activeJobChannel?.unsubscribe();
                _activeJobChannel = null;
                _initLocation();
              }
            }
          });
        }
      }
    }, onError: (error) {
      debugPrint("[SafeSeat debug] Realtime stream error on buddyteam: $error");
    });
  }

  void _setupActiveJobListener(dynamic requestId, bool isPub) {
    _activeJobChannel?.unsubscribe();
    
    final supabase = Supabase.instance.client;
    _activeJobChannel = supabase.channel('active_job_$requestId');
    _activeJobChannel!.onPostgresChanges(
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
            } else if (dbStatus == 'in progress' || dbStatus == 'กำลังเดินทาง') {
              _currentJobStatus = 'in progress';
            } else if (dbStatus == 'completed' || dbStatus == 'เสร็จสิ้น') {
              _hasActiveJob = false;
              _activeRequestId = null;
              _polylines = [];
              _activeJobChannel?.unsubscribe();
              _activeJobChannel = null;
              _initLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("งานนี้เดินทางเสร็จสิ้นแล้ว!")),
              );
            }
          });
        }
      },
    ).subscribe();
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
            } else if (dbStatus == 'in progress' || dbStatus == 'กำลังเดินทาง') {
              _currentJobStatus = 'in progress';
            }
            
            _pickupName = "จุดนัดหมายลูกค้า";
            _dropoffName = "จุดหมายปลายทาง";
            _pickupLat = double.tryParse(jobData['pickuplatitude']?.toString() ?? '') ?? _currentPosition?.latitude ?? 13.7563;
            _pickupLng = double.tryParse(jobData['pickuplongitude']?.toString() ?? '') ?? _currentPosition?.longitude ?? 100.5018;
            _dropoffLat = double.tryParse(jobData['dropofflatitude']?.toString() ?? '') ?? (_pickupLat! - 0.02);
            _dropoffLng = double.tryParse(jobData['dropofflongitude']?.toString() ?? '') ?? (_pickupLng! + 0.02);
            
            _isJobOfferOpen = false;
            _updateJobMarkers();
          });
        }
      }
    } catch (e) {
      debugPrint("[SafeSeat] Error fetching active job: $e");
    }
  }

  void _startLocationUpdater() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      // If we don't have a team ID yet, periodically check it
      if (_buddyTeamId == null) {
        await _checkLeaderStatus();
      }

      // Only Leader updates location, and only when matched
      if (_isLeader && _buddyTeamId != null) {
        try {
          Position? position;
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {}

          if (position == null) {
            try {
              position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.low,
                  timeLimit: Duration(seconds: 5),
                ),
              );
            } catch (_) {
              position = _currentPosition;
            }
          }

          if (position != null) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
                _currentAddress = "พิกัด: ${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}";
              });
            }

            await Supabase.instance.client
                .from('buddyteam')
                .update({
                  'currentloclat': position.latitude,
                  'currentloclng': position.longitude,
                })
                .eq('buddyteamid', _buddyTeamId!);
          }
        } catch (e) {
          debugPrint("Failed to update team location: $e");
        }
      }
    });
  }

  Future<void> _forceUpdateLocation() async {
    if (!_isLeader) {
      debugPrint("Not a leader. Cannot update GPS.");
      return;
    }
    if (_buddyTeamId == null) {
      debugPrint("BuddyTeamId is null. Cannot update GPS.");
      return;
    }
    
    // พยายามดึงพิกัดใหม่ถ้ายังไม่มี
    if (_currentPosition == null) {
      try {
        _currentPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      if (_currentPosition == null) {
        try {
          _currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (e) {
          debugPrint("Failed to fetch GPS during force update: $e");
          return;
        }
      }
    }

    if (_currentPosition != null) {
      try {
        await Supabase.instance.client
            .from('buddyteam')
            .update({
              'currentloclat': _currentPosition!.latitude,
              'currentloclng': _currentPosition!.longitude,
            })
            .eq('buddyteamid', _buddyTeamId!);
        debugPrint("Forced GPS update to DB successful.");
      } catch (e) {
        debugPrint("Failed to force update team location: $e");
      }
    }
  }

  Future<void> _fetchJobOfferDetails(Map<String, dynamic> payload, bool isPub) async {
    try {
      final supabase = Supabase.instance.client;
      
      if (isPub) {
        setState(() {
          _clientName = payload['custname']?.toString() ?? 'ลูกค้าทั่วไป';
          _clientProfileImage = null;
          _clientPhone = payload['phoneno']?.toString() ?? '';
          _isLadyMode = payload['isladymode'] == true || payload['isladymode']?.toString() == 'true';

          final note = payload['note']?.toString() ?? '';
          
          // ดึงข้อมูลรุ่นรถและทะเบียนจาก note หากมีรูปแบบ [รุ่นรถ: ... | ทะเบียน: ...]
          String parsedCarInfo = "";
          String customNote = note;
          if (note.contains('[รุ่นรถ:') && note.contains(']')) {
            final match = RegExp(r'\[รุ่นรถ:\s*(.*?)\s*\|\s*ทะเบียน:\s*(.*?)\]').firstMatch(note);
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
          } else if (carType == '2') {
            _carDetails = "SUV / รถขนาดใหญ่";
          } else {
            _carDetails = "Sedan / รถเก๋ง";
          }

          final phoneEmer = payload['phoneemer']?.toString() ?? '';
          _carSubdetails = customNote.isNotEmpty 
              ? "หมายเหตุ: $customNote" 
              : "เบอร์ติดต่อฉุกเฉิน: ${phoneEmer.isNotEmpty ? phoneEmer : 'ไม่มี'}";

          final fee = payload['requestfee'];
          if (fee != null) {
            final feeDouble = double.tryParse(fee.toString());
            _jobFee = feeDouble != null ? "${feeDouble.toStringAsFixed(2)} บาท" : "${fee.toString()} บาท";
          } else {
            _jobFee = "0.00 บาท";
          }

          final payMethod = payload['paymentmethod'];
          if (payMethod == 2 || payMethod.toString().toLowerCase().contains('wallet')) {
            _paymentMethod = "App Wallet";
          } else {
            _paymentMethod = "เงินสด (Cash)";
          }

          if (note.toLowerCase().contains('auto')) {
            _gearType = "Auto Gear";
          } else if (note.toLowerCase().contains('manual') || note.toLowerCase().contains('ธรรมดา')) {
            _gearType = "Manual Gear";
          } else {
            _gearType = "Auto / Manual Gear";
          }
          
          final dist = payload['reqdistance'];
          if (dist != null) {
            final distDouble = double.tryParse(dist.toString());
            _jobDistance = distDouble != null ? "${distDouble.toStringAsFixed(2)} km" : "${dist.toString()} km";
          } else {
            _jobDistance = "0.0 km";
          }

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

      // 2. ดึงข้อมูลรถยนต์ (usercar)
      Map<String, dynamic>? carData;
      if (userCarId != null) {
        final carRes = await supabase
            .from('usercar')
            .select('carbrand, carcolor, carmodel, carplate')
            .eq('usercarid', userCarId)
            .maybeSingle();
        carData = carRes;
      }

      setState(() {
        _clientName = userData?['name']?.toString() ?? 'ลูกค้าทั่วไป';
        _clientProfileImage = userData?['profileimagepath']?.toString();
        _clientPhone = userData?['phoneno']?.toString() ?? userId;
        _isLadyMode = payload['isladymode'] == true || payload['isladymode']?.toString() == 'true';

        if (carData != null) {
          final brand = carData['carbrand']?.toString() ?? '';
          final model = carData['carmodel']?.toString() ?? '';
          _carDetails = "$brand $model".trim();
          if (_carDetails!.isEmpty) _carDetails = "รถยนต์ส่วนบุคคล";
          
          final color = carData['carcolor']?.toString() ?? '';
          final plate = carData['carplate']?.toString() ?? '';
          _carSubdetails = "${color.isNotEmpty ? 'สี$color' : ''} ทะเบียน ${plate.isNotEmpty ? plate : 'ไม่ระบุ'}".trim();
        } else {
          _carDetails = "รถยนต์ส่วนบุคคล";
          _carSubdetails = "ไม่ทราบรายละเอียดรถ";
        }

        final fee = payload['requestfee'];
        if (fee != null) {
          final feeDouble = double.tryParse(fee.toString());
          _jobFee = feeDouble != null ? "${feeDouble.toStringAsFixed(2)} บาท" : "${fee.toString()} บาท";
        } else {
          _jobFee = "0.00 บาท";
        }

        final payMethod = payload['paymentmethod'];
        if (payMethod == 2 || payMethod.toString().toLowerCase().contains('wallet')) {
          _paymentMethod = "App Wallet";
        } else {
          _paymentMethod = "เงินสด (Cash)";
        }

        // ระบบเกียร์
        final note = payload['note']?.toString() ?? '';
        if (note.toLowerCase().contains('auto')) {
          _gearType = "Auto Gear";
        } else if (note.toLowerCase().contains('manual') || note.toLowerCase().contains('ธรรมดา')) {
          _gearType = "Manual Gear";
        } else {
          _gearType = "Manual Gear"; // ค่าเริ่มต้นตามแบบร่าง
        }

        final dist = payload['reqdistance'];
        if (dist != null) {
          final distDouble = double.tryParse(dist.toString());
          _jobDistance = distDouble != null ? "${distDouble.toStringAsFixed(2)} km" : "${dist.toString()} km";
        } else {
          _jobDistance = "0.0 km";
        }

        _activeRequestId = payload['requestid'];
        _isJobOfferOpen = true;
      });
    } catch (e) {
      debugPrint("Error fetching job offer details: $e");
      setState(() {
        _clientName = "ลูกค้าทั่วไป";
        _clientPhone = payload['user_id']?.toString();
        _carDetails = "รถยนต์ส่วนบุคคล";
        _carSubdetails = "ไม่ทราบรายละเอียดรถ";
        
        final fee = payload['requestfee'];
        if (fee != null) {
          final feeDouble = double.tryParse(fee.toString());
          _jobFee = feeDouble != null ? "${feeDouble.toStringAsFixed(2)} บาท" : "${fee.toString()} บาท";
        } else {
          _jobFee = "0.00 บาท";
        }
        
        _paymentMethod = "App Wallet";
        _gearType = "Manual Gear";
        
        final dist = payload['reqdistance'];
        if (dist != null) {
          final distDouble = double.tryParse(dist.toString());
          _jobDistance = distDouble != null ? "${distDouble.toStringAsFixed(2)} km" : "${dist.toString()} km";
        } else {
          _jobDistance = "0.0 km";
        }
        
        _activeRequestId = payload['requestid'];
        _isJobOfferOpen = true;
      });
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

    final isPub = actualPayload['isPubJob'] == true || actualPayload['pub_id'] != null;
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
        const SnackBar(content: Text("บัดดี้ของคุณรับงานนี้แล้ว กำลังเข้าสู่โหมดนำทาง")),
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
        content: Text("ส่งสัญญาณทดสอบรับงาน Lady Mode ไปยังทุกคนในทีมเรียบร้อยแล้ว"),
        backgroundColor: Color(0xFFFF1493),
        duration: Duration(seconds: 2),
      ),
    );
  }


  Future<List<LatLng>> _getOSRMRoute(LatLng start, LatLng end) async {
    try {
      final url = "https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson";
      final dio = Dio();
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            return coords.map((c) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint("[SafeSeat OSRM] Error fetching route: $e");
    }
    // Fallback to straight line if OSRM fails
    return [start, end];
  }

  Future<void> _updateJobMarkers() async {
    List<Marker> jobMarkers = [];
    List<Polyline> jobPolylines = [];
    
    // 1. Driver Marker
    if (_currentPosition != null) {
      jobMarkers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 80,
          height: 80,
          child: Transform.rotate(
            angle: 0.785398,
            child: const Icon(Icons.navigation, color: Colors.blue, size: 40),
          ),
        ),
      );
    }
    
    // 2. Pickup Marker
    if (_pickupLat != null && _pickupLng != null) {
      jobMarkers.add(
        Marker(
          point: LatLng(_pickupLat!, _pickupLng!),
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, color: Colors.green, size: 48),
        ),
      );
    }
    
    // 3. Dropoff Marker
    if (_dropoffLat != null && _dropoffLng != null) {
      jobMarkers.add(
        Marker(
          point: LatLng(_dropoffLat!, _dropoffLng!),
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, color: Colors.red, size: 48),
        ),
      );
    }
    
    setState(() {
      _markers = jobMarkers;
    });

    // Move map camera to show pickup point
    if (_pickupLat != null && _pickupLng != null) {
      _moveToCoordinates(_pickupLat!, _pickupLng!, zoom: 14);
    }

    // Generate route line (polylines) using OSRM
    List<LatLng> driverToPickup = [];
    if (_currentPosition != null && _pickupLat != null && _pickupLng != null) {
      driverToPickup = await _getOSRMRoute(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(_pickupLat!, _pickupLng!),
      );
    }
    
    List<LatLng> pickupToDropoff = [];
    if (_pickupLat != null && _pickupLng != null && _dropoffLat != null && _dropoffLng != null) {
      pickupToDropoff = await _getOSRMRoute(
        LatLng(_pickupLat!, _pickupLng!),
        LatLng(_dropoffLat!, _dropoffLng!),
      );
    }

    if (driverToPickup.isNotEmpty) {
      jobPolylines.add(
        Polyline(
          points: driverToPickup,
          color: const Color(0xFF3B82F6), // Material Blue
          strokeWidth: 4.5,
        ),
      );
    }
    
    if (pickupToDropoff.isNotEmpty) {
      jobPolylines.add(
        Polyline(
          points: pickupToDropoff,
          color: const Color(0xFF10B981), // Emerald Green
          strokeWidth: 4.5,
        ),
      );
    }
    
    if (mounted) {
      setState(() {
        _polylines = jobPolylines;
      });
    }
  }

  Future<void> _acceptTeamJob(dynamic requestId) async {
    debugPrint("[SafeSeat debug] _acceptTeamJob called with requestId: $requestId, _buddyTeamId: $_buddyTeamId");
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รับงานจำลองสำเร็จ!')),
        );
      }
      return;
    }

    try {
      if (_buddyTeamId == null) {
        debugPrint("[SafeSeat debug] _buddyTeamId is null! Cannot accept job.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('รับงานล้มเหลว: ไม่พบข้อมูลทีมคนขับในเครื่อง (buddyTeamId is null)')),
          );
        }
        return;
      }
      
      final response = await ApiService.post('/buddy-team/accept-job', data: {
        'request_id': requestId,
        'buddy_team_id': _buddyTeamId,
        'is_pub_job': _isPubJob,
      });
      
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
              _pickupLat = double.tryParse(jobData['pickuplatitude']?.toString() ?? '') ?? _currentPosition?.latitude ?? 13.7563;
              _pickupLng = double.tryParse(jobData['pickuplongitude']?.toString() ?? '') ?? _currentPosition?.longitude ?? 100.5018;
              _dropoffLat = double.tryParse(jobData['dropofflatitude']?.toString() ?? '') ?? (_pickupLat! - 0.02);
              _dropoffLng = double.tryParse(jobData['dropofflongitude']?.toString() ?? '') ?? (_pickupLng! + 0.02);
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
            SnackBar(content: Text(response.data['message'] ?? 'รับงานไม่สำเร็จ (อาจมีคนรับไปแล้ว)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์')),
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

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {

        // ดึงตำแหน่งประวัติล่าสุดแบบรวดเร็ว
        Position? position = await Geolocator.getLastKnownPosition();
        
        // ดึงตำแหน่งสดด้วยความแม่นยำต่ำเพื่อความชัวร์และเร็วสูงสุดบน Emulator (พร้อม Fallback กรณี Timeout)
        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 4),
              ),
            );
          } catch (e) {
            debugPrint("[SafeSeat Mapbox] Timeout/Error fetching live position, fallback to default: $e");
            // Fallback location (Bangkok default coordinates) so app won't hang
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
        }

        String address = "พิกัด: " + position.latitude.toStringAsFixed(5) + ", " + position.longitude.toStringAsFixed(5);

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _currentAddress = address;
          });

          // ย้ายกล้องไปที่ตำแหน่งจริงของเครื่องทันที
          _moveToCoordinates(position.latitude, position.longitude, zoom: 15);
          _addDriverMarkerAt(position.latitude, position.longitude, showSnackBar: false);
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

  void _addDriverMarkerAt(double lat, double lon, {bool showSnackBar = true}) async {
    final address = "พิกัด: " + lat.toStringAsFixed(5) + ", " + lon.toStringAsFixed(5);
    
    setState(() {
      _currentAddress = address;
      
      _markers = [
        Marker(
          point: LatLng(lat, lon),
          width: 80,
          height: 80,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 48,
          ),
        )
      ];
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
      buttonColor = isOnline ? const Color(0xFF22C55E) : const Color(0xFF1E1F22);
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
            const SnackBar(content: Text("เฉพาะหัวหน้าทีมเท่านั้นที่สามารถกด Online ได้")),
          );
          return;
        }

        if (!isOnline) { // กำลังจะเปิด Online
          if (_buddyTeamId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("กรุณาจับคู่เพื่อนร่วมทางก่อนเข้าสู่สถานะออนไลน์")),
            );
            String? username = await SessionManager.getUsername();
            if (username != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchbuddyPage(currentUsername: username),
                ),
              );
            }
            return;
          }
        }

        final newOnlineState = !isOnline;
        
        // Update database teamstatus
        if (_buddyTeamId != null) {
          try {
            await Supabase.instance.client
                .from('buddyteam')
                .update({
                  'teamstatus': newOnlineState ? 'Ready' : 'Offline',
                })
                .eq('buddyteamid', _buddyTeamId!);
          } catch (e) {
            debugPrint("Failed to update team status in DB: $e");
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
            const Icon(
              Icons.power_settings_new,
              color: Colors.white,
              size: 24,
            ),
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
              initialCenter: const LatLng(13.7563, 100.5018), // กรุงเทพฯ เป็นค่าเริ่มต้น
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
              PolylineLayer(
                polylines: _polylines,
              ),
              MarkerLayer(
                markers: _markers,
              ),
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
                          : (_isLeader ? const Color(0xFF7CE5FF) : const Color(0xFFFFB300))),
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
                            : (_isLeader ? Icons.stars : Icons.supervised_user_circle)),
                    color: _isLoadingLeaderStatus 
                        ? Colors.grey 
                        : (_buddyTeamId == null
                            ? Colors.grey
                            : (_isLeader ? const Color(0xFF7CE5FF) : const Color(0xFFFFB300))),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLoadingLeaderStatus
                        ? "กำลังตรวจสอบบทบาท..."
                        : (_buddyTeamId == null
                            ? "ยังไม่ได้จับคู่"
                            : (_isLeader ? "Leader (หัวหน้าทีม)" : "Follower (บัดดี้)")),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7CE5FF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFF1E1E1E), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedPlaceName!,
                            style: const TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedPlaceAddress != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _selectedPlaceAddress!,
                              style: const TextStyle(
                                color: Color(0xFF333333),
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
                      icon: const Icon(Icons.close, color: Color(0xFF1E1E1E), size: 18),
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
            bottom: (_isJobOfferOpen || _hasActiveJob) ? 410 : 120,
            right: 20,
            child: GestureDetector(
              onTap: () {
                if (_currentPosition != null) {
                  _addDriverMarkerAt(_currentPosition!.latitude, _currentPosition!.longitude, showSnackBar: true);
                } else {
                  _initLocation();
                }
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: 0.785398, // หมุนเอียง 45 องศาให้ชี้บนขวา
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),


          // ปุ่มศูนย์ความปลอดภัย (แสดงเมื่อมีงานเสนอเข้ามา หรือมีงานปัจจุบัน)
          if (_isJobOfferOpen || _hasActiveJob)
            Positioned(
              bottom: 410,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0C0C0),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "ศูนย์ความปลอดภัย",
                      style: TextStyle(
                        color: Colors.black,
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
              child: Container(
                decoration: BoxDecoration(
                  color: _isLadyMode ? const Color(0xFFFFF0F5) : const Color(0xFFB2B2B2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: _isLadyMode ? Border.all(color: const Color(0xFFFF69B4), width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: _isLadyMode ? const Color(0xFFFF1493).withOpacity(0.3) : Colors.black26,
                      blurRadius: 12,
                      spreadRadius: 3,
                    )
                  ],
                ),
                padding: const EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ขีดสำหรับลากดึง
                    Center(
                      child: Container(
                        width: 80,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isLadyMode ? const Color(0xFFFF1493) : const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Text(
                      _currentJobStatus == 'going to pickup'
                          ? "กำลังไปรับลูกค้า"
                          : (_currentJobStatus == 'arrived' ? "ถึงจุดนัดหมายแล้ว (รอลูกค้า)" : "กำลังเดินทางไปส่งลูกค้า"),
                      style: TextStyle(
                        color: _isLadyMode ? const Color(0xFFC71585) : const Color(0xDD000000),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLadyMode) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40FF1493),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.female, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "🌸 Lady Mode (สำหรับผู้หญิงเท่านั้น)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),

                    // ข้อมูลลูกค้า
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage: (_clientProfileImage != null && _clientProfileImage!.isNotEmpty)
                              ? NetworkImage(_clientProfileImage!)
                              : null,
                          child: (_clientProfileImage == null || _clientProfileImage!.isEmpty)
                              ? const Icon(Icons.person, size: 32, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            _clientName ?? "คุณหญิงนุ้งนิ้ม สายบันเทิง",
                            style: const TextStyle(
                              color: Color(0xDD000000),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            debugPrint("Calling customer: $_clientPhone");
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.black,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            if (_activeRequestId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportUserPage(requestId: _activeRequestId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("ไม่พบข้อมูลคำขอที่จะรายงาน")),
                              );
                            }
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.report_problem,
                              color: Colors.redAccent,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // เส้นทางจุดเริ่มต้นและจุดหมายปลายทาง
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.location_on, color: Colors.black87, size: 28),
                            Container(
                              width: 2.5,
                              height: 60,
                              color: Colors.black87,
                            ),
                            const Icon(Icons.location_on_outlined, color: Colors.black87, size: 28),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickupName ?? "ผับคุณหนูนิ่มประจำเชียงใหม่",
                                style: const TextStyle(
                                  color: Color(0xDD000000),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "${_jobDistance ?? '3.4'} Km. Estimate 20 Min",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                _dropoffName ?? "บ้านพักคุณหนูนิ่ม",
                                style: const TextStyle(
                                  color: Color(0xDD000000),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // ปุ่มกดแสดงสถานะ (สไลด์เพื่อยืนยัน)
                    SlideActionBtn(
                      text: _currentJobStatus == 'going to pickup'
                          ? "ถึงจุดนัดหมาย"
                          : (_currentJobStatus == 'arrived' ? "เริ่มเดินทาง" : "สิ้นสุดการเดินทาง"),
                      onConfirmed: () async {
                        if (_currentJobStatus == 'going to pickup') {
                          try {
                            await Supabase.instance.client
                                .from(_isPubJob ? 'requestbypub' : 'requestbyuser')
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
                                .from(_isPubJob ? 'requestbypub' : 'requestbyuser')
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
                              debugPrint("Error broadcasting job completion: $e");
                            }

                            setState(() {
                              _hasActiveJob = false;
                              _activeRequestId = null;
                              _currentPosition = null;
                              _polylines = [];
                              _initLocation();
                            });
                          }
                        }
                      },
                    ),
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
                  color: _isLadyMode ? const Color(0xFFFFF0F5) : const Color(0xFFB2B2B2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: _isLadyMode ? Border.all(color: const Color(0xFFFF69B4), width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: _isLadyMode ? const Color(0xFFFF1493).withOpacity(0.35) : Colors.black26,
                      blurRadius: 12,
                      spreadRadius: 3,
                    )
                  ],
                ),
                padding: const EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ขีดสำหรับลากดึง
                    Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isLadyMode ? const Color(0xFFFF1493) : const Color(0xCC000000),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // หัวข้อ
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _isLadyMode ? "🌸 มีงานใหม่ (Lady Mode)!" : "มีงานใหม่เข้ามา!",
                            style: TextStyle(
                              color: _isLadyMode ? const Color(0xFFC71585) : const Color(0xDD000000),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gesture, color: _isLadyMode ? const Color(0xFFC71585) : const Color(0xDD000000), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _jobDistance ?? "0.0 km",
                              style: TextStyle(
                                color: _isLadyMode ? const Color(0xFFC71585) : const Color(0xDD000000),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_isLadyMode) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40FF1493),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.female, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "🌸 Lady Mode (สำหรับผู้หญิงเท่านั้น)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),

                    // ข้อมูลลูกค้า
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage: (_clientProfileImage != null && _clientProfileImage!.isNotEmpty)
                              ? NetworkImage(_clientProfileImage!)
                              : null,
                          child: (_clientProfileImage == null || _clientProfileImage!.isEmpty)
                              ? const Icon(Icons.person, size: 32, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            _clientName ?? "ลูกค้าทั่วไป",
                            style: const TextStyle(
                              color: Color(0xDD000000),
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
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ข้อมูลรถยนต์
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car, color: Color(0xDE000000)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _carDetails ?? "รถยนต์ส่วนบุคคล",
                                style: const TextStyle(
                                  color: Color(0xDD000000),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _carSubdetails ?? "ไม่ทราบรายละเอียดรถ",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ข้อมูลราคา/วิธีการจ่ายเงิน
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.attach_money, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _jobFee ?? "0.00\$",
                                style: const TextStyle(
                                  color: Color(0xDD000000),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _paymentMethod ?? "App Wallet",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ข้อมูลเกียร์
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings, color: Color(0xDE000000)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            _gearType ?? "Manual Gear",
                            style: const TextStyle(
                              color: Color(0xDD000000),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ปุ่มกด Accept / Denial
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_activeRequestId != null) {
                                _acceptTeamJob(_activeRequestId);
                              }
                              setState(() {
                                _isJobOfferOpen = false;
                              });
                            },
                            icon: const Icon(Icons.directions_car, color: Colors.black),
                            label: const Text(
                              "Accept",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF33),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isJobOfferOpen = false;
                              });
                            },
                            icon: const Icon(Icons.pan_tool, color: Colors.white),
                            label: const Text(
                              "Denial",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF3B30),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF7CE5FF),
        unselectedItemColor: Colors.white60,
        showSelectedLabels: true,
        showUnselectedLabels: true,
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
                  builder: (context) => ProfilePage(username: username, phoneno: phoneNo),
                ),
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
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
  const SlideActionBtn({super.key, required this.text, required this.onConfirmed});

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
                  padding: const EdgeInsets.only(left: 40.0), // give space for the green button
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
                      if (_dragPosition > maxDragDistance) _dragPosition = maxDragDistance;
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
