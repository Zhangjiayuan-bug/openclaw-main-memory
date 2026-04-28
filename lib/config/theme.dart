import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 科技风配色主题
class TechTheme {
  // 主色调
  static const Color deepSpaceBlue = Color(0xFF0D1B2A);    // 深空蓝（背景）
  static const Color darkNightBlue = Color(0xFF1B263B);   // 暗夜蓝（卡片背景）
  static const Color starGrayBlue = Color(0xFF415A77);    // 星灰蓝（次级元素）
  static const Color silverGray = Color(0xFF778DA9);      // 银灰（文字）

  // 强调色
  static const Color electricCyan = Color(0xFF00D9FF);     // 电光青（主要按钮、高亮）
  static const Color matrixGreen = Color(0xFF00FF88);     // 矩阵绿（成功状态）
  static const Color warningRed = Color(0xFFFF6B6B);       // 警示红（错误、失败）
  static const Color neonPurple = Color(0xFF9D4EDD);       // 霓虹紫（sakura 专属）
  static const Color energyYellow = Color(0xFFFFD93D);      // 能量黄（进行中）

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepSpaceBlue,
      primaryColor: electricCyan,
      colorScheme: const ColorScheme.dark(
        primary: electricCyan,
        secondary: matrixGreen,
        surface: darkNightBlue,
        error: warningRed,
        onPrimary: deepSpaceBlue,
        onSecondary: deepSpaceBlue,
        onSurface: silverGray,
        onError: Colors.white,
      ),
      cardColor: darkNightBlue,
      appBarTheme: AppBarTheme(
        backgroundColor: deepSpaceBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansSc(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: electricCyan),
      ),
      cardTheme: CardTheme(
        color: darkNightBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: starGrayBlue, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricCyan,
          foregroundColor: deepSpaceBlue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansSc(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: electricCyan,
          side: const BorderSide(color: electricCyan, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansSc(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.notoSansSc(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.notoSansSc(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.notoSansSc(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.notoSansSc(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: silverGray,
        ),
        bodyLarge: GoogleFonts.notoSansSc(
          fontSize: 16,
          color: silverGray,
        ),
        bodyMedium: GoogleFonts.notoSansSc(
          fontSize: 14,
          color: silverGray,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: electricCyan,
        ),
      ),
      iconTheme: const IconThemeData(color: electricCyan),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: electricCyan,
        linearTrackColor: starGrayBlue,
      ),
      dividerTheme: const DividerThemeData(
        color: starGrayBlue,
        thickness: 0.5,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkNightBlue,
        selectedItemColor: electricCyan,
        unselectedItemColor: silverGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkNightBlue,
        contentTextStyle: GoogleFonts.notoSansSc(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: starGrayBlue),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 获取状态颜色
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return matrixGreen;
      case 'pending':
      case 'waiting':
        return energyYellow;
      case 'error':
      case 'failed':
        return warningRed;
      case 'in_progress':
      case 'running':
        return electricCyan;
      default:
        return silverGray;
    }
  }
}
