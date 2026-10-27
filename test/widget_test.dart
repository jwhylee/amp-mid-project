// 3상태(로딩·오류·빈) + 화면 흐름(push · tab · modal) + 적응형(600 / 900dp) 위젯 테스트.
// 네트워크를 쓰지 않도록 HomeScreen에 가짜 loader를 넣는다 → json-server 없이 `flutter test`가 돈다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mid_project_template/api.dart';
import 'package:mid_project_template/models.dart';
import 'package:mid_project_template/screens/a_list_screen.dart';
import 'package:mid_project_template/screens/b_detail_screen.dart';

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
    ConditionCheckItem(no: 1, part: '바디 스크래치', level: '보통', note: '작은 스크래치'),
    ConditionCheckItem(no: 2, part: '잭 소켓', level: '확인 필요', note: '판매자에게 물어보기'),
  ],
);
Future<PriceInfo?> _loadPrice(int id) async =>
    PriceInfo(postId: id, low: 480000, avg: 560000, high: 650000);

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

const _aiEmpty = AiResponse(
  id: 2,
  query: '강남 주말 드럼 합주실 1만 원 이하',
  conditions: [AiCondition(type: 'category', label: '합주실')],
);

Future<AiResponse?> _loadAi(int id) async => id == 2 ? _aiEmpty : _aiFound;
Future<Post?> _loadPost(int id) async => _posts.firstWhere((p) => p.id == id);

Widget _app(PostsLoader load, {AiResponseLoader loadAi = _loadAi}) =>
    MaterialApp(
      home: HomeScreen(
        loadPosts: load,
        loadNotices: _loadNotices,
        loadUsageReviews: _noReviews,
        loadPriceInfo: _loadPrice,
        loadConditionCheck: _loadCheck,
        loadAiResponse: loadAi,
        loadPost: _loadPost,
      ),
    );

/// A-2에 문장을 넣고 보내기 → C 시트
Future<void> _sendQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.tap(find.byTooltip('보내기'));
  await tester.pumpAndSettle();
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('A-7 3상태: 로딩 → 오류 → 다시 시도 → 성공', (tester) async {
    _setSize(tester, const Size(400, 800));

    final first = Completer<List<Post>>();
    var calls = 0;
    await tester.pumpWidget(
      _app((_) => ++calls == 1 ? first.future : Future.value(_posts)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

  testWidgets('A-7 3상태: 빈 상태', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app((_) async => const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 글이 없습니다'), findsOneWidget);
  });

  testWidgets('A-3 예시 칩 → A-2 입력창 · A-4 탭 → board로 GET · A-5 기본 접힘', (
    tester,
  ) async {
    _setSize(tester, const Size(400, 800));
    final boards = <String>[];
    await tester.pumpWidget(
      _app((board) async {
        boards.add(board);
        return _posts;
      }),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('베이스 레슨 초보'));
    await tester.pump();
    expect(find.widgetWithText(TextField, '베이스 레슨 초보'), findsOneWidget);

    await tester.tap(find.text('합주실'));
    await tester.pumpAndSettle();
    expect(boards, ['market', 'studio']);

    expect(find.text('[공지] 첫 공지'), findsOneWidget);
    expect(find.text('[공지] 둘째 공지'), findsNothing); // 접힘
    await tester.tap(find.text('[공지] 첫 공지'));
    await tester.pumpAndSettle();
    expect(find.text('[공지] 둘째 공지'), findsOneWidget); // 펼침
  });

  testWidgets('흐름: A 통합 홈 → push B 게시글 상세', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing); // 폰: 목록

    await tester.tap(find.text('게시글 1'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // push
    expect(find.byIcon(Icons.check), findsNothing); // A에서 오면 B-3 없음
  });

  testWidgets('적응형: 600dp 이상 격자 2열 · 900dp 이상 3열', (tester) async {
    int columns() {
      final grid = tester.widget<GridView>(find.byType(GridView));
      return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount;
    }

    _setSize(tester, const Size(700, 900));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();
    expect(columns(), 2);

    _setSize(tester, const Size(1024, 900));
    await tester.pumpAndSettle();
    expect(columns(), 3);
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

  testWidgets('C-2 조건 빼기 · C-3 빼는 단어 추가 · C-4 AI 조언 · C-7 알림 SnackBar', (
    tester,
  ) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app((_) async => _posts));
    await tester.pumpAndSettle();
    await _sendQuery(tester, '아무 문장');

    await tester.tap(find.byTooltip('조건 빼기').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '일렉기타'), findsNothing);

    await tester.tap(find.text('+ 빼는 단어'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'lespaul');
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'lespaul 빼기'), findsOneWidget);

    expect(find.text('AI 조언'), findsOneWidget); // C-4
    await tester.tap(find.text('더 보기'));
    await tester.pumpAndSettle();
    expect(find.text('접기'), findsOneWidget); // S5 펼침

    await tester.tap(find.text('이 조건으로 알림'));
    await tester.pumpAndSettle();
    expect(find.textContaining('이 조건으로 새 글 알림을 받아요'), findsOneWidget); // C-7
  });

  testWidgets('C-6: 예시 칩 2번 → 빈 결과 · 오류 → 다시 찾기', (tester) async {
    _setSize(tester, const Size(400, 800));
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
    expect(find.text('장터'), findsOneWidget); // B-1 제목
    expect(find.byType(Tab), findsNWidgets(5)); // B-4

    await tester.tap(find.text('AI 상태 체크'));
    await tester.pumpAndSettle();
    expect(find.text('잭 소켓 — 확인 필요'), findsOneWidget); // B-6
    expect(find.text('2'), findsNWidgets(2)); // 사진 위 번호 + 목록 번호

    await tester.tap(find.text('시세'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsOneWidget); // B-5
    expect(find.text('480,000원'), findsOneWidget);

    await tester.tap(find.text('후기'));
    await tester.pumpAndSettle();
    expect(find.text('넥이 편해요'), findsOneWidget); // B-6
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
    expect(find.text('합주실'), findsOneWidget); // B-1 제목
    expect(find.byType(Tab), findsOneWidget);
    expect(find.text('주말 예약 가능'), findsOneWidget);
  });
}
