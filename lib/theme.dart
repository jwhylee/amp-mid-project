// S-2 브랜드 색과 모양 — 현행 앱(뮬) 색을 바탕으로 한 보라 계열 + 주황 강조.
//   그라데이션 헤더(마젠타 → 보라 → 파랑) · 연한 보라 회색 배경 · 흰 둥근 카드(16) · 알약 모양 탭.
//   모든 화면이 이 테마 하나만 쓴다 → 같은 자리 · 같은 모양 (P04 일관성).
import 'package:flutter/material.dart';

const muleMagenta = Color(0xFFD12FC8);
const mulePurple = Color(0xFF8A3FD6);
const muleBlue = Color(0xFF4A62EE);

/// 강조색 — 새 글 수 · 선택된 게시판처럼 "지금 봐야 할 것"에만 쓴다
const muleOrange = Color(0xFFF2661B);

/// 배경 · 테두리 · 글자
const muleBackground = Color(0xFFF5F3FA);
const muleLine = Color(0xFFE8E3F1);
const muleInk = Color(0xFF1E1A2B);

/// 보조 글자 (조건 줄 · 날짜 · 설명)
const muleSubtle = Color(0xFF6B6578);

/// 헤더 그라데이션 — 가로 방향이라 AppBar와 그 아래 상자를 이어 붙여도 색이 맞는다
const muleGradient = LinearGradient(
  colors: [muleMagenta, mulePurple, muleBlue],
);

ThemeData buildMuleTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: mulePurple,
    primary: mulePurple,
    secondary: muleOrange,
    surface: Colors.white,
  );
  final rounded16 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  final rounded14 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: muleBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: muleBackground,
      foregroundColor: muleInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded16.copyWith(side: const BorderSide(color: muleLine)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: mulePurple.withValues(alpha: 0.14),
      side: const BorderSide(color: muleLine),
      shape: const StadiumBorder(),
      // 한글 글꼴이 칩 안에서 아래가 잘리지 않게 줄 높이를 조금 준다
      labelStyle: const TextStyle(color: muleInk, height: 1.35),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // 흰 다이얼로그 안에서도 입력칸이 보이게 연한 바탕 (헤더 안 A-2는 흰색으로 따로 정한다)
      fillColor: muleBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(
        color: mulePurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: mulePurple,
      unselectedLabelColor: const Color(0xFF7A7488),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      splashBorderRadius: BorderRadius.circular(20),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: mulePurple.withValues(alpha: 0.14),
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: Colors.black26,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded14,
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: rounded14,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: mulePurple),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: muleBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
    listTileTheme: ListTileThemeData(shape: rounded14),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
