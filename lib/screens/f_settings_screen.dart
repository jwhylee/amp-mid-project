// 화면 F: 설정 — 하단 메뉴 '설정' (데이터 GET 없음 · 하드코딩 상수)
//
// ── 디자인 가이드 대응표: 화면 F — 설정 (docs/디자인가이드.md 3장과 같게) ────────────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준 | 원칙 | 편의성 포인트 |
// |---|---|---|---|---|---|
// | F-1 | GradientHeader | 설정 머리 | 화면 이름 + 한 줄 설명 | P04 · 모든 메뉴 같은 자리 | 지금 어느 메뉴인지 바로 앎 |
// | F-2 | Card · SwitchListTile | 알림 설정 | 새 글 알림 · 가격 내림 알림 · 방해 금지 시간 | P03 · P07 | 알림이 너무 많을 때 한 곳에서 줄임 |
// | F-3 | Card · ListTile → showDialog | 앱 정보 · 데모 안내 | 관심 지역 · 버전 · 데모 안내 | P10 | 무엇이 실제로 동작하지 않는지 미리 앎 |
// | F-4 | SegmentedButton | 데모 상태 | 평소 · 느리게 · 오류 · 빈 결과 — 발표 · 영상용 | P09 · 3상태 시연 | 앱을 다시 켜지 않고 로딩 · 오류 · 빈 상태를 보여 줌 |
// ────────────────────────────────────────────────────────────────────────────────────────
// 전환: F-3 데모 안내 덮기(showDialog).
// 상태관리 포인트: S10 설정 스위치 · S11 데모 상태 → `grep -rn "STATE:" lib`
//
// ⚠ 스위치는 화면 표시만 바꾼다. 저장하지 않으므로 앱을 다시 켜면 처음대로 돌아간다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

/// 설정 본문 최대 너비
const settingsMaxWidth = 720.0;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _newPosts = true;
  var _priceDrop = true;
  var _quietHours = false;

  /// F-4 데모 상태 — '' 평소 · loading 느리게 · error 오류 · empty 빈 결과
  var _demo = demoState;

  void _setDemo(String value) {
    // STATE: S11 데모 상태 → 다음 GET부터 모든 화면의 3상태 (저장하지 않는다)
    setState(() {
      _demo = value;
      demoState = value;
    });
    _snack('다음 불러오기부터 적용돼요 — 당겨서 새로고침하거나 탭을 바꿔 보세요.');
  }

  void _set(void Function() change) {
    // STATE: S10 설정 스위치 → F-2 (저장하지 않는다)
    setState(change);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDemoNotice() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데모 안내'),
        content: const Text(
          'MuBase v2는 화면만 보여 주는 프로토타입입니다.\n'
          '알림 등록 · 판매자 연락 · 설정 저장은 실제로 일어나지 않고, '
          'AI 결과는 미리 써 둔 예시입니다.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    ); // F-3 P10
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget group(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            title,
            style: text.labelLarge?.copyWith(color: muleSubtle),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
    return Column(
      children: [
        const GradientHeader(title: '설정', subtitle: '알림과 앱 정보'), // F-1 P04
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: settingsMaxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  group('알림', [
                    SwitchListTile(
                      secondary: const Icon(Icons.fiber_new_outlined),
                      title: const Text('새 글 알림'),
                      subtitle: const Text('알림 조건에 맞는 새 글이 올라오면'),
                      value: _newPosts,
                      onChanged: (v) => _set(() => _newPosts = v),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.trending_down),
                      title: const Text('가격 내림 알림'),
                      subtitle: const Text('본 글의 가격이 내려가면'),
                      value: _priceDrop,
                      onChanged: (v) => _set(() => _priceDrop = v),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.bedtime_outlined),
                      title: const Text('방해 금지 시간'),
                      subtitle: const Text('밤 10시 – 아침 8시에는 알림을 쉬어요'),
                      value: _quietHours,
                      onChanged: (v) => _set(() => _quietHours = v),
                    ),
                  ]), // F-2 P03 · P07
                  group('앱 정보', [
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: const Text('관심 지역'),
                      trailing: const Text('서울 마포'),
                      onTap: () => _snack('관심 지역 바꾸기는 데모에서 지원하지 않습니다.'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('버전'),
                      trailing: Text('v2 프로토타입'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('데모 안내'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showDemoNotice,
                    ),
                  ]), // F-3 P10
                  group('발표 · 영상용', [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: '', label: Text('평소')),
                            ButtonSegment(value: 'loading', label: Text('느리게')),
                            ButtonSegment(value: 'error', label: Text('오류')),
                            ButtonSegment(value: 'empty', label: Text('빈 결과')),
                          ],
                          selected: {_demo},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => _setDemo(s.first),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text(
                        '로딩 · 오류 · 빈 상태를 앱을 다시 켜지 않고 보여 줍니다. 느리게는 3초 늦게 응답해요.',
                        style: text.bodySmall?.copyWith(color: muleSubtle),
                      ),
                    ),
                  ]), // F-4 P09 3상태 시연
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
