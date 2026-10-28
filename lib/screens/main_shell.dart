// S-3 하단 메뉴 — 홈 · 게시판 · 알림 · 설정 (옆으로: NavigationBar)
//
// 네 화면은 IndexedStack으로 겹쳐 두어, 메뉴를 오가도 스크롤 위치 · 고른 탭이 그대로 남는다.
// 홈의 "게시판 바로가기"(A-9) · 알림 아이콘(A-1)은 이 화면의 메뉴 번호만 바꾼다 (화면 안 표시 변화 — setState).
// 상태관리 포인트: S8 선택된 하단 메뉴 · S2 선택된 게시판 → `grep -rn "STATE:" lib`
import 'package:flutter/material.dart';

import '../api.dart';
import 'a_list_screen.dart';
import 'd_board_screen.dart';
import 'e_alerts_screen.dart';
import 'f_settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.loaders = const AppLoaders()});

  /// 데이터를 가져오는 함수 묶음 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final AppLoaders loaders;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _tab = 0;
  var _boardIndex = 0;

  void _selectTab(int index) {
    // STATE: S8 선택된 하단 메뉴 → S-3 · 보이는 화면
    setState(() {
      _tab = index;
    });
  }

  /// A-9 게시판 바로가기 → D 게시판 탭으로 옮기고 그 게시판을 고른다
  void _openBoard(int boardIndex) {
    // STATE: S2 선택된 게시판 → D-2 · D-3
    setState(() {
      _boardIndex = boardIndex;
      _tab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loaders = widget.loaders;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            loaders: loaders,
            onOpenBoard: _openBoard,
            onOpenAlerts: () => _selectTab(2),
          ),
          BoardScreen(
            loaders: loaders,
            boardIndex: _boardIndex,
            onBoardChanged: (i) {
              // STATE: S2 선택된 게시판 → D-2 · D-3
              setState(() {
                _boardIndex = i;
              });
            },
          ),
          AlertsScreen(loaders: loaders),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '게시판',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: '알림',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ), // S-3 P04 · P06
    );
  }
}
