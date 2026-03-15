import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF231A0F);
  static const surface = Color(0xFF16161F);
  static const accent = Color(0xFFF98C06);
  static const accentLight = Color(0xFF7EE6F2);
  static const success = Color(0xFF00C853);

  // Text Colors
  static const textPrimary = Color(0xFFF1F5F9); // slate-100
  static const textSecondary = Color(0xFF94A3B8); // slate-400
  static const textCaption = Color(0xFF64748B); // slate-500

  static final border = Colors.white.withValues(alpha: 0.08);
  static final borderLight = Colors.white.withValues(alpha: 0.06);
  static final surfaceLight = Colors.white.withValues(alpha: 0.05);
  static final tagBackground = const Color(0xFFF98C06).withValues(alpha: 0.14);
}
