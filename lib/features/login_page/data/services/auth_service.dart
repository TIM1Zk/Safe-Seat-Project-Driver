import 'package:mobile_project/core/network/api_service.dart';
import 'package:dio/dio.dart';
import '../models/user_dto.dart';

class AuthService {
  Future<UserDto?> login(String username, String password, double? latitude, double? longitude) async {
    try {
      final response = await ApiService.post('/auth/login', data: {
        'username': username,
        'password': password,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      
      if (response.statusCode == 200 && response.data != null) {
        return UserDto.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map && e.response?.data['error'] != null) {
        throw e.response!.data['error'].toString();
      }
      if (e.response?.statusCode == 401) {
        throw 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
      }
      throw e.message ?? 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
    } catch (e) {
      rethrow;
    }
  }
}
