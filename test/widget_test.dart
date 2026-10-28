// 3상태(로딩·오류·빈) + 화면 흐름(push · tab · NavigationBar · modal) + 적응형(600 / 900dp) 위젯 테스트.
// 네트워크를 쓰지 않도록 MainShell에 가짜 loader 묶음을 넣는다 → json-server 없이 `flutter test`가 돈다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mid_project_template/api.dart';
import 'package:mid_project_template/models.dart';
import 'package:mid_project_template/screens/b_detail_screen.dart';
import 'package:mid_project_template/screens/c_result_sheet.dart';
import 'package:mid_project_template/screens/main_shell.dart';
import 'package:mid_project_template/theme.dart';
import 'package:mid_project_template/widgets.dart';

const _posts = [
  Post(
    id: 1,
    board: 'market',
    category: '일렉기타',
    brand: 'Fender',
    model: '',
    title: '게시글 1',
    price: 580000,
    region: '서울 마포',
    body: '본문 1',
    image: '',
    createdAt: '2026-10-22',
  ),
  Post(
    id: 2,
    board: 'market',
    category: '베이스',
    brand: 'Fender',
    model: '',
    title: '게시글 2',
    price: 690000,
    region: '인천 부평',
    body: '본문 2',
    image: '',
    createdAt: '2026-10-22',
  ),
];

const _notices = [
  Notice(id: 1, text: '[공지] 첫 공지'),
  Notice(id: 2, text: '[공지] 둘째 공지'),
];

Future<List<Notice>> _loadNotices() async => _notices;
Future<List<UsageReview>> _noReviews(int _) async => const [];
Future<ConditionCheck?> _loadCheck(int id) async => ConditionCheck(
  id: 1,
  postId: id,
  image: '',
  items: const [
    ConditionCheckItem(
      no: 1,
      part: '바디 스크래치',
      level: '보통',
      note: '작은 스크래치',
      x: 0.3,
      y: 0.6,
    ),
    ConditionCheckItem(no: 2, part: '잭 소켓', level: '확인 필요', note: '판매자에게 물어보기'),
  ],
);
Future<PriceInfo?> _loadPrice(int id) async => PriceInfo(
  postId: id,
  low: 480000,
  avg: 560000,
  high: 650000,
  label: '시세 평균보다 2만 원 싸요',
);

const _aiFound = AiResponse(
  id: 1,
  query: '60만 원 이하 펜더 일렉, 앰프 빼고',
  advice: '예산 안에서 1번 매물이 싸요. 2번은 상태가 좋아요. 앰프는 빼고 찾았어요.',
  conditions: [
    AiCondition(type: 'category', label: '일렉기타'),
    AiCondition(type: 'brand', label: '펜더'),
    AiCondition(type: 'exclude', label: '앰프'),
  ],
  results: [
    AiResult(
      postId: 1,
      board: '장터',
      title: '게시글 1',
      price: 580000,
      reasons: ['일렉기타', '펜더', '앰프 제외'],
    ),
  ],
);

const _consulting = AiConsulting(
  goal: ['예산 60만 원', '합주용 일렉기타'],
  pick: ConsultingPick(
    postId: 1,
    title: '펜더 멕시코 스트랫',
    headline: '예산 안에서 가장 균형이 좋아요',
    reasons: ['시세 평균보다 2만 원 싸요'],
  ),
  compare: [
    ConsultingRow(
      postId: 2,
      title: '재팬 텔레캐스터',
      price: 640000,
      market: '평균보다 2만 원 ↑',
      condition: '좋음 2',
      note: '예산 4만 원 초과',
    ),
  ],
  checklist: ['잭 소켓 상태 물어보기'],
  budgetTips: ['4만 원 더 쓸 수 있다면 → 텔레캐스터'],
  basis: '시세 · 후기를 바탕으로 미리 써 둔 예시 답변이에요',
);

const _aiConsult = AiResponse(
  id: 1,
  query: '60만 원 이하 펜더 일렉, 앰프 빼고',
  consulting: _consulting,
  conditions: [AiCondition(type: 'category', label: '일렉기타')],
  results: [
    AiResult(postId: 1, board: '장터', title: '게시글 1', price: 580000),
    AiResult(postId: 2, board: '장터', title: '게시글 2', price: 690000),
  ],
);

const _aiEmptyConsult = AiResponse(
  id: 2,
  query: '강남 주말 드럼 합주실 1만 원 이하',
  consulting: AiConsulting(
    goal: ['강남', '주말 드럼 합주실'],
    budgetTips: ['시간당 1.8만 원까지 올린다면 → A룸'],
    basis: '합주실 게시글을 바탕으로 미리 써 둔 예시 답변이에요',
  ),
);

const _aiEmpty = AiResponse(
  id: 2,
  query: '강남 주말 드럼 합주실 1만 원 이하',
  conditions: [AiCondition(type: 'category', label: '합주실')],
);

Future<AiResponse?> _loadAi(int id) async => id == 2 ? _aiEmpty : _aiFound;
Future<Post?> _loadPost(int id) async => _posts.firstWhere((p) => p.id == id);

const _alerts = [
  SearchAlert(
    id: 1,
    name: '펜더 일렉',
    query: '60만 원 이하 펜더 일렉, 앰프 빼고',
    labels: ['일렉기타', '펜더'],
    newCount: 2,
    matches: [
      AlertMatch(
        postId: 1,
        board: '장터',
        title: '게시글 1',
        price: 580000,
        image: '',
      ),
    ],
  ),
  SearchAlert(
    id: 2,
    name: '강남 합주실',
    query: '강남 주말 드럼 합주실 1만 원 이하',
    responseId: 2,
    labels: ['합주실'],
  ),
];

Future<List<SearchAlert>> _loadAlerts() async => _alerts;

Widget _app(
  PostsLoader load, {
  AiResponseLoader loadAi = _loadAi,
  AlertsLoader loadAlerts = _loadAlerts,
}) => MaterialApp(
  theme: buildMuleTheme(),
  home: MainShell(
    loaders: AppLoaders(
      posts: load,
      post: _loadPost,
      notices: _loadNotices,
      alerts: loadAlerts,
      aiResponse: loadAi,
      priceInfo: _loadPrice,
      conditionCheck: _loadCheck,
      usageReviews: _noReviews,
    ),
  ),
);

/// S-3 하단 메뉴 누르기 (화면 제목과 겹치지 않게 NavigationBar 안에서 찾는다)
Future<void> _goTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// A-2에 문장을 넣고 보내기 → C 시트
Future<void> _sendQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(); // 글자가 들어가야 보내기 버튼이 켜진다
  await tester.tap(find.byTooltip('보내기'));
  await tester.pumpAndSettle();
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('D-4 3상태: 로딩 → 오류 → 다시 시도 → 성공', (tester) async {
    _setSize(tester, const Size(400, 800));

    final first = Completer<List<Post>>();
    var calls = 0;
    await tester.pumpWidget(
      _app((_) => ++calls == 1 ? first.future : Future.value(_posts)),
    );
    await _goTab(tester, '게시판');
    expect(find.text('게시글을 불러오는 중…'), findsOneWidget);

    first.completeError(Exception('테스트 오류'));
    await tester.pumpAndSettle();
    expect(find.text('게시글을 불러오지 못했습니다.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('게시글 1'), findsOneWidget);
    expect(find.text('580,000원'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('D-4 3상태: 빈 상태', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app((_) async => const []));
    await _goTab(tester, '게시판');
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 글이 없습니다'), findsOneWidget);
  });

  testWidgets('A-3 예시 칩 → A-2 · A-5 기본 접힘 · A-9 바로가기 → D 게시판 · D-2 탭', (
    tester,
  ) async {
    _setSize(tester, const Size(400, 1400));
    final boards = <String>[];
    await tester.pumpWidget(
      _app((board) async {
        boards.add(board);
        return _posts;
      }),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('베이스 레슨 초보')); // 가로 한 줄 칩
    await tester.tap(find.text('베이스 레슨 초보'));
    await tester.pump();
    expect(find.widgetWithText(TextField, '베이스 레슨 초보'), findsOneWidget);

    expect(find.text('[공지] 첫 공지'), findsOneWidget);
    expect(find.text('[공지] 둘째 공지'), findsNothing); // 접힘
    await tester.tap(find.text('[공지] 첫 공지'));
    await tester.pumpAndSettle();
    expect(find.text('[공지] 둘째 공지'), findsOneWidget); // 펼침

    await tester.tap(find.text('합주실')); // A-9
    await tester.pumpAndSettle();
    expect(find.text('활동별 게시판을 골라 보세요'), findsOneWidget); // D 게시판으로
    expect(boards, ['market', 'studio']);

    await tester.tap(find.text('레슨')); // D-2
    await tester.pumpAndSettle();
    expect(boards, ['market', 'studio', 'lesson']);
  });

  testWidgets('A-8 내 알림 조건: 새 글 → B · 조건 칩 바꾸기 · AI 검색 → C', (tester) async {
    _setSize(tester, const Size(400, 1400));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();

    expect(find.text('펜더 일렉'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(NewBadge), matching: find.text('2')),
      findsOneWidget,
    ); // 숫자만
    await tester.tap(find.text('게시글 1'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // A → B push
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('강남 합주실'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 새 글이 없어요'), findsOneWidget); // S7

    await tester.tap(find.text('AI 검색으로 보기'));
    await tester.pumpAndSettle();
    expect(find.text('“강남 주말 드럼 합주실 1만 원 이하”'), findsOneWidget); // C-1
    expect(find.textContaining('조건을 하나 빼 보세요'), findsOneWidget);
  });

  testWidgets('A-8 3상태: 오류 → 다시 시도 · 빈 상태', (tester) async {
    _setSize(tester, const Size(400, 1400));
    var fail = true;
    await tester.pumpWidget(
      _app(
        (_) async => _posts,
        loadAlerts: () async {
          if (fail) throw Exception('테스트 오류');
          return const [];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('알림 조건을 불러오지 못했습니다.'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 알림을 건 조건이 없어요'), findsOneWidget);
  });

  testWidgets('흐름: D 게시판 → push B 게시글 상세', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app((_) async => _posts));
    await _goTab(tester, '게시판');
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing); // 폰: 목록

    await tester.tap(find.text('게시글 1'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // push
    expect(find.byIcon(Icons.check), findsNothing); // 게시판에서 오면 B-3 없음
  });

  testWidgets('적응형: 600dp 이상 격자 2열 · 900dp 이상 3열', (tester) async {
    int columns() {
      final grid = tester.widget<GridView>(find.byType(GridView));
      return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount;
    }

    _setSize(tester, const Size(700, 900));
    await tester.pumpWidget(_app((_) async => _posts));
    await _goTab(tester, '게시판');
    await tester.pumpAndSettle();
    expect(columns(), 2);

    _setSize(tester, const Size(1024, 900));
    await tester.pumpAndSettle();
    expect(columns(), 3);
  });

  testWidgets('A-1 알림 아이콘 → E 알림 · E-2 끄기 · 새 글 → B · AI 검색 → C', (
    tester,
  ) async {
    _setSize(tester, const Size(400, 1000));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('알림 보기')); // A-1
    await tester.pumpAndSettle();
    expect(find.text('알림을 걸어 둔 조건과 새 글'), findsOneWidget);
    expect(find.text('“60만 원 이하 펜더 일렉, 앰프 빼고”'), findsOneWidget);

    await tester.tap(find.text('게시글 1'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // E → B push
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('알림이 꺼져 있어요'), findsOneWidget); // S9
    expect(find.textContaining('알림을 껐어요'), findsOneWidget); // SnackBar

    await tester.tap(find.text('AI 검색으로 보기').first);
    await tester.pumpAndSettle();
    expect(find.text('다시 찾기'), findsOneWidget); // E → C
  });

  testWidgets('F 설정: 스위치 · 데모 안내 다이얼로그', (tester) async {
    _setSize(tester, const Size(400, 900));
    await tester.pumpWidget(_app((_) async => _posts));
    await _goTab(tester, '설정');
    await tester.pumpAndSettle();

    Switch newPosts() => tester.widget<Switch>(
      find.descendant(
        of: find.widgetWithText(SwitchListTile, '새 글 알림'),
        matching: find.byType(Switch),
      ),
    );
    expect(newPosts().value, isTrue);
    await tester.tap(find.text('새 글 알림'));
    await tester.pumpAndSettle();
    expect(newPosts().value, isFalse); // S10

    await tester.tap(find.text('데모 안내'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('C 시트: AI가 알아들은 조건 · 추천 결과 → push B → 뒤로 시트', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();

    await _sendQuery(tester, '아무 문장');
    expect(find.text('“아무 문장”'), findsOneWidget); // C-1
    expect(find.widgetWithText(InputChip, '펜더'), findsOneWidget); // C-2
    expect(find.text('일렉기타 · 펜더 · 앰프 제외'), findsOneWidget); // C-5 맞는 이유

    await tester.tap(find.text('일렉기타 · 펜더 · 앰프 제외'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // C → B push
    expect(find.widgetWithText(Chip, '앰프 제외'), findsOneWidget); // B-3
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('다시 찾기'), findsOneWidget); // 시트로 돌아옴
  });

  testWidgets(
    'C-2 조건 빼기 · C-3 제외 단어 · C-9 포함 단어 · C-4 AI 조언 · C-7 알림 SnackBar',
    (tester) async {
      _setSize(tester, const Size(400, 800));
      await tester.pumpWidget(_app((_) async => _posts));
      await tester.pumpAndSettle();
      await _sendQuery(tester, '아무 문장');

      await tester.tap(find.byTooltip('조건 빼기').first);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, '일렉기타'), findsNothing);

      await tester.tap(find.text('제외 단어'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'lespaul');
      await tester.pump(); // 글자가 들어가야 "추가"가 켜진다
      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'lespaul 제외'), findsOneWidget);

      await tester.tap(find.text('포함 단어')); // C-9
      await tester.pumpAndSettle();
      expect(find.text('포함 단어 추가'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '추가'))
            .onPressed,
        isNull,
      ); // 비어 있으면 "추가" 꺼짐
      await tester.enterText(find.byType(TextField).last, '하드케이스');
      await tester.pump();
      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, '하드케이스 포함'), findsOneWidget);

      expect(find.text('AI 조언'), findsOneWidget); // C-4
      await tester.tap(find.text('더 보기'));
      await tester.pumpAndSettle();
      expect(find.text('접기'), findsOneWidget); // S5 펼침

      await tester.tap(find.text('이 조건으로 알림'));
      await tester.pumpAndSettle();
      expect(find.textContaining('이 조건으로 새 글 알림을 받아요'), findsOneWidget); // C-7
    },
  );

  testWidgets('C-6: 예시 칩 2번 → 빈 결과 · 오류 → 다시 찾기', (tester) async {
    _setSize(tester, const Size(800, 900)); // 예시 칩 3개가 한 줄에 다 보이게
    var fail = true;
    await tester.pumpWidget(
      _app(
        (_) async => _posts,
        loadAi: (id) async {
          if (id == 1 && fail) throw Exception('테스트 오류');
          return _loadAi(id);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('강남 주말 드럼 합주실 1만 원 이하'));
    await tester.pump();
    await tester.tap(find.byTooltip('보내기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('조건을 하나 빼 보세요'), findsOneWidget);
    Navigator.of(tester.element(find.text('다시 찾기'))).pop();
    await tester.pumpAndSettle();

    await _sendQuery(tester, '아무 문장');
    expect(find.text('AI 응답을 불러오지 못했습니다.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('다시 찾기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '펜더'), findsOneWidget);
  });

  testWidgets('A-2: 비면 보내기 꺼짐 · 지우기(X) · 조건 빼기 되돌리기(C-2)', (tester) async {
    _setSize(tester, const Size(400, 1000));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();

    IconButton send() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton),
      ),
    );
    expect(send().onPressed, isNull); // P05 빈 문장은 못 보냄
    expect(find.byTooltip('지우기'), findsNothing);

    await tester.enterText(find.byType(TextField), '아무 문장');
    await tester.pump();
    expect(send().onPressed, isNotNull);
    await tester.tap(find.byTooltip('지우기')); // P03
    await tester.pump();
    expect(find.widgetWithText(TextField, '아무 문장'), findsNothing);

    await _sendQuery(tester, '아무 문장');
    await tester.tap(find.byTooltip('조건 빼기').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '일렉기타'), findsNothing);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '일렉기타'), findsOneWidget); // 같은 자리로
  });

  testWidgets('E-2 알림 끄기 → 되돌리기', (tester) async {
    _setSize(tester, const Size(400, 1000));
    await tester.pumpWidget(_app((_) async => _posts));
    await _goTab(tester, '알림');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('알림이 꺼져 있어요'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('알림이 꺼져 있어요'), findsNothing); // S9 원래대로
  });

  testWidgets('B-8: 여는 중 → 오류 → 다시 시도 → 상세 · 없는 글 안내', (tester) async {
    _setSize(tester, const Size(400, 900));
    final first = Completer<Post?>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PostLoadingScreen(
          postId: 1,
          loaders: AppLoaders(
            post: (_) =>
                ++calls == 1 ? first.future : Future.value(_posts.first),
            priceInfo: _loadPrice,
            conditionCheck: _loadCheck,
            usageReviews: _noReviews,
          ),
        ),
      ),
    );
    expect(find.text('게시글을 여는 중…'), findsOneWidget); // P01 바로 반응
    expect(find.byType(BackButton), findsOneWidget);

    first.completeError(Exception('테스트 오류'));
    await tester.pumpAndSettle();
    expect(find.text('게시글을 열지 못했습니다.'), findsOneWidget); // P09
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('판매자에게 연락하기'), findsOneWidget); // 같은 자리에 상세

    await tester.pumpWidget(
      MaterialApp(
        home: PostLoadingScreen(
          key: const ValueKey('missing'),
          postId: 99,
          loaders: AppLoaders(post: (_) async => null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('찾을 수 없는 글'), findsOneWidget);
  });

  testWidgets('F-4 데모 상태 바꾸기 · 예시 문장은 띄어쓰기만 달라도 같은 응답', (tester) async {
    addTearDown(() => demoState = '');
    _setSize(tester, const Size(400, 1000));
    final asked = <int>[];
    await tester.pumpWidget(
      _app(
        (_) async => _posts,
        loadAi: (id) async {
          asked.add(id);
          return _loadAi(id);
        },
      ),
    );
    await tester.pumpAndSettle();

    await _sendQuery(tester, '강남 주말 드럼 합주실  1만원 이하');
    expect(asked, [2]); // 빈칸 실수에도 빈 결과 응답(id=2)
    Navigator.of(tester.element(find.text('다시 찾기'))).pop();
    await tester.pumpAndSettle();

    await _goTab(tester, '설정');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('오류'));
    await tester.tap(find.text('오류'));
    await tester.pumpAndSettle();
    expect(demoState, 'error'); // S11 — 다음 GET부터 오류
    expect(find.textContaining('다음 불러오기부터 적용돼요'), findsOneWidget);
  });

  testWidgets('C-4 AI 조언 컨설팅: 접힘 → 자세히 보기 → 비교표 → B · 1순위 없는 응답', (
    tester,
  ) async {
    _setSize(tester, const Size(400, 1400));
    await tester.pumpWidget(
      _app(
        (_) async => _posts,
        loadAi: (id) async => id == 2 ? _aiEmptyConsult : _aiConsult,
      ),
    );
    await tester.pumpAndSettle();
    await _sendQuery(tester, '아무 문장');

    expect(find.text('추천 결과 2개 · 장터'), findsOneWidget); // C-2 결과 수 · 게시판
    expect(find.text('예산 60만 원'), findsOneWidget); // ① 목적 요약
    expect(find.textContaining('1순위 · '), findsOneWidget); // ② 1순위 한 줄
    expect(find.text('사기 전 확인할 것'), findsNothing); // 접힘
    expect(find.text('미리 써 둔 예시 답변이에요 · 참고용'), findsOneWidget); // 접힘 한 줄

    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();
    expect(find.text('시세 평균보다 2만 원 싸요'), findsOneWidget); // ② 이유
    expect(find.text('잭 소켓 상태 물어보기'), findsOneWidget); // ④
    expect(find.text('4만 원 더 쓸 수 있다면 → 텔레캐스터'), findsOneWidget); // ⑤
    expect(find.textContaining('시세 · 후기를 바탕으로'), findsOneWidget); // ⑥
    // 펼치면 근거 줄 하나만 — "예시 답변이에요"가 두 번 나오지 않음
    expect(find.textContaining('예시 답변이에요'), findsOneWidget);
    expect(find.textContaining('예시 답변이에요 · 참고용'), findsOneWidget);

    await tester.tap(find.text('재팬 텔레캐스터')); // ③ 비교표 → B
    await tester.pumpAndSettle();
    expect(find.text('판매자에게 연락하기'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('AI가 이렇게 알아들었어요'))).pop();
    await tester.pumpAndSettle();

    await _sendQuery(tester, '강남 주말 드럼 합주실 1만 원 이하');
    expect(find.text('추천 결과 없음'), findsOneWidget);
    expect(find.textContaining('1순위 · '), findsNothing); // ②③④ 숨김
    await tester.tap(find.text('자세히 보기'));
    await tester.pumpAndSettle();
    expect(find.text('시간당 1.8만 원까지 올린다면 → A룸'), findsOneWidget); // ⑤
    expect(find.text('비교'), findsNothing);
  });

  testWidgets('C-8 닫기 확인 · C-5 조건 변경 배너', (tester) async {
    _setSize(tester, const Size(400, 1000));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();

    // 고친 적이 없으면 바로 닫힌다
    await _sendQuery(tester, '아무 문장');
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('AI가 이렇게 알아들었어요'), findsNothing);

    await _sendQuery(tester, '아무 문장');
    await tester.tap(find.byTooltip('조건 빼기').first);
    await tester.pumpAndSettle();
    expect(find.text('조건이 바뀌었어요 — 다시 찾기'), findsOneWidget); // C-5 배너
    expect(find.textContaining('조건을 뺐어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // 되돌리기 알림은 4초 뒤 닫힘
    await tester.pumpAndSettle();
    expect(find.textContaining('조건을 뺐어요'), findsNothing);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('고친 조건을 버릴까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('AI가 이렇게 알아들었어요'), findsOneWidget); // 남아 있음

    // 끌어 내리기도 확인을 거친다
    // 시트 맨 위 끌기 손잡이(drag handle)를 잡고 아래로
    final sheetTop = tester.getTopLeft(find.byType(AiSearchConfirmSheet)).dy;
    await tester.dragFrom(Offset(200, sheetTop + 12), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(
      find.text('AI가 이렇게 알아들었어요'),
      findsOneWidget,
      reason: '끌어도 바로 닫히면 안 됨',
    );
    expect(find.text('고친 조건을 버릴까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    // 바깥(어두운 배경) 누르기도 확인을 거친다
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.text('고친 조건을 버릴까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('다시 찾기').first); // 배너 사라짐
    await tester.pumpAndSettle();
    expect(find.text('조건이 바뀌었어요 — 다시 찾기'), findsNothing);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('버리기'));
    await tester.pumpAndSettle();
    expect(find.text('AI가 이렇게 알아들었어요'), findsNothing); // 닫힘
  });

  testWidgets('PostImage: 사진 주소가 없거나 못 불러오면 카테고리 그림', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            PostImage('', category: '베이스', width: 100, height: 100),
            // 테스트 환경의 네트워크 요청은 실패(400) → errorBuilder
            PostImage(
              'https://example.com/none.jpg',
              category: '앰프',
              width: 100,
              height: 100,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CategoryArt), findsNWidgets(2));
    expect(find.text('베이스'), findsOneWidget);
    expect(find.text('앰프'), findsOneWidget);
  });

  testWidgets('B: 장터 글 5탭 · B-6 AI 상태 체크 · B-5 시세 · 후기 · B-7 취소/확인', (
    tester,
  ) async {
    _setSize(tester, const Size(400, 1600)); // 탭 안 목록까지 한 화면에 그려지게
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          post: _posts.first,
          loadPriceInfo: _loadPrice,
          loadConditionCheck: _loadCheck,
          loadUsageReviews: (_) async => const [
            UsageReview(id: 1, postId: 1, rating: 4, text: '넥이 편해요'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '장터'), findsOneWidget); // B-1 제목
    expect(find.byType(Tab), findsNWidgets(5)); // B-4
    // B-2 제목 · 가격 카드가 사진과 같은 폭
    final photoWidth = tester.getSize(find.byType(PostImage).first).width;
    final cardWidth = tester
        .getSize(
          find.ancestor(
            of: find.text(_posts.first.title),
            matching: find.byType(Card),
          ),
        )
        .width;
    expect(cardWidth, photoWidth);

    await tester.tap(find.text('AI 상태 체크'));
    await tester.pumpAndSettle();
    expect(find.text('잭 소켓 — 확인 필요'), findsOneWidget); // B-6
    expect(find.text('2'), findsNWidgets(2)); // 사진 위 번호 + 목록 번호

    await tester.tap(find.text('시세'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsOneWidget); // B-5
    expect(find.text('480,000원'), findsOneWidget);
    expect(find.text('시세 평균보다 2만 원 싸요'), findsOneWidget); // label 그대로

    await tester.tap(find.text('후기'));
    await tester.pumpAndSettle();
    expect(find.text('넥이 편해요'), findsOneWidget); // B-4 후기
    expect(find.text('★★★★☆'), findsOneWidget);

    await tester.tap(find.text('판매자에게 연락하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing); // 취소하면 아무 일 없음

    await tester.tap(find.text('판매자에게 연락하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('B: 장터 밖 게시판은 글 내용 한 탭', (tester) async {
    _setSize(tester, const Size(400, 800));
    const studio = Post(
      id: 8,
      board: 'studio',
      category: '합주실',
      brand: '',
      model: '',
      title: '합주실 B룸',
      price: 15000,
      region: '서울 마포',
      body: '주말 예약 가능',
      image: '',
      createdAt: '2026-10-22',
    );
    await tester.pumpWidget(
      const MaterialApp(home: PostDetailScreen(post: studio)),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '합주실'), findsOneWidget); // B-1 제목
    expect(find.byType(Tab), findsOneWidget);
    expect(find.text('주말 예약 가능'), findsOneWidget);
  });
}
