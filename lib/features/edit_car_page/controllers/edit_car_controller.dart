import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_project/core/network/api_service.dart';
import 'package:mobile_project/features/edit_car_page/models/driver_car.dart';
import 'package:dio/dio.dart' as dio;

class EditCarController extends ChangeNotifier {
  DriverCar? driverCar;
  bool isLoading = true;
  String? errorMessage;

  final String username;

  EditCarController({required this.username}) {
    fetchCarDetails();
  }

  /// ดึงข้อมูลรถยนต์ปัจจุบันของผู้ใช้
  Future<void> fetchCarDetails() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/users/$username');
      if (response.statusCode == 200 && response.data != null) {
        final carJson = response.data['drivercar'];
        if (carJson != null) {
          driverCar = DriverCar.fromJson(carJson);
        } else {
          errorMessage = "ไม่พบข้อมูลรถยนต์ของคนขับ";
        }
      } else {
        errorMessage = "ไม่พบข้อมูลโปรไฟล์คนขับ";
      }
    } catch (e) {
      errorMessage = "ดึงข้อมูลรถยนต์ไม่สำเร็จ: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// อัปเดตข้อมูลรถยนต์ไปยังระบบหลังบ้าน
  Future<bool> updateCarDetails({
    required String carBrand,
    required String carModel,
    required String carColor,
    required String carPlate,
    String? frontImagePath,
    String? sideImagePath,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> driverCarMap = {
        'carbrand': carBrand,
        'carmodel': carModel,
        'carcolor': carColor,
        'carplate': carPlate,
      };

      // Since we need to support file uploads, we use FormData
      final Map<String, dynamic> dataMap = {
        'drivercar': jsonEncode(driverCarMap),
      };

      if (frontImagePath != null && frontImagePath.isNotEmpty) {
        dataMap['frontImage'] = await dio.MultipartFile.fromFile(
          frontImagePath,
          filename: 'front_car.jpg',
        );
      }

      if (sideImagePath != null && sideImagePath.isNotEmpty) {
        dataMap['sideImage'] = await dio.MultipartFile.fromFile(
          sideImagePath,
          filename: 'side_car.jpg',
        );
      }

      final formData = dio.FormData.fromMap(dataMap);

      final response = await ApiService.put('/users/$username', data: formData);

      if (response.statusCode == 200) {
        if (response.data != null && response.data is Map) {
          final carJson = response.data['drivercar'] ?? response.data;
          if (carJson is Map<String, dynamic>) {
            driverCar = DriverCar.fromJson(carJson);
          }
        }
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = "แก้ไขข้อมูลรถยนต์ไม่สำเร็จ";
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is dio.DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('error')) {
          errorMessage = "แก้ไขไม่สำเร็จ: ${data['error']}";
        } else {
          errorMessage = "แก้ไขข้อมูลรถยนต์ไม่สำเร็จ: ${e.response?.statusCode} ${e.response?.statusMessage}";
        }
      } else {
        errorMessage = "แก้ไขข้อมูลรถยนต์ไม่สำเร็จ: $e";
      }
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
