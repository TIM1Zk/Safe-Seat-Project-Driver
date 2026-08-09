import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LocationHelper {
  static final Map<String, String> _cache = {};

  /// Converts latitude and longitude into a readable location/address string.
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    if (lat == 0 && lng == 0) return "ไม่ระบุตำแหน่ง";

    // Round lat/lng to 4 decimal places (~11m precision) for caching
    final key = "${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}";
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'accept-language': 'th',
        },
        options: Options(
          headers: {
            'User-Agent': 'SafeSeatApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          final address = data['address'];
          final name = data['name'];
          final displayName = data['display_name'];

          String? result;

          // 1. Check if explicit POI or named location exists
          if (name != null && name.toString().trim().isNotEmpty) {
            result = name.toString().trim();
          } 
          // 2. Extract address components from OpenStreetMap address dictionary
          else if (address != null && address is Map) {
            final poi = address['amenity'] ??
                address['building'] ??
                address['shop'] ??
                address['tourism'] ??
                address['leisure'] ??
                address['hospital'] ??
                address['university'];
            final road = address['road'] ??
                address['pedestrian'] ??
                address['suburb'] ??
                address['neighbourhood'];
            final city = address['city'] ??
                address['town'] ??
                address['district'] ??
                address['county'] ??
                address['province'] ??
                address['state'];

            if (poi != null && road != null) {
              result = '$poi, $road';
            } else if (poi != null) {
              result = poi.toString();
            } else if (road != null && city != null) {
              result = '$road, $city';
            } else if (road != null) {
              result = road.toString();
            } else if (city != null) {
              result = city.toString();
            }
          }

          // 3. Fallback to parsing display_name
          if (result == null && displayName != null) {
            final parts = displayName.toString().split(',');
            if (parts.isNotEmpty) {
              result = parts.take(2).join(',').trim();
            }
          }

          if (result != null && result.isNotEmpty) {
            _cache[key] = result;
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint("LocationHelper reverse geocode error for ($lat, $lng): $e");
    }

    final fallback = "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
    _cache[key] = fallback;
    return fallback;
  }
}
