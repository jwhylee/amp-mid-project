// MuBase v2 — GAI3008 중간고사 (UI만 구현)
//
// ── 디자인 가이드 대응표: 화면 S — 앱 뼈대 · 하단 메뉴 (docs/디자인가이드.md 3장과 같게) ──
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준 | 원칙 | 편의성 포인트 |
// |---|---|---|---|---|---|
// | S-1 | MaterialApp | MuBase v2 | 앱 이름 | — | — |
// | S-2 | ThemeData(theme.dart) | 브랜드 색 | 뮬 그라데이션 헤더 · 흰 둥근 카드 · 주황은 새 소식에만 | P04 · 모든 화면 같은 색 · 모양 | 어느 화면이든 같은 자리 · 같은 모양 |
// | S-3 | NavigationBar | 하단 메뉴 | 홈 · 게시판 · 알림 · 설정 4개 · 아이콘 + 이름 | P04 · P06 · 메뉴를 보고 고르기 | 어느 메뉴에서든 한 번에 다른 메뉴로 |
// 화면 흐름(docs/디자인가이드.md 1장과 같게):
//   S-3 하단 메뉴 (옆으로: NavigationBar) ─ A 통합 홈 | D 게시판 | E 알림 | F 설정
//   A 통합 홈 ──덮기(BottomSheet)──▶ C AI 검색 확인 시트 ──쌓기(push)──▶ B 게시글 상세 [옆으로(tab): 글 내용 | AI 상태 체크 | 시세 | 사양 | 후기]
//   A 내 알림 조건 · E 알림 ──덮기──▶ C   ·   새 글 카드 ──쌓기──▶ B
//   A 게시판 바로가기 ──옆으로──▶ D 게시판 ──쌓기(push)──▶ B 게시글 상세
// 기획 문서에 없는 화면은 만들지 않는다(감점). 화면을 늘리면 이 주석·가이드도 같이 고친다.
import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'theme.dart';

void main() => runApp(const MidProjectApp());

class MidProjectApp extends StatelessWidget {
  const MidProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuBase v2', // S-1
      debugShowCheckedModeBanner: false,
      theme: buildMuleTheme(), // S-2 P04
      home: const MainShell(),
    );
  }
}
