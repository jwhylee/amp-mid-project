// MuBase v2 — GAI3008 중간고사 (UI만 구현)
//
// ┌──────── 디자인 가이드 대응표: 앱 뼈대 ──────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명        │ 비즈니스 명칭(한글)      │ 원칙(P번호)       │
// │ S-1  │ MaterialApp           │ MuBase v2                │ —                 │
// │ S-2  │ ThemeData(seedColor)  │ TODO: 브랜드 색          │ P04 일관성 (예)   │
// └────────────────────────────────────────────────────────────────────────────┘
// 화면 흐름(docs/디자인가이드.md 1장과 같게):
//   A 통합 홈 ──덮기(BottomSheet)──▶ C AI 검색 확인 시트 ──쌓기(push)──▶ B 게시글 상세 [옆으로(tab): 글 내용 | 시세 | 사양 | 사용 후기]
//   A 통합 홈 ──쌓기(push)──────────────────────────────────────────▶ B 게시글 상세
// 기획 문서에 없는 화면은 만들지 않는다(감점). 화면을 늘리면 이 주석·가이드도 같이 고친다.
import 'package:flutter/material.dart';
import 'screens/a_list_screen.dart';

void main() => runApp(const MidProjectApp());

class MidProjectApp extends StatelessWidget {
  const MidProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuBase v2', // S-1
      debugShowCheckedModeBanner: false,
      // S-2 TODO: 현행 앱의 브랜드 색으로 바꾼다
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3F51B5)),
      home: const HomeScreen(),
    );
  }
}
