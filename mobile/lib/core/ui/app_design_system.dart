import 'package:flutter/material.dart';

typedef AppTextStyle = TextStyle;
typedef AppEdgeInsets = EdgeInsets;
typedef AppEdgeInsetsDirectional = EdgeInsetsDirectional;
typedef AppBorderRadius = BorderRadius;
typedef AppRadiusValue = Radius;
typedef AppBoxDecoration = BoxDecoration;
typedef AppInputDecoration = InputDecoration;

/// Preview contract for the Inflap mobile design system.
///
/// New UI should consume these tokens, themes, helpers, and component styles
/// instead of declaring one-off colors, padding, radii, text styles, or button
/// styles inside screens.
abstract final class AppDesignSystem {
  static const name = 'Inflap Mobile Design System';

  static ThemeData darkTheme() => AppTheme.dark();
}

enum AppScreenClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const expanded = 840.0;

  static AppScreenClass classify(double width) {
    if (width >= expanded) return AppScreenClass.expanded;
    if (width >= compact) return AppScreenClass.medium;
    return AppScreenClass.compact;
  }
}

class AppAdaptive {
  const AppAdaptive._({
    required this.size,
    required this.screenClass,
    required this.shortestSide,
    required this.textScaleFactor,
  });

  final Size size;
  final AppScreenClass screenClass;
  final double shortestSide;
  final double textScaleFactor;

  factory AppAdaptive.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final baseFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? AppTypography.body;
    final textScaleFactor = textScaler.scale(baseFontSize) / baseFontSize;

    return AppAdaptive._(
      size: size,
      screenClass: AppBreakpoints.classify(size.width),
      shortestSide: size.shortestSide,
      textScaleFactor: textScaleFactor.clamp(1.0, 1.4),
    );
  }

  bool get isCompact => screenClass == AppScreenClass.compact;
  bool get isMedium => screenClass == AppScreenClass.medium;
  bool get isExpanded => screenClass == AppScreenClass.expanded;
  bool get isNarrow => size.width < 370;
  bool get isShort => size.height < 700;

  /// Use only for layout chrome: spacing, icons, radii, media blocks.
  /// Do not use this to shrink text against system accessibility scaling.
  double scale(
    double value, {
    double minFactor = 0.86,
    double maxFactor = 1.08,
  }) {
    final widthFactor = (shortestSide / 393).clamp(minFactor, maxFactor);
    final textPenalty = textScaleFactor > 1.12
        ? 1 - ((textScaleFactor - 1.12) * 0.10)
        : 1.0;
    final factor = (widthFactor * textPenalty).clamp(minFactor, maxFactor);
    return value * factor;
  }

  EdgeInsets get pagePadding {
    return switch (screenClass) {
      AppScreenClass.compact => EdgeInsets.symmetric(
        horizontal: isNarrow ? AppSpacing.lg : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      AppScreenClass.medium => const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      AppScreenClass.expanded => const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xl,
      ),
    };
  }

  BoxConstraints get contentConstraints {
    return switch (screenClass) {
      AppScreenClass.compact => const BoxConstraints(),
      AppScreenClass.medium => const BoxConstraints(maxWidth: 720),
      AppScreenClass.expanded => const BoxConstraints(maxWidth: 1040),
    };
  }
}

extension AppDesignContext on BuildContext {
  AppAdaptive get appAdaptive => AppAdaptive.of(this);
  TextTheme get appTextTheme => Theme.of(this).textTheme;
  ColorScheme get appColorScheme => Theme.of(this).colorScheme;
}

abstract final class AppPalette {
  static const primary = Color(0xFFF98C06);
  static const accent = primary;
  static const primaryLight = info;
  static const primarySoft = Color(0xFFFFB44D);
  static const primaryMuted = Color(0xFF9E5D05);
  static const onPrimary = Color(0xFF1B1006);

  static const info = Color(0xFF7EE6F2);
  static const accentLight = info;
  static const success = Color(0xFF00C853);
  static const warning = Color(0xFFFFC56D);
  static const danger = Color(0xFFFF6B6B);
  static const destructive = danger;
  static const destruct = danger;

  static const background = Color(0xFF120B06);
  static const backgroundDeep = Color(0xFF0A0705);
  static const backgroundWarm = Color(0xFF231A0F);

  static const surface = Color(0xFF21170D);
  static const surfaceRaised = Color(0xFF2B1F14);
  static const surfaceHigh = Color(0xFF332416);
  static const surfaceMuted = Color(0xFF3B2B1C);
  static const surfaceCool = Color(0xFF16161F);
  static const surfaceInverse = Color(0xFFFFF7ED);
  static const surfaceLight = Color(0x0DFFFFFF);

  static const textPrimary = Color(0xFFF1F5F9);
  static const textWarm = Color(0xFFFFF7EF);
  static const textSecondary = Color(0xFFE0D4C6);
  static const textCaption = Color(0xFF64748B);
  static const textMuted = Color(0xFFA99683);
  static const textDisabled = Color(0xFF756252);
  static const textOnInverse = Color(0xFF241407);

  static const border = Color(0x293A270F);
  static const borderStrong = Color(0x33FF9800);
  static const borderSoft = Color(0x12FFFFFF);
  static const borderLight = Color(0x0FFFFFFF);
  static const tagBackground = Color(0x24F98C06);
  static const divider = Color(0x1FFFF7ED);
  static const scrim = Color(0xB3000000);
  // Generated palette tokens: keep raw color values centralized here.
  static const clearWarmInk01 = Color(0x00140A05);
  static const clearWarmInk02 = Color(0x001D1208);
  static const clearOrangeSoft01 = Color(0x00FF9326);
  static const clearOrangeSoft02 = Color(0x00FFAD42);
  static const clearOrangeSoft03 = Color(0x00FFB24B);
  static const redOverlayWash01 = Color(0x05F4F2F2);
  static const neutralOverlayInk01 = Color(0x08000000);
  static const warmOverlayMuted01 = Color(0x0DFF9900);
  static const amberOverlaySoft01 = Color(0x0DFFB854);
  static const neutralOverlayInk02 = Color(0x12000000);
  static const redOverlaySoft01 = Color(0x14FF7A59);
  static const warmOverlayMuted02 = Color(0x14FF9800);
  static const warmOverlayMuted03 = Color(0x14FFA200);
  static const orangeOverlaySoft01 = Color(0x18FFB24B);
  static const warmOverlaySurface01 = Color(0x1A3A2109);
  static const neutralOverlayWash01 = Color(0x1AFFFFFF);
  static const neutralOverlayInk03 = Color(0x1F000000);
  static const orangeOverlaySoft02 = Color(0x1FFFA833);
  static const blueOverlayLight01 = Color(0x2280B7FF);
  static const neutralOverlayInk04 = Color(0x24000000);
  static const orangeOverlaySoft03 = Color(0x24FF9326);
  static const warmOverlayMuted04 = Color(0x2EFF9D00);
  static const orangeOverlaySoft04 = Color(0x2EFFAB4F);
  static const warmOverlayInk01 = Color(0x33271609);
  static const warmOverlaySurface02 = Color(0x332B1A0D);
  static const warmOverlayMuted05 = Color(0x33F98C06);
  static const neutralOverlayWash02 = Color(0x33FFFFFF);
  static const warmOverlayMuted06 = Color(0x3DFF9800);
  static const warmOverlayMuted07 = Color(0x42FF9900);
  static const neutralOverlayInk05 = Color(0x47000000);
  static const warmOverlayMuted08 = Color(0x4DFF9900);
  static const orangeOverlaySoft05 = Color(0x4FFFAD42);
  static const neutralOverlayInk06 = Color(0x55000000);
  static const greenOverlayMuted01 = Color(0x554E8B57);
  static const warmOverlayMuted09 = Color(0x57FF9900);
  static const blueOverlayInk01 = Color(0x6605060A);
  static const warmOverlayInk02 = Color(0x66120B05);
  static const warmOverlayInk03 = Color(0x661D1109);
  static const redOverlayMuted01 = Color(0x66B9584B);
  static const warmOverlaySurface03 = Color(0x734C2F15);
  static const orangeOverlayWash01 = Color(0x75FFF0E0);
  static const redOverlaySoft02 = Color(0x88FF8A65);
  static const orangeOverlayWash02 = Color(0x88FFF0E0);
  static const warmOverlaySurface04 = Color(0x8A4C2F15);
  static const orangeOverlayWash03 = Color(0x8CFFF0E0);
  static const orangeOverlayWash04 = Color(0x8FFFF7EF);
  static const orangeOverlayLight01 = Color(0x99D6C1B3);
  static const orangeOverlayWash05 = Color(0x99FFF0E0);
  static const orangeOverlayWash06 = Color(0xA1FFF0E0);
  static const warmOverlaySurface05 = Color(0xA334271D);
  static const warmOverlaySurface06 = Color(0xA34D2D13);
  static const orangeOverlayWash07 = Color(0xA8FFF0E0);
  static const orangeOverlayWash08 = Color(0xB0FFF0E0);
  static const orangeOverlayWash09 = Color(0xB3FFF0E0);
  static const neutralOverlaySoft01 = Color(0xB4959A96);
  static const warmOverlayInk04 = Color(0xB6231A0F);
  static const tealOverlaySurface01 = Color(0xB71B211F);
  static const warmOverlayInk05 = Color(0xB8140B06);
  static const warmOverlaySurface07 = Color(0xB83A2616);
  static const warmOverlaySurface08 = Color(0xB8412A18);
  static const warmOverlaySurfaceHigh01 = Color(0xB8554C24);
  static const neutralOverlayInk07 = Color(0xBF000000);
  static const blueOverlayInk02 = Color(0xC2080A12);
  static const warmOverlayInk06 = Color(0xC21F130A);
  static const orangeOverlayWash10 = Color(0xC2FFF0E0);
  static const warmOverlaySurface09 = Color(0xC428211B);
  static const orangeOverlayLight02 = Color(0xC7E3D4C2);
  static const warmOverlaySurface10 = Color(0xCC46362A);
  static const redOverlaySoft03 = Color(0xCCFF7A59);
  static const warmOverlayInk07 = Color(0xD01F1710);
  static const warmOverlaySurface11 = Color(0xD1261C15);
  static const warmOverlaySurface12 = Color(0xD12D1A0D);
  static const warmOverlaySurface13 = Color(0xD136230F);
  static const warmOverlaySurface14 = Color(0xD13C210D);
  static const tealOverlaySurface02 = Color(0xD41B211F);
  static const warmOverlayInk08 = Color(0xD423150B);
  static const warmOverlayInk09 = Color(0xD723160D);
  static const warmOverlayInk10 = Color(0xD91D1009);
  static const warmOverlaySurface15 = Color(0xE02F1809);
  static const warmOverlaySurface16 = Color(0xE62D1A0D);
  static const orangeOverlayLight03 = Color(0xE6F0E2D2);
  static const orangeOverlayWash11 = Color(0xE6FFF0E0);
  static const blueOverlayInk03 = Color(0xEB090B12);
  static const warmOverlaySurface17 = Color(0xEB2C2014);
  static const warmOverlaySurface18 = Color(0xF029190A);
  static const warmOverlayInk11 = Color(0xF2100703);
  static const warmOverlayInk12 = Color(0xF2211508);
  static const warmOverlaySurface19 = Color(0xF228190D);
  static const warmOverlayInk13 = Color(0xF51D0E06);
  static const warmOverlayInk14 = Color(0xF822150C);
  static const warmOverlaySurface20 = Color(0xF92A190D);
  static const warmOverlayInk15 = Color(0xFA170E08);
  static const warmOverlayInk16 = Color(0xFA180E08);
  static const blueSurfaceHigh01 = Color(0xFF000080);
  static const blueSurfaceHigh02 = Color(0xFF002776);
  static const blueSurfaceHigh03 = Color(0xFF002A8F);
  static const blueSurfaceHigh04 = Color(0xFF0032A0);
  static const blueSurfaceHigh05 = Color(0xFF0033A0);
  static const blueSurfaceHigh06 = Color(0xFF0038A8);
  static const blueSurfaceHigh07 = Color(0xFF0039A6);
  static const blueSurfaceHigh08 = Color(0xFF003F87);
  static const blueSurfaceHigh09 = Color(0xFF0047A0);
  static const tealSurface01 = Color(0xFF00534E);
  static const blueSurfaceHigh10 = Color(0xFF0057B7);
  static const greenSurface01 = Color(0xFF006233);
  static const greenSurface02 = Color(0xFF006600);
  static const blueSurfaceHigh11 = Color(0xFF0066B3);
  static const tealSurface02 = Color(0xFF006847);
  static const blueSurfaceHigh12 = Color(0xFF006AA7);
  static const greenSurfaceHigh01 = Color(0xFF00732F);
  static const greenSurfaceHigh02 = Color(0xFF007A3D);
  static const greenSurfaceHigh03 = Color(0xFF007E3A);
  static const greenSurfaceHigh04 = Color(0xFF00843D);
  static const greenSurfaceHigh05 = Color(0xFF009639);
  static const greenSurfaceHigh06 = Color(0xFF009A49);
  static const greenSurfaceHigh07 = Color(0xFF009B3A);
  static const blueMuted01 = Color(0xFF00A3DD);
  static const tealMuted01 = Color(0xFF00AFCA);
  static const tealMuted02 = Color(0xFF00B5E2);
  static const tealMuted03 = Color(0xFF00BCD4);
  static const tealMuted04 = Color(0xFF00DF85);
  static const blueSurface01 = Color(0xFF010066);
  static const blueSurface02 = Color(0xFF012169);
  static const blueSurfaceHigh13 = Color(0xFF02529C);
  static const greenInk01 = Color(0xFF07140A);
  static const blueSurface03 = Color(0xFF071D31);
  static const greenInk02 = Color(0xFF072012);
  static const tealInk01 = Color(0xFF08232A);
  static const blueSurface04 = Color(0xFF083256);
  static const tealInk02 = Color(0xFF0C1816);
  static const blueSurfaceHigh14 = Color(0xFF0C3F67);
  static const blueSurfaceHigh15 = Color(0xFF0C4076);
  static const warmInk01 = Color(0xFF0D0602);
  static const greenInk03 = Color(0xFF0D2417);
  static const warmInk02 = Color(0xFF0E0A08);
  static const greenInk04 = Color(0xFF0E1D13);
  static const tealInk03 = Color(0xFF0E2423);
  static const tealSurface03 = Color(0xFF0E4C5B);
  static const blueSurfaceHigh16 = Color(0xFF0E4F88);
  static const warmInk03 = Color(0xFF0F0905);
  static const warmInk04 = Color(0xFF0F0906);
  static const tealSurface04 = Color(0xFF0F2B2B);
  static const warmInk05 = Color(0xFF100802);
  static const warmInk06 = Color(0xFF100C08);
  static const neutralInk01 = Color(0xFF101010);
  static const blueSurface05 = Color(0xFF101923);
  static const greenInk05 = Color(0xFF101A10);
  static const blueSurface06 = Color(0xFF101A25);
  static const tealInk04 = Color(0xFF10211E);
  static const greenSurface03 = Color(0xFF10291E);
  static const greenSurface04 = Color(0xFF102E19);
  static const neutralInk02 = Color(0xFF111111);
  static const blueSurfaceHigh17 = Color(0xFF11457E);
  static const warmInk07 = Color(0xFF120A05);
  static const warmInk08 = Color(0xFF120B07);
  static const warmInk09 = Color(0xFF120C07);
  static const warmInk10 = Color(0xFF120D07);
  static const tealSurface05 = Color(0xFF12352F);
  static const tealSurface06 = Color(0xFF124953);
  static const warmInk11 = Color(0xFF130A03);
  static const warmInk12 = Color(0xFF130C06);
  static const greenSurfaceHigh08 = Color(0xFF138808);
  static const warmInk13 = Color(0xFF140901);
  static const warmInk14 = Color(0xFF140A05);
  static const warmInk15 = Color(0xFF140B04);
  static const warmInk16 = Color(0xFF140B06);
  static const greenSurface05 = Color(0xFF143B29);
  static const greenSurface06 = Color(0xFF143E23);
  static const warmInk17 = Color(0xFF150A03);
  static const warmInk18 = Color(0xFF150E08);
  static const warmInk19 = Color(0xFF15100D);
  static const warmInk20 = Color(0xFF160B05);
  static const warmInk21 = Color(0xFF160D05);
  static const warmInk22 = Color(0xFF160D07);
  static const warmInk23 = Color(0xFF160F0A);
  static const blueSurface07 = Color(0xFF161329);
  static const blueSurface08 = Color(0xFF16313A);
  static const tealSurfaceHigh01 = Color(0xFF168D95);
  static const warmInk24 = Color(0xFF170C04);
  static const warmInk25 = Color(0xFF170D06);
  static const warmInk26 = Color(0xFF170D08);
  static const violetInk01 = Color(0xFF170F1F);
  static const warmInk27 = Color(0xFF171009);
  static const warmInk28 = Color(0xFF17100A);
  static const blueSurface09 = Color(0xFF171428);
  static const greenSurface07 = Color(0xFF173E2A);
  static const warmInk29 = Color(0xFF181006);
  static const warmInk30 = Color(0xFF181109);
  static const warmInk31 = Color(0xFF18110A);
  static const blueMuted02 = Color(0xFF1877BC);
  static const tealSurfaceHigh02 = Color(0xFF187B5F);
  static const greenMuted01 = Color(0xFF18C26E);
  static const greenMuted02 = Color(0xFF18D26E);
  static const violetInk02 = Color(0xFF190E22);
  static const warmInk32 = Color(0xFF1A0D03);
  static const warmInk33 = Color(0xFF1A0F08);
  static const warmInk34 = Color(0xFF1A1007);
  static const warmInk35 = Color(0xFF1A1008);
  static const warmInk36 = Color(0xFF1A1009);
  static const warmInk37 = Color(0xFF1A1209);
  static const warmInk38 = Color(0xFF1A120D);
  static const warmInk39 = Color(0xFF1B0F07);
  static const warmInk40 = Color(0xFF1B1008);
  static const warmInk41 = Color(0xFF1B1009);
  static const warmInk42 = Color(0xFF1B1208);
  static const warmInk43 = Color(0xFF1B120B);
  static const warmInk44 = Color(0xFF1B120C);
  static const warmInk45 = Color(0xFF1B130E);
  static const tealSurface07 = Color(0xFF1B2D32);
  static const greenSurfaceHigh09 = Color(0xFF1B5E20);
  static const tealSurfaceHigh03 = Color(0xFF1B6258);
  static const warmInk46 = Color(0xFF1C0F08);
  static const warmInk47 = Color(0xFF1C1007);
  static const warmInk48 = Color(0xFF1C1107);
  static const warmInk49 = Color(0xFF1C1109);
  static const warmInk50 = Color(0xFF1C110A);
  static const warmInk51 = Color(0xFF1C120A);
  static const warmInk52 = Color(0xFF1C150C);
  static const neutralSurface01 = Color(0xFF1C1C1C);
  static const pinkInk01 = Color(0xFF1D0B17);
  static const warmInk53 = Color(0xFF1D1008);
  static const warmInk54 = Color(0xFF1D1208);
  static const warmInk55 = Color(0xFF1D120B);
  static const warmInk56 = Color(0xFF1D1711);
  static const greenSurface08 = Color(0xFF1D4726);
  static const tealSurface08 = Color(0xFF1D4B45);
  static const greenMuted03 = Color(0xFF1DBF73);
  static const warmInk57 = Color(0xFF1E1208);
  static const warmInk58 = Color(0xFF1E120A);
  static const warmInk59 = Color(0xFF1E140B);
  static const blueMuted03 = Color(0xFF1EB2E8);
  static const greenMuted04 = Color(0xFF1EB53A);
  static const pinkInk02 = Color(0xFF1F0A17);
  static const warmInk60 = Color(0xFF1F150B);
  static const blueSurfaceHigh18 = Color(0xFF1F4D8A);
  static const tealSurfaceHigh04 = Color(0xFF1F5248);
  static const tealSurfaceHigh05 = Color(0xFF1F6B5B);
  static const warmInk61 = Color(0xFF201108);
  static const warmInk62 = Color(0xFF201207);
  static const warmInk63 = Color(0xFF201208);
  static const warmInk64 = Color(0xFF201407);
  static const warmInk65 = Color(0xFF20150B);
  static const warmInk66 = Color(0xFF20160D);
  static const warmInk67 = Color(0xFF20170E);
  static const warmInk68 = Color(0xFF211108);
  static const warmInk69 = Color(0xFF211109);
  static const warmInk70 = Color(0xFF211207);
  static const warmInk71 = Color(0xFF211209);
  static const warmInk72 = Color(0xFF211306);
  static const warmInk73 = Color(0xFF211307);
  static const warmInk74 = Color(0xFF21140B);
  static const warmInk75 = Color(0xFF21140C);
  static const warmInk76 = Color(0xFF211508);
  static const warmInk77 = Color(0xFF21150D);
  static const warmInk78 = Color(0xFF211609);
  static const warmInk79 = Color(0xFF21160C);
  static const warmInk80 = Color(0xFF21160D);
  static const warmInk81 = Color(0xFF21180D);
  static const blueSurfaceHigh19 = Color(0xFF214B67);
  static const warmInk82 = Color(0xFF221109);
  static const warmInk83 = Color(0xFF221209);
  static const warmInk84 = Color(0xFF22140A);
  static const warmInk85 = Color(0xFF22140B);
  static const warmInk86 = Color(0xFF22160D);
  static const warmInk87 = Color(0xFF231108);
  static const warmInk88 = Color(0xFF231407);
  static const warmInk89 = Color(0xFF23140A);
  static const greenSurfaceHigh10 = Color(0xFF23864C);
  static const tealMuted05 = Color(0xFF2396A8);
  static const warmInk90 = Color(0xFF241100);
  static const warmInk91 = Color(0xFF241307);
  static const warmInk92 = Color(0xFF241308);
  static const warmInk93 = Color(0xFF241405);
  static const warmInk94 = Color(0xFF241406);
  static const warmInk95 = Color(0xFF241509);
  static const warmInk96 = Color(0xFF24150A);
  static const warmInk97 = Color(0xFF24160C);
  static const warmInk98 = Color(0xFF24170B);
  static const warmInk99 = Color(0xFF24170C);
  static const warmSurface01 = Color(0xFF241A11);
  static const blueMuted04 = Color(0xFF244AA5);
  static const blueSurfaceHigh20 = Color(0xFF245163);
  static const greenSurfaceHigh11 = Color(0xFF245C3D);
  static const warmInk100 = Color(0xFF251408);
  static const warmInk101 = Color(0xFF25160B);
  static const warmInk102 = Color(0xFF25160D);
  static const warmInk103 = Color(0xFF25170C);
  static const warmInk104 = Color(0xFF25170D);
  static const warmInk105 = Color(0xFF25180D);
  static const warmInk106 = Color(0xFF25190D);
  static const warmSurface02 = Color(0xFF251A10);
  static const blueSurface10 = Color(0xFF25323B);
  static const blueSurfaceHigh21 = Color(0xFF25405A);
  static const greenSurfaceHigh12 = Color(0xFF257B54);
  static const tealMuted06 = Color(0xFF25B67A);
  static const warmInk107 = Color(0xFF26160C);
  static const warmInk108 = Color(0xFF26170C);
  static const warmSurface03 = Color(0xFF26180D);
  static const warmSurface04 = Color(0xFF261A12);
  static const blueSurfaceHigh22 = Color(0xFF263C53);
  static const warmInk109 = Color(0xFF271609);
  static const warmInk110 = Color(0xFF27170B);
  static const warmInk111 = Color(0xFF27180B);
  static const warmSurface05 = Color(0xFF271A0E);
  static const warmSurface06 = Color(0xFF281A10);
  static const tealSurface09 = Color(0xFF293B35);
  static const tealSurfaceHigh06 = Color(0xFF295E54);
  static const redSurface01 = Color(0xFF2A1512);
  static const warmInk112 = Color(0xFF2A1608);
  static const warmInk113 = Color(0xFF2A1708);
  static const warmSurface07 = Color(0xFF2A1709);
  static const warmSurface08 = Color(0xFF2A180C);
  static const warmSurface09 = Color(0xFF2A180D);
  static const warmInk114 = Color(0xFF2A1907);
  static const warmSurface10 = Color(0xFF2A190C);
  static const warmSurface11 = Color(0xFF2A190E);
  static const warmSurface12 = Color(0xFF2A1A0A);
  static const warmSurface13 = Color(0xFF2A1A0E);
  static const warmSurface14 = Color(0xFF2A1A10);
  static const warmSurface15 = Color(0xFF2A1B0B);
  static const warmSurface16 = Color(0xFF2A1C10);
  static const warmSurface17 = Color(0xFF2A1D13);
  static const warmSurface18 = Color(0xFF2A1E11);
  static const warmSurface19 = Color(0xFF2A1F12);
  static const warmSurface20 = Color(0xFF2A2118);
  static const greenSurfaceHigh13 = Color(0xFF2A4B2B);
  static const greenSurfaceHigh14 = Color(0xFF2A5F31);
  static const tealSurfaceHigh07 = Color(0xFF2A7A6E);
  static const tealMuted07 = Color(0xFF2A9EA4);
  static const warmInk115 = Color(0xFF2B1606);
  static const warmSurface21 = Color(0xFF2B1808);
  static const warmSurface22 = Color(0xFF2B1908);
  static const warmSurface23 = Color(0xFF2B190D);
  static const warmInk116 = Color(0xFF2B1A05);
  static const warmSurface24 = Color(0xFF2B1D0F);
  static const warmSurface25 = Color(0xFF2B2119);
  static const warmSurface26 = Color(0xFF2C1507);
  static const warmSurface27 = Color(0xFF2C2014);
  static const warmSurface28 = Color(0xFF2C2118);
  static const greenSurface09 = Color(0xFF2C3A2C);
  static const warmSurface29 = Color(0xFF2D1308);
  static const warmSurface30 = Color(0xFF2D1A0D);
  static const warmSurface31 = Color(0xFF2D1C0B);
  static const warmSurface32 = Color(0xFF2D1C0F);
  static const warmSurface33 = Color(0xFF2D1E11);
  static const warmSurface34 = Color(0xFF2D1F11);
  static const warmSurface35 = Color(0xFF2D2115);
  static const blueSurfaceHigh23 = Color(0xFF2D2A4A);
  static const tealSurfaceHigh08 = Color(0xFF2D7478);
  static const blueSoft01 = Color(0xFF2D7DFF);
  static const greenSurfaceHigh15 = Color(0xFF2D8437);
  static const greenSurfaceHigh16 = Color(0xFF2D8B63);
  static const warmSurface36 = Color(0xFF2E2114);
  static const blueMuted05 = Color(0xFF2E5B9A);
  static const greenSurfaceHigh17 = Color(0xFF2E7D4C);
  static const warmSurface37 = Color(0xFF2F1A06);
  static const warmSurface38 = Color(0xFF2F2B27);
  static const blueSurfaceHigh24 = Color(0xFF2F4D8F);
  static const warmSurface39 = Color(0xFF30160C);
  static const warmSurface40 = Color(0xFF312316);
  static const blueMuted06 = Color(0xFF3157A4);
  static const warmSurface41 = Color(0xFF322013);
  static const warmSurface42 = Color(0xFF33200F);
  static const warmSurface43 = Color(0xFF33210C);
  static const blueSurfaceHigh25 = Color(0xFF33516E);
  static const tealSurfaceHigh09 = Color(0xFF338E7B);
  static const warmSurface44 = Color(0xFF342315);
  static const warmSurface45 = Color(0xFF342416);
  static const blueSurfaceHigh26 = Color(0xFF342E63);
  static const tealSurfaceHigh10 = Color(0xFF346B73);
  static const blueMuted07 = Color(0xFF3474A8);
  static const tealSurfaceHigh11 = Color(0xFF357B70);
  static const blueSurfaceHigh27 = Color(0xFF375F75);
  static const warmSurface46 = Color(0xFF392719);
  static const blueMuted08 = Color(0xFF394F90);
  static const redSurface02 = Color(0xFF3A180E);
  static const warmSurface47 = Color(0xFF3A2107);
  static const warmSurface48 = Color(0xFF3A2108);
  static const warmSurface49 = Color(0xFF3A210C);
  static const warmSurface50 = Color(0xFF3A2114);
  static const warmSurface51 = Color(0xFF3A220D);
  static const warmSurface52 = Color(0xFF3A220E);
  static const warmSurface53 = Color(0xFF3A220F);
  static const warmSurface54 = Color(0xFF3A2308);
  static const warmSurface55 = Color(0xFF3A240D);
  static const warmSurface56 = Color(0xFF3A2415);
  static const warmSurface57 = Color(0xFF3A270F);
  static const warmSurface58 = Color(0xFF3A2814);
  static const warmSurface59 = Color(0xFF3A2818);
  static const warmSurface60 = Color(0xFF3A2A1A);
  static const warmSurface61 = Color(0xFF3A2A1B);
  static const warmSurface62 = Color(0xFF3A2A1D);
  static const warmSurface63 = Color(0xFF3A2B1D);
  static const warmSurface64 = Color(0xFF3A302C);
  static const warmSurface65 = Color(0xFF3B2414);
  static const warmSurface66 = Color(0xFF3B260D);
  static const warmSurface67 = Color(0xFF3B2815);
  static const warmSurface68 = Color(0xFF3B2818);
  static const warmSurface69 = Color(0xFF3B2A0E);
  static const warmSurface70 = Color(0xFF3C2006);
  static const warmSurface71 = Color(0xFF3C342E);
  static const blueSurfaceHigh28 = Color(0xFF3C3B6E);
  static const blueMuted09 = Color(0xFF3C6CA8);
  static const greenSurfaceHigh18 = Color(0xFF3C7B42);
  static const warmSurface72 = Color(0xFF3D2612);
  static const tealMuted08 = Color(0xFF3D8B7D);
  static const blueSurfaceHigh29 = Color(0xFF3E346A);
  static const violetSurfaceHigh01 = Color(0xFF3F264F);
  static const blueMuted10 = Color(0xFF3F6EA8);
  static const greenMuted05 = Color(0xFF3F8C62);
  static const redSurface03 = Color(0xFF40201A);
  static const blueMuted11 = Color(0xFF40538F);
  static const greenSurfaceHigh19 = Color(0xFF407D57);
  static const warmSurface73 = Color(0xFF422D1B);
  static const blueMuted12 = Color(0xFF426AA0);
  static const warmSurface74 = Color(0xFF43280D);
  static const warmSurface75 = Color(0xFF432A13);
  static const warmSurface76 = Color(0xFF433124);
  static const blueSoft02 = Color(0xFF43A9DF);
  static const warmSurface77 = Color(0xFF442512);
  static const warmSurface78 = Color(0xFF44301F);
  static const warmSurface79 = Color(0xFF443121);
  static const blueSurfaceHigh30 = Color(0xFF443A73);
  static const neutralSurfaceHigh01 = Color(0xFF444444);
  static const blueMuted13 = Color(0xFF47698A);
  static const greenMuted06 = Color(0xFF477B4B);
  static const blueMuted14 = Color(0xFF496DA0);
  static const blueMuted15 = Color(0xFF496FB0);
  static const warmSurface80 = Color(0xFF4A2305);
  static const warmSurface81 = Color(0xFF4A2B10);
  static const warmSurface82 = Color(0xFF4A2B13);
  static const warmSurface83 = Color(0xFF4A2B1A);
  static const warmSurface84 = Color(0xFF4A2D14);
  static const warmSurface85 = Color(0xFF4A321D);
  static const warmSurfaceHigh01 = Color(0xFF4A3D31);
  static const blueMuted16 = Color(0xFF4A418D);
  static const greenMuted07 = Color(0xFF4AA657);
  static const warmSurface86 = Color(0xFF4B2D13);
  static const warmSurfaceHigh02 = Color(0xFF4B392B);
  static const blueSoft03 = Color(0xFF4BA8FF);
  static const warmSurface87 = Color(0xFF4C2206);
  static const blueMuted17 = Color(0xFF4E86C7);
  static const warmSurface88 = Color(0xFF4F2914);
  static const warmSurface89 = Color(0xFF4F2C08);
  static const blueMuted18 = Color(0xFF4F5C9C);
  static const blueMuted19 = Color(0xFF4F7FAE);
  static const greenMuted08 = Color(0xFF4F8E65);
  static const pinkSurface01 = Color(0xFF501D3D);
  static const greenMuted09 = Color(0xFF509E2F);
  static const blueMuted20 = Color(0xFF516572);
  static const warmSurface90 = Color(0xFF52301B);
  static const warmSurface91 = Color(0xFF52311E);
  static const tealSoft01 = Color(0xFF52B8D9);
  static const warmSurface92 = Color(0xFF533018);
  static const warmSurfaceHigh03 = Color(0xFF534638);
  static const blueSoft04 = Color(0xFF56C4EE);
  static const greenMuted10 = Color(0xFF58C47B);
  static const tealMuted09 = Color(0xFF59B596);
  static const warmSurface93 = Color(0xFF5A1B05);
  static const pinkSurfaceHigh01 = Color(0xFF5A2348);
  static const warmSurface94 = Color(0xFF5A2F13);
  static const pinkSurfaceHigh02 = Color(0xFF5A3055);
  static const warmSurfaceHigh04 = Color(0xFF5A3419);
  static const warmSurface95 = Color(0xFF5A350B);
  static const warmSurfaceHigh05 = Color(0xFF5A3517);
  static const warmSurfaceHigh06 = Color(0xFF5A3519);
  static const violetSurfaceHigh02 = Color(0xFF5A356D);
  static const warmSurface96 = Color(0xFF5A370D);
  static const warmSurfaceHigh07 = Color(0xFF5A493B);
  static const warmSurfaceHigh08 = Color(0xFF5A4B3B);
  static const blueMuted21 = Color(0xFF5A7BC0);
  static const blueMuted22 = Color(0xFF5A88A5);
  static const blueSoft05 = Color(0xFF5A9BC8);
  static const blueSoft06 = Color(0xFF5AA8DF);
  static const redSurfaceHigh01 = Color(0xFF5B2C26);
  static const warmSurface97 = Color(0xFF5C330B);
  static const warmSurfaceHigh09 = Color(0xFF5C5139);
  static const warmSurfaceHigh10 = Color(0xFF5C5147);
  static const violetMuted01 = Color(0xFF5E3E86);
  static const warmSurfaceHigh11 = Color(0xFF5F3D1F);
  static const blueMuted23 = Color(0xFF5F578D);
  static const blueMuted24 = Color(0xFF5F86B3);
  static const tealMuted10 = Color(0xFF5F9E98);
  static const greenSoft01 = Color(0xFF65D08A);
  static const warmSurfaceHigh12 = Color(0xFF66371A);
  static const warmSurfaceHigh13 = Color(0xFF66431E);
  static const blueMuted25 = Color(0xFF665CB6);
  static const blueSoft07 = Color(0xFF67A8F5);
  static const warmSurfaceHigh14 = Color(0xFF6A3D0B);
  static const warmSurfaceHigh15 = Color(0xFF6A410B);
  static const greenMuted11 = Color(0xFF6B8B4A);
  static const tealSoft02 = Color(0xFF6CB5B1);
  static const redSurfaceHigh02 = Color(0xFF6D2418);
  static const redSurfaceHigh03 = Color(0xFF6D2812);
  static const warmSurfaceHigh16 = Color(0xFF6D5141);
  static const warmSurfaceHigh17 = Color(0xFF6E3717);
  static const blueSoft08 = Color(0xFF6E6FB3);
  static const blueMuted26 = Color(0xFF6E78A6);
  static const warmSurfaceHigh18 = Color(0xFF6F3F22);
  static const warmSurfaceHigh19 = Color(0xFF6F5848);
  static const greenMuted12 = Color(0xFF6F8A67);
  static const greenMuted13 = Color(0xFF6F8E55);
  static const greenMuted14 = Color(0xFF6F8F7B);
  static const warmSurfaceHigh20 = Color(0xFF704117);
  static const pinkSurfaceHigh03 = Color(0xFF712651);
  static const warmSurfaceHigh21 = Color(0xFF724720);
  static const violetMuted02 = Color(0xFF7342A4);
  static const warmSurfaceHigh22 = Color(0xFF74411A);
  static const blueSoft09 = Color(0xFF74ACDF);
  static const tealSoft03 = Color(0xFF74CBB5);
  static const tealSoft04 = Color(0xFF74D2AE);
  static const greenSoft02 = Color(0xFF77D88B);
  static const greenSoft03 = Color(0xFF78C36A);
  static const warmSurfaceHigh23 = Color(0xFF7A3602);
  static const warmSurfaceHigh24 = Color(0xFF7A3B18);
  static const warmSurfaceHigh25 = Color(0xFF7A4A08);
  static const violetMuted03 = Color(0xFF7A4D94);
  static const blueSoft10 = Color(0xFF7A88FF);
  static const blueSoft11 = Color(0xFF7AA4C9);
  static const tealSoft05 = Color(0xFF7ABDA9);
  static const greenSoft04 = Color(0xFF7BBE6D);
  static const warmSurfaceHigh26 = Color(0xFF7D3508);
  static const warmMuted01 = Color(0xFF7D6D60);
  static const blueSoft12 = Color(0xFF7D8BAD);
  static const tealSoft06 = Color(0xFF7DD2C7);
  static const tealSoft07 = Color(0xFF7ED7B5);
  static const warmMuted02 = Color(0xFF806F5E);
  static const blueLight01 = Color(0xFF80B7FF);
  static const warmSurfaceHigh27 = Color(0xFF81562A);
  static const blueSoft13 = Color(0xFF81A7B8);
  static const warmSurfaceHigh28 = Color(0xFF8A3009);
  static const warmSurfaceHigh29 = Color(0xFF8A5A2B);
  static const redSurfaceHigh04 = Color(0xFF8B3A2B);
  static const warmSurfaceHigh30 = Color(0xFF8B5506);
  static const violetMuted04 = Color(0xFF8B65A6);
  static const neutralMuted01 = Color(0xFF8B8178);
  static const tealSoft08 = Color(0xFF8BD1E3);
  static const warmSurfaceHigh31 = Color(0xFF8C4022);
  static const warmSurfaceHigh32 = Color(0xFF8C4A24);
  static const warmSurfaceHigh33 = Color(0xFF8C5A16);
  static const warmMuted03 = Color(0xFF8C6239);
  static const neutralMuted02 = Color(0xFF8C8582);
  static const redSurfaceHigh05 = Color(0xFF8D153A);
  static const warmMuted04 = Color(0xFF8D7464);
  static const warmMuted05 = Color(0xFF8D7A68);
  static const blueSoft14 = Color(0xFF8E7CDB);
  static const warmSurfaceHigh34 = Color(0xFF8F4A16);
  static const warmMuted06 = Color(0xFF8F765B);
  static const warmMuted07 = Color(0xFF8F7768);
  static const warmMuted08 = Color(0xFF8F7A66);
  static const warmMuted09 = Color(0xFF8F8378);
  static const greenSoft05 = Color(0xFF8FA18B);
  static const warmMuted10 = Color(0xFF927C67);
  static const neutralSoft01 = Color(0xFF97929A);
  static const pinkMuted01 = Color(0xFF9A3F75);
  static const warmMuted11 = Color(0xFF9A5E39);
  static const warmMuted12 = Color(0xFF9A673A);
  static const warmMuted13 = Color(0xFF9A6A38);
  static const warmMuted14 = Color(0xFF9A856F);
  static const blueSoft15 = Color(0xFF9A89E2);
  static const warmSurfaceHigh35 = Color(0xFF9B4C08);
  static const warmMuted15 = Color(0xFF9B8976);
  static const neutralSoft02 = Color(0xFF9C9695);
  static const warmMuted16 = Color(0xFF9D6437);
  static const warmMuted17 = Color(0xFF9D846B);
  static const warmMuted18 = Color(0xFF9D8877);
  static const amberMuted01 = Color(0xFF9D947F);
  static const warmSurfaceHigh36 = Color(0xFF9E5523);
  static const orangeMuted01 = Color(0xFF9E8B7D);
  static const tealLight01 = Color(0xFF9EDFD3);
  static const orangeMuted02 = Color(0xFF9F8B7D);
  static const warmMuted19 = Color(0xFF9F8D78);
  static const orangeMuted03 = Color(0xFF9F8E7B);
  static const blueLight02 = Color(0xFF9FD0FF);
  static const redSurfaceHigh06 = Color(0xFFA51931);
  static const orangeSoft01 = Color(0xFFA59282);
  static const blueLight03 = Color(0xFFA6ABD8);
  static const greenSoft06 = Color(0xFFA6B686);
  static const violetLight01 = Color(0xFFA78BFA);
  static const orangeSoft02 = Color(0xFFA79D93);
  static const orangeMuted04 = Color(0xFFA98D74);
  static const orangeSoft03 = Color(0xFFA9917B);
  static const orangeSoft04 = Color(0xFFA99586);
  static const greenSoft07 = Color(0xFFA9B6A6);
  static const blueLight04 = Color(0xFFAAA0F0);
  static const blueLight05 = Color(0xFFAEB9D6);
  static const redMuted01 = Color(0xFFAF4C4F);
  static const violetSoft01 = Color(0xFFAFA5BA);
  static const redSurfaceHigh07 = Color(0xFFB00020);
  static const violetLight02 = Color(0xFFB08CF6);
  static const redMuted02 = Color(0xFFB22234);
  static const orangeSoft05 = Color(0xFFB3A28D);
  static const warmSurfaceHigh37 = Color(0xFFB45309);
  static const orangeSoft06 = Color(0xFFB5A394);
  static const orangeSoft07 = Color(0xFFB5A694);
  static const warmMuted20 = Color(0xFFB65C38);
  static const redMuted03 = Color(0xFFB65C73);
  static const warmMuted21 = Color(0xFFB67A33);
  static const orangeSoft08 = Color(0xFFB69B78);
  static const greenSoft08 = Color(0xFFB6F36C);
  static const warmMuted22 = Color(0xFFB76821);
  static const neutralSoft03 = Color(0xFFB7B2BD);
  static const blueLight06 = Color(0xFFB7D2E7);
  static const orangeSoft09 = Color(0xFFB8A68E);
  static const orangeSoft10 = Color(0xFFB8A898);
  static const orangeSoft11 = Color(0xFFB8AB9D);
  static const orangeSoft12 = Color(0xFFB8B0AA);
  static const neutralSoft04 = Color(0xFFB8B3B4);
  static const greenSoft09 = Color(0xFFB8DB95);
  static const tealLight02 = Color(0xFFB8F6DF);
  static const redMuted04 = Color(0xFFB94A48);
  static const redMuted05 = Color(0xFFB95A55);
  static const warmMuted23 = Color(0xFFB95D28);
  static const warmMuted24 = Color(0xFFB9763D);
  static const amberMuted02 = Color(0xFFB99562);
  static const orangeSoft13 = Color(0xFFB9A48D);
  static const amberSoft01 = Color(0xFFB9A88F);
  static const orangeSoft14 = Color(0xFFB9A99A);
  static const blueLight07 = Color(0xFFB9CAD5);
  static const orangeSoft15 = Color(0xFFBAAB9D);
  static const redSurfaceHigh08 = Color(0xFFBB0000);
  static const redSurfaceHigh09 = Color(0xFFBC002D);
  static const orangeSoft16 = Color(0xFFBDA393);
  static const orangeSoft17 = Color(0xFFBDAA98);
  static const greenLight01 = Color(0xFFBDEBCB);
  static const amberMuted03 = Color(0xFFBE965D);
  static const orangeSoft18 = Color(0xFFBFA78E);
  static const blueLight08 = Color(0xFFBFE6F3);
  static const warmSurfaceHigh38 = Color(0xFFC09300);
  static const redMuted06 = Color(0xFFC1272D);
  static const redMuted07 = Color(0xFFC44456);
  static const warmMuted25 = Color(0xFFC45D24);
  static const orangeSoft19 = Color(0xFFC4A27D);
  static const redMuted08 = Color(0xFFC53D42);
  static const violetSoft02 = Color(0xFFC58EDC);
  static const redMuted09 = Color(0xFFC60C30);
  static const redMuted10 = Color(0xFFC6363C);
  static const orangeSoft20 = Color(0xFFC6B6A7);
  static const orangeSoft21 = Color(0xFFC7AD92);
  static const orangeSoft22 = Color(0xFFC7B19B);
  static const orangeSoft23 = Color(0xFFC7B49F);
  static const redMuted11 = Color(0xFFC8102E);
  static const redMuted12 = Color(0xFFC8313E);
  static const redMuted13 = Color(0xFFC8404F);
  static const redMuted14 = Color(0xFFC84E44);
  static const redSoft01 = Color(0xFFC85A65);
  static const orangeSoft24 = Color(0xFFC8AD9C);
  static const orangeSoft25 = Color(0xFFC8B39A);
  static const greenLight02 = Color(0xFFC8CDB5);
  static const redMuted15 = Color(0xFFC94C4C);
  static const redMuted16 = Color(0xFFC95353);
  static const redSoft02 = Color(0xFFC96B70);
  static const amberSoft02 = Color(0xFFC9AF89);
  static const orangeSoft26 = Color(0xFFC9B09B);
  static const tealLight03 = Color(0xFFC9EDF6);
  static const orangeSoft27 = Color(0xFFCA9A6D);
  static const orangeSoft28 = Color(0xFFCAB9A5);
  static const pinkSoft01 = Color(0xFFCB6BA6);
  static const pinkSoft02 = Color(0xFFCB84BA);
  static const orangeMuted05 = Color(0xFFCB8B50);
  static const orangeSoft29 = Color(0xFFCBB8A3);
  static const blueLight09 = Color(0xFFCBE6F1);
  static const redMuted17 = Color(0xFFCC0000);
  static const redMuted18 = Color(0xFFCC0001);
  static const redMuted19 = Color(0xFFCC142B);
  static const redMuted20 = Color(0xFFCD2E3A);
  static const orangeSoft30 = Color(0xFFCDB9A5);
  static const orangeSoft31 = Color(0xFFCDB9A8);
  static const amberSoft03 = Color(0xFFCDBEA7);
  static const redMuted21 = Color(0xFFCE1126);
  static const redMuted22 = Color(0xFFCF142B);
  static const warmMuted26 = Color(0xFFD17618);
  static const redMuted23 = Color(0xFFD21034);
  static const orangeLight01 = Color(0xFFD3BFA9);
  static const blueWash01 = Color(0xFFD3E8FA);
  static const orangeLight02 = Color(0xFFD4BEA8);
  static const redMuted24 = Color(0xFFD52B1E);
  static const warmMuted27 = Color(0xFFD56D11);
  static const orangeLight03 = Color(0xFFD5C0B2);
  static const redMuted25 = Color(0xFFD62828);
  static const redMuted26 = Color(0xFFD64C3C);
  static const orangeLight04 = Color(0xFFD6BDAB);
  static const amberSoft04 = Color(0xFFD6BF94);
  static const orangeLight05 = Color(0xFFD6C1B3);
  static const orangeLight06 = Color(0xFFD6C5B8);
  static const amberLight01 = Color(0xFFD6C7B1);
  static const greenLight03 = Color(0xFFD6F2B8);
  static const redMuted27 = Color(0xFFD7141A);
  static const orangeLight07 = Color(0xFFD7BFAA);
  static const orangeLight08 = Color(0xFFD7C5B2);
  static const orangeLight09 = Color(0xFFD7C7BB);
  static const blueWash02 = Color(0xFFD7D2FF);
  static const redMuted28 = Color(0xFFD80621);
  static const redMuted29 = Color(0xFFD85B3E);
  static const orangeLight10 = Color(0xFFD8C0A2);
  static const orangeLight11 = Color(0xFFD8C2AD);
  static const orangeLight12 = Color(0xFFD8C2B3);
  static const orangeLight13 = Color(0xFFD8C3AA);
  static const orangeLight14 = Color(0xFFD8C6B4);
  static const orangeLight15 = Color(0xFFD8C7B7);
  static const orangeLight16 = Color(0xFFD8CABC);
  static const redMuted30 = Color(0xFFD90012);
  static const redSoft03 = Color(0xFFD97A6A);
  static const orangeLight17 = Color(0xFFD9C4B5);
  static const orangeLight18 = Color(0xFFD9C8B8);
  static const redMuted31 = Color(0xFFDA2032);
  static const redMuted32 = Color(0xFFDA251D);
  static const redMuted33 = Color(0xFFDC143C);
  static const redMuted34 = Color(0xFFDC1E35);
  static const orangeLight19 = Color(0xFFDCC7AF);
  static const orangeLight20 = Color(0xFFDCCAB7);
  static const redMuted35 = Color(0xFFDE2910);
  static const pinkSoft03 = Color(0xFFE040FB);
  static const warmMuted28 = Color(0xFFE07A22);
  static const pinkSoft04 = Color(0xFFE07AB8);
  static const violetLight03 = Color(0xFFE0C3EF);
  static const orangeLight21 = Color(0xFFE0C8AE);
  static const amberSoft05 = Color(0xFFE1C071);
  static const redSoft04 = Color(0xFFE28A7E);
  static const blueWash03 = Color(0xFFE2DDFF);
  static const redMuted36 = Color(0xFFE30A17);
  static const orangeSoft32 = Color(0xFFE39A47);
  static const amberLight02 = Color(0xFFE3CBA5);
  static const redSoft05 = Color(0xFFE47F78);
  static const orangeSoft33 = Color(0xFFE48D44);
  static const pinkSoft05 = Color(0xFFE540A4);
  static const warmMuted29 = Color(0xFFE56F00);
  static const pinkSoft06 = Color(0xFFE58BBE);
  static const amberSoft06 = Color(0xFFE5C48D);
  static const orangeSoft34 = Color(0xFFE69B4B);
  static const orangeLight22 = Color(0xFFE6CDB8);
  static const amberSoft07 = Color(0xFFE7C38A);
  static const orangeLight23 = Color(0xFFE7C9AD);
  static const redMuted37 = Color(0xFFE8112D);
  static const orangeLight24 = Color(0xFFE8D1BF);
  static const amberLight03 = Color(0xFFE8D3B0);
  static const orangeLight25 = Color(0xFFE8DDD2);
  static const warmMuted30 = Color(0xFFE98409);
  static const orangeLight26 = Color(0xFFEAD7C0);
  static const orangeLight27 = Color(0xFFEAD8C2);
  static const orangeLight28 = Color(0xFFEADCD0);
  static const orangeLight29 = Color(0xFFEBD6BE);
  static const blueWash04 = Color(0xFFEEF3F6);
  static const redSoft06 = Color(0xFFEF3340);
  static const orangeLight30 = Color(0xFFEFDCC8);
  static const orangeWash01 = Color(0xFFEFE7DF);
  static const amberSoft08 = Color(0xFFF0B150);
  static const orangeSoft35 = Color(0xFFF0B983);
  static const violetWash01 = Color(0xFFF0D4FF);
  static const amberLight04 = Color(0xFFF0D6A8);
  static const orangeLight31 = Color(0xFFF0DFC8);
  static const orangeSoft36 = Color(0xFFF1A234);
  static const orangeSoft37 = Color(0xFFF1B36B);
  static const orangeLight32 = Color(0xFFF1E4D3);
  static const orangeWash02 = Color(0xFFF1EBE3);
  static const redLight01 = Color(0xFFF2A099);
  static const warmMuted31 = Color(0xFFF2A800);
  static const amberSoft09 = Color(0xFFF2B84B);
  static const orangeLight33 = Color(0xFFF2E5D7);
  static const orangeWash03 = Color(0xFFF2E7DA);
  static const orangeWash04 = Color(0xFFF2E7DD);
  static const orangeLight34 = Color(0xFFF3D7B3);
  static const orangeLight35 = Color(0xFFF3DFC8);
  static const orangeWash05 = Color(0xFFF3E8DC);
  static const amberWash01 = Color(0xFFF3EFE2);
  static const warmMuted32 = Color(0xFFF4A020);
  static const orangeSoft38 = Color(0xFFF4BD74);
  static const orangeSoft39 = Color(0xFFF4C07D);
  static const orangeWash06 = Color(0xFFF4E7D8);
  static const orangeWash07 = Color(0xFFF4E8DA);
  static const orangeWash08 = Color(0xFFF4EEE8);
  static const amberWash02 = Color(0xFFF4F1EB);
  static const orangeSoft40 = Color(0xFFF5B05A);
  static const pinkLight01 = Color(0xFFF5BEDD);
  static const orangeLight36 = Color(0xFFF5DEC2);
  static const orangeWash09 = Color(0xFFF5E9DA);
  static const orangeWash10 = Color(0xFFF5EDE6);
  static const orangeWash11 = Color(0xFFF5EFE8);
  static const orangeWash12 = Color(0xFFF5F2EF);
  static const amberWash03 = Color(0xFFF5F3EF);
  static const warmMuted33 = Color(0xFFF6B40E);
  static const orangeLight37 = Color(0xFFF6DEC2);
  static const orangeLight38 = Color(0xFFF6E5D4);
  static const orangeWash13 = Color(0xFFF6EDE2);
  static const orangeWash14 = Color(0xFFF6F1EA);
  static const orangeSoft41 = Color(0xFFF7A541);
  static const amberSoft10 = Color(0xFFF7B955);
  static const warmMuted34 = Color(0xFFF7C800);
  static const orangeWash15 = Color(0xFFF7EBDD);
  static const amberWash04 = Color(0xFFF7F2EA);
  static const orangeWash16 = Color(0xFFF7F4F1);
  static const redMuted38 = Color(0xFFF83600);
  static const warmMuted35 = Color(0xFFF8C300);
  static const orangeWash17 = Color(0xFFF8E8D7);
  static const orangeWash18 = Color(0xFFF8E9DC);
  static const orangeWash19 = Color(0xFFF9F0E4);
  static const warmMuted36 = Color(0xFFFCD116);
  static const amberSoft11 = Color(0xFFFCD856);
  static const orangeWash20 = Color(0xFFFDF9F4);
  static const warmMuted37 = Color(0xFFFE8C00);
  static const warmMuted38 = Color(0xFFFECC00);
  static const redMuted39 = Color(0xFFFF0000);
  static const warmMuted39 = Color(0xFFFF4A00);
  static const warmMuted40 = Color(0xFFFF5C00);
  static const orangeSoft42 = Color(0xFFFF6B2C);
  static const redSoft07 = Color(0xFFFF6B57);
  static const redSoft08 = Color(0xFFFF6B5F);
  static const warmMuted41 = Color(0xFFFF7600);
  static const redSoft09 = Color(0xFFFF7A70);
  static const redSoft10 = Color(0xFFFF7B6E);
  static const warmMuted42 = Color(0xFFFF7F00);
  static const warmMuted43 = Color(0xFFFF8908);
  static const redSoft11 = Color(0xFFFF8A65);
  static const redSoft12 = Color(0xFFFF8A76);
  static const warmMuted44 = Color(0xFFFF9300);
  static const warmMuted45 = Color(0xFFFF9800);
  static const warmMuted46 = Color(0xFFFF9900);
  static const orangeSoft43 = Color(0xFFFF9933);
  static const warmMuted47 = Color(0xFFFF9B0D);
  static const orangeMuted06 = Color(0xFFFF9C1E);
  static const warmMuted48 = Color(0xFFFF9D00);
  static const warmMuted49 = Color(0xFFFF9F05);
  static const orangeMuted07 = Color(0xFFFF9F1A);
  static const orangeSoft44 = Color(0xFFFFA657);
  static const orangeSoft45 = Color(0xFFFFA65F);
  static const orangeSoft46 = Color(0xFFFFAD3F);
  static const amberSoft12 = Color(0xFFFFB02E);
  static const amberMuted04 = Color(0xFFFFB11E);
  static const amberSoft13 = Color(0xFFFFB13B);
  static const redLight02 = Color(0xFFFFB199);
  static const amberSoft14 = Color(0xFFFFB347);
  static const orangeLight39 = Color(0xFFFFB49A);
  static const redLight03 = Color(0xFFFFB4A8);
  static const redLight04 = Color(0xFFFFB4AB);
  static const amberSoft15 = Color(0xFFFFB547);
  static const amberSoft16 = Color(0xFFFFB64D);
  static const warmMuted50 = Color(0xFFFFB700);
  static const amberSoft17 = Color(0xFFFFB74D);
  static const redLight05 = Color(0xFFFFB7A8);
  static const amberSoft18 = Color(0xFFFFBD55);
  static const amberSoft19 = Color(0xFFFFBD5A);
  static const orangeLight40 = Color(0xFFFFC09A);
  static const redLight06 = Color(0xFFFFC0B8);
  static const orangeLight41 = Color(0xFFFFC1A8);
  static const amberSoft20 = Color(0xFFFFC247);
  static const amberSoft21 = Color(0xFFFFC46A);
  static const amberSoft22 = Color(0xFFFFC46B);
  static const amberSoft23 = Color(0xFFFFC56A);
  static const amberSoft24 = Color(0xFFFFC857);
  static const warmMuted51 = Color(0xFFFFCC00);
  static const amberLight05 = Color(0xFFFFD083);
  static const amberLight06 = Color(0xFFFFD08A);
  static const orangeLight42 = Color(0xFFFFD09A);
  static const orangeLight43 = Color(0xFFFFD0A1);
  static const redLight07 = Color(0xFFFFD0C1);
  static const warmMuted52 = Color(0xFFFFD100);
  static const amberSoft25 = Color(0xFFFFD166);
  static const pinkWash01 = Color(0xFFFFD1EC);
  static const orangeLight44 = Color(0xFFFFD29A);
  static const orangeLight45 = Color(0xFFFFD4C5);
  static const orangeLight46 = Color(0xFFFFD6A3);
  static const redWash01 = Color(0xFFFFD6CC);
  static const warmMuted53 = Color(0xFFFFD700);
  static const amberLight07 = Color(0xFFFFD89A);
  static const warmMuted54 = Color(0xFFFFD900);
  static const orangeLight47 = Color(0xFFFFD9A8);
  static const warmMuted55 = Color(0xFFFFDE00);
  static const orangeLight48 = Color(0xFFFFDEB6);
  static const warmMuted56 = Color(0xFFFFDF00);
  static const amberLight08 = Color(0xFFFFE0B2);
  static const amberLight09 = Color(0xFFFFE1AE);
  static const amberLight10 = Color(0xFFFFE2AD);
  static const amberLight11 = Color(0xFFFFE2B5);
  static const amberLight12 = Color(0xFFFFE2B8);
  static const amberLight13 = Color(0xFFFFE3B8);
  static const orangeLight49 = Color(0xFFFFE4C4);
  static const redWash02 = Color(0xFFFFE4E4);
  static const amberLight14 = Color(0xFFFFE5BC);
  static const amberLight15 = Color(0xFFFFE5BF);
  static const orangeLight50 = Color(0xFFFFE5C2);
  static const amberLight16 = Color(0xFFFFE6B4);
  static const amberLight17 = Color(0xFFFFE6B8);
  static const amberWash05 = Color(0xFFFFF1D6);
  static const orangeWash21 = Color(0xFFFFF3E8);
  static const amberWash06 = Color(0xFFFFF4DE);
  static const orangeWash22 = Color(0xFFFFF4E5);
  static const orangeWash23 = Color(0xFFFFF5E8);
  static const orangeWash24 = Color(0xFFFFF6EA);
  static const amberWash07 = Color(0xFFFFF7E6);
  static const amberWash08 = Color(0xFFFFF7EA);
  static const orangeWash25 = Color(0xFFFFF7EC);
  static const orangeWash26 = Color(0xFFFFF8EF);
  static const orangeWash27 = Color(0xFFFFF8F0);
  static const amberWash09 = Color(0xFFFFF9F0);
  static const amberWash10 = Color(0xFFFFFAF2);
  static const orangeWash28 = Color(0xFFFFFAF4);
  static const orangeWash29 = Color(0xFFFFFAF5);
  static const orangeWash30 = Color(0xFFFFFBF6);
  static const warmSurface98 = Color(0xFF2B170C);
  // End generated palette tokens.

  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const white54 = Color(0x8AFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const materialDanger = Color(0xFFF44336);
  static const dangerAccent = Color(0xFFFF5252);
  static const materialDangerAccent = dangerAccent;
  static const textCoolSecondary = Color(0xFF94A3B8);
  static const outlineOverlay = Color(0x14FFFFFF);
  static const outlineOverlaySoft = Color(0x0FFFFFFF);
  static const outlineOverlayLight = outlineOverlaySoft;
  static const outlineOverlayFaint = Color(0x0CFFFFFF);
  static const surfaceCoolLight = surfaceLight;
}

abstract final class AppGradients {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C1007), AppPalette.background],
  );

  static const surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.surfaceRaised, AppPalette.surface],
  );

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.primarySoft, AppPalette.primary],
  );
}

abstract final class AppSpacing {
  static const zero = 0.0;
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 48.0;
}

abstract final class AppInsets {
  static const none = EdgeInsets.zero;
  static const allXs = EdgeInsets.all(AppSpacing.xs);
  static const allSm = EdgeInsets.all(AppSpacing.sm);
  static const allMd = EdgeInsets.all(AppSpacing.md);
  static const allLg = EdgeInsets.all(AppSpacing.lg);
  static const allXl = EdgeInsets.all(AppSpacing.xl);

  static const card = EdgeInsets.all(AppSpacing.lg);
  static const panel = EdgeInsets.all(AppSpacing.xl);
  static const chip = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );
  static const button = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
  static const listItem = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );

  static EdgeInsets page(BuildContext context) =>
      AppAdaptive.of(context).pagePadding;
}

abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 18.0;
  static const xxl = 22.0;
  static const sheet = 28.0;
  static const full = 999.0;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const compactCard = BorderRadius.all(Radius.circular(sm));
  static const panel = BorderRadius.all(Radius.circular(xxl));
  static const input = BorderRadius.all(Radius.circular(lg));
  static const button = BorderRadius.all(Radius.circular(lg));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
  static const pill = BorderRadius.all(Radius.circular(full));
}

abstract final class AppSizes {
  static const minTapTarget = 48.0;
  static const minDenseTapTarget = 44.0;
  static const iconXs = 16.0;
  static const iconSm = 18.0;
  static const iconMd = 22.0;
  static const iconLg = 28.0;
  static const avatarSm = 32.0;
  static const avatarMd = 44.0;
  static const avatarLg = 64.0;
  static const bottomNavHeight = 64.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const slow = Duration(milliseconds: 260);

  static const curve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeInOutCubic;
}

abstract final class AppTypography {
  static const fontFamily = 'Inter';

  static const display = 32.0;
  static const headline = 24.0;
  static const titleLarge = 20.0;
  static const title = 18.0;
  static const subtitle = 16.0;
  static const body = 14.0;
  static const bodySmall = 13.0;
  static const caption = 12.0;
  static const micro = 11.0;

  static const TextStyle displayStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: display,
    height: 1.08,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle headlineStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: headline,
    height: 1.12,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle titleLargeStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: titleLarge,
    height: 1.18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle titleStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: title,
    height: 1.22,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: subtitle,
    height: 1.28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: body,
    height: 1.42,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle bodyStrongStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: body,
    height: 1.36,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle captionStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: caption,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static TextTheme textTheme() {
    return const TextTheme(
      displaySmall: displayStyle,
      headlineSmall: headlineStyle,
      titleLarge: titleLargeStyle,
      titleMedium: titleStyle,
      titleSmall: subtitleStyle,
      bodyLarge: bodyStyle,
      bodyMedium: bodyStyle,
      bodySmall: captionStyle,
      labelLarge: bodyStrongStyle,
      labelMedium: captionStyle,
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: micro,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

abstract final class AppBorders {
  static const soft = BorderSide(color: AppPalette.borderSoft);
  static const defaultBorder = BorderSide(color: AppPalette.border);
  static const strong = BorderSide(color: AppPalette.borderStrong);
  static const focus = BorderSide(color: AppPalette.primary, width: 1.4);
  static const danger = BorderSide(color: AppPalette.danger, width: 1.4);
}

abstract final class AppShadows {
  static List<BoxShadow> get low => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.26),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: AppPalette.primary.withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

abstract final class AppDecorations {
  static BoxDecoration screenBackground() {
    return const BoxDecoration(gradient: AppGradients.background);
  }

  static BoxDecoration card({bool elevated = false}) {
    return BoxDecoration(
      color: AppPalette.surface,
      borderRadius: AppRadius.card,
      border: const Border.fromBorderSide(AppBorders.defaultBorder),
      boxShadow: elevated ? AppShadows.low : null,
    );
  }

  static BoxDecoration raisedCard() {
    return BoxDecoration(
      gradient: AppGradients.surface,
      borderRadius: AppRadius.panel,
      border: const Border.fromBorderSide(AppBorders.strong),
      boxShadow: AppShadows.medium,
    );
  }

  static BoxDecoration input() {
    return const BoxDecoration(
      color: AppPalette.surfaceRaised,
      borderRadius: AppRadius.input,
      border: Border.fromBorderSide(AppBorders.defaultBorder),
    );
  }

  static BoxDecoration pill({
    Color background = AppPalette.surfaceRaised,
    Color border = AppPalette.border,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: AppRadius.pill,
      border: Border.all(color: border),
    );
  }

  static BoxDecoration status({required Color color, double alpha = 0.14}) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: AppRadius.pill,
      border: Border.all(color: color.withValues(alpha: 0.28)),
    );
  }
}

abstract final class AppButtonStyles {
  static ButtonStyle primary() {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, AppSizes.minTapTarget),
      padding: AppInsets.button,
      backgroundColor: AppPalette.primary,
      foregroundColor: AppPalette.onPrimary,
      disabledBackgroundColor: AppPalette.surfaceMuted,
      disabledForegroundColor: AppPalette.textDisabled,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.bodyStrongStyle,
    );
  }

  static ButtonStyle secondary() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppSizes.minTapTarget),
      padding: AppInsets.button,
      foregroundColor: AppPalette.primary,
      disabledForegroundColor: AppPalette.textDisabled,
      side: const BorderSide(color: AppPalette.primary),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.bodyStrongStyle,
    );
  }

  static ButtonStyle ghost() {
    return TextButton.styleFrom(
      minimumSize: const Size(0, AppSizes.minDenseTapTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      foregroundColor: AppPalette.primary,
      disabledForegroundColor: AppPalette.textDisabled,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.bodyStrongStyle,
    );
  }

  static ButtonStyle destructive() {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, AppSizes.minTapTarget),
      padding: AppInsets.button,
      backgroundColor: AppPalette.danger,
      foregroundColor: AppPalette.textPrimary,
      disabledBackgroundColor: AppPalette.surfaceMuted,
      disabledForegroundColor: AppPalette.textDisabled,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
      textStyle: AppTypography.bodyStrongStyle,
    );
  }

  static ButtonStyle icon() {
    return IconButton.styleFrom(
      minimumSize: const Size.square(AppSizes.minDenseTapTarget),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: AppPalette.primary.withValues(alpha: 0.12),
      foregroundColor: AppPalette.primary,
      disabledForegroundColor: AppPalette.textDisabled,
      shape: const CircleBorder(),
    );
  }
}

abstract final class AppInputDecorations {
  static InputDecoration textField({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorMaxLines: 3,
    );
  }

  static OutlineInputBorder border([
    BorderSide side = AppBorders.defaultBorder,
  ]) {
    return OutlineInputBorder(borderRadius: AppRadius.input, borderSide: side);
  }
}

abstract final class AppStateStyles {
  static const emptyIcon = IconThemeData(color: AppPalette.primary, size: 52);
  static const errorIcon = IconThemeData(color: AppPalette.danger, size: 52);

  static TextStyle title(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.titleMedium!.copyWith(color: AppPalette.textPrimary);
  }

  static TextStyle message(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: AppPalette.textSecondary);
  }
}

abstract final class AppTheme {
  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppPalette.primary,
          onPrimary: AppPalette.onPrimary,
          secondary: AppPalette.primarySoft,
          onSecondary: AppPalette.onPrimary,
          tertiary: AppPalette.info,
          onTertiary: AppPalette.backgroundDeep,
          error: AppPalette.danger,
          onError: AppPalette.textPrimary,
          surface: AppPalette.surface,
          onSurface: AppPalette.textPrimary,
          surfaceContainerHighest: AppPalette.surfaceRaised,
          outline: AppPalette.border,
          outlineVariant: AppPalette.borderSoft,
          scrim: AppPalette.scrim,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme().apply(
        bodyColor: AppPalette.textPrimary,
        displayColor: AppPalette.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.textPrimary,
        titleTextStyle: AppTypography.titleLargeStyle,
      ),
      dividerColor: AppPalette.divider,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.panel),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppPalette.surface,
        modalBarrierColor: AppPalette.scrim,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: AppBorders.defaultBorder,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: AppInputDecorations.border(),
        enabledBorder: AppInputDecorations.border(),
        focusedBorder: AppInputDecorations.border(AppBorders.focus),
        errorBorder: AppInputDecorations.border(AppBorders.danger),
        focusedErrorBorder: AppInputDecorations.border(AppBorders.danger),
        labelStyle: AppTypography.bodyStyle.copyWith(
          color: AppPalette.textMuted,
        ),
        floatingLabelStyle: AppTypography.captionStyle.copyWith(
          color: AppPalette.primary,
        ),
        hintStyle: AppTypography.bodyStyle.copyWith(
          color: AppPalette.textMuted,
        ),
        errorStyle: AppTypography.captionStyle.copyWith(
          color: AppPalette.danger,
        ),
        prefixIconColor: AppPalette.primary,
        suffixIconColor: AppPalette.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: AppButtonStyles.primary(),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.secondary(),
      ),
      textButtonTheme: TextButtonThemeData(style: AppButtonStyles.ghost()),
      iconButtonTheme: IconButtonThemeData(style: AppButtonStyles.icon()),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary.withValues(alpha: 0.22);
          }
          return AppPalette.primary.withValues(alpha: 0.12);
        }),
        labelStyle: AppTypography.captionStyle.copyWith(
          color: AppPalette.textPrimary,
        ),
        secondaryLabelStyle: AppTypography.captionStyle.copyWith(
          color: AppPalette.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppPalette.primary),
        side: const BorderSide(color: AppPalette.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.surfaceHigh,
        contentTextStyle: AppTypography.bodyStyle.copyWith(
          color: AppPalette.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppPalette.primary,
        selectionColor: AppPalette.primary.withValues(alpha: 0.28),
        selectionHandleColor: AppPalette.primary,
      ),
    );
  }
}

class AppDesignSystemPreview extends StatelessWidget {
  const AppDesignSystemPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppDesignSystem.darkTheme(),
      child: Builder(
        builder: (context) {
          final adaptive = AppAdaptive.of(context);

          return Scaffold(
            body: DecoratedBox(
              decoration: AppDecorations.screenBackground(),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: adaptive.contentConstraints,
                    child: ListView(
                      padding: adaptive.pagePadding,
                      children: const [
                        _PreviewHero(),
                        SizedBox(height: AppSpacing.xl),
                        _PreviewColorSection(),
                        SizedBox(height: AppSpacing.xl),
                        _PreviewTypographySection(),
                        SizedBox(height: AppSpacing.xl),
                        _PreviewComponentsSection(),
                        SizedBox(height: AppSpacing.xl),
                        _PreviewStateSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.raisedCard(),
      child: Padding(
        padding: AppInsets.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppDesignSystem.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppPalette.textWarm),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Preview tokens for Flutter screens: palette, typography, spacing, surfaces, buttons, inputs, chips, and state blocks.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewColorSection extends StatelessWidget {
  const _PreviewColorSection();

  @override
  Widget build(BuildContext context) {
    return const _PreviewSection(
      title: 'Palette',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          _ColorSwatch('Primary', AppPalette.primary),
          _ColorSwatch('Primary soft', AppPalette.primarySoft),
          _ColorSwatch('Background', AppPalette.background),
          _ColorSwatch('Surface', AppPalette.surface),
          _ColorSwatch('Raised', AppPalette.surfaceRaised),
          _ColorSwatch('Text', AppPalette.textPrimary),
          _ColorSwatch('Muted', AppPalette.textMuted),
          _ColorSwatch('Success', AppPalette.success),
          _ColorSwatch('Warning', AppPalette.warning),
          _ColorSwatch('Danger', AppPalette.danger),
        ],
      ),
    );
  }
}

class _PreviewTypographySection extends StatelessWidget {
  const _PreviewTypographySection();

  @override
  Widget build(BuildContext context) {
    return _PreviewSection(
      title: 'Typography',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display / 32 / w900', style: AppTypography.displayStyle),
          const SizedBox(height: AppSpacing.sm),
          Text('Headline / 24 / w900', style: AppTypography.headlineStyle),
          const SizedBox(height: AppSpacing.sm),
          Text('Title / 18 / w800', style: AppTypography.titleStyle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Body copy keeps system text scaling and wraps naturally on compact devices.',
            style: AppTypography.bodyStyle.copyWith(
              color: AppPalette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Caption / 12 / w700',
            style: AppTypography.captionStyle.copyWith(
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewComponentsSection extends StatelessWidget {
  const _PreviewComponentsSection();

  @override
  Widget build(BuildContext context) {
    return _PreviewSection(
      title: 'Components',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Primary')),
              OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
              TextButton(onPressed: () {}, child: const Text('Ghost')),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            decoration: AppInputDecorations.textField(
              label: 'Search',
              hint: 'City, route, activity',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              Chip(label: Text('Activity')),
              Chip(label: Text('Guide')),
              Chip(label: Text('Route')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewStateSection extends StatelessWidget {
  const _PreviewStateSection();

  @override
  Widget build(BuildContext context) {
    return _PreviewSection(
      title: 'States',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: const [
          _StateCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading',
            message: 'Use skeletons or compact progress indicators.',
          ),
          _StateCard(
            icon: Icons.inbox_rounded,
            title: 'Empty',
            message: 'Explain the next useful action.',
          ),
          _StateCard(
            icon: Icons.error_outline_rounded,
            title: 'Error',
            message: 'Show recovery, retry, and safe fallback.',
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.card(elevated: true),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.compactCard,
              border: Border.all(color: AppPalette.borderSoft),
            ),
            child: const SizedBox(height: 64, width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppPalette.danger : AppPalette.primary;

    return SizedBox(
      width: 220,
      child: DecoratedBox(
        decoration: AppDecorations.status(color: color, alpha: 0.10),
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: AppSizes.iconLg),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppStateStyles.title(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(message, style: AppStateStyles.message(context)),
            ],
          ),
        ),
      ),
    );
  }
}
