import 'package:flutter/material.dart';

/// ระบบชุดสีและ Design Tokens มาตรฐานของ SafeSeat (อ้างอิง COLOR_SYSTEM.md)
class AppTheme {
  // 1. Brand & Core Colors
  static const Color primaryBrand = Color(0xFF2340A7);       // #2340A7
  static const Color accentBlue = Color(0xFF2563EB);         // #2563EB
  static const Color deepBrandBlue = Color(0xFF0044C9);      // #0044C9

  // 2. Semantic & Feedback Colors
  static const Color success = Color(0xFF059669);            // #059669 (เขียวสำเร็จ)
  static const Color error = Color(0xFFDC2626);              // #DC2626 (แดงข้อผิดพลาด)
  static const Color warning = Color(0xFFD97706);            // #D97706 (ส้ม/อำพันคำเตือน)
  static const Color info = Color(0xFF0F172A);               // #0F172A (ข้อมูล)

  // 3. Trip Status Flow Colors
  static const Color statusSearchingFg = Color(0xFF94A3B8);  // กำลังค้นหาคนขับ
  static const Color statusSearchingBg = Color(0xFFF1F5F9);
  static const Color statusGoingPickupFg = Color(0xFF2563EB); // คนขับกำลังมารับ
  static const Color statusGoingPickupBg = Color(0xFFDBEAFE);
  static const Color statusArrivedFg = Color(0xFFD97706);     // ถึงจุดนัดหมายแล้ว
  static const Color statusArrivedBg = Color(0xFFFEF3C7);
  static const Color statusInProgressFg = Color(0xFF7C3AED);  // กำลังนำทางไปปลายทาง
  static const Color statusInProgressBg = Color(0xFFF3E8FF);
  static const Color statusCompletedFg = Color(0xFF059669);   // การเดินทางเสร็จสิ้น
  static const Color statusCompletedBg = Color(0xFFD1FAE5);

  // 4. Map & Navigation Markers
  static const Color pickupMarker = Color(0xFFF97316);       // จุดรับร้านเหล้า #F97316 (ส้ม Amber/Orange)
  static const Color dropoffMarker = Color(0xFF10B981);      // จุดส่ง #10B981
  static const Color driverMarker = Color(0xFF2340A7);       // ตำแหน่งคนขับ #2340A7
  static const Color polylineColor = Color(0xFF2340A7);      // เส้นทาง #2340A7

  // 5. Neutral & Surface Colors
  static const Color appBackground = Color(0xFFF8FAFC);      // Slate 50 (#F8FAFC)
  static const Color cardSurface = Colors.white;             // #FFFFFF
  static const Color inputBackground = Color(0xFFF3F4F6);    // #F3F4F6
  static const Color borderDivider = Color(0xFFE2E8F0);      // #E2E8F0
  static const Color textPrimary = Color(0xFF1E293B);        // Slate 800 (#1E293B)
  static const Color textSecondary = Color(0xFF64748B);      // Slate 500 (#64748B)
  static const Color textMuted = Color(0xFF94A3B8);          // Slate 400 (#94A3B8)
}
