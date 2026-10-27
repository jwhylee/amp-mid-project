// 화면 A: 통합 홈 (GET /posts?board= · /notices)
//
// ── 디자인 가이드 대응표: 화면 A — 통합 홈 (docs/디자인가이드.md 3장과 같게) ──────────────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준(무엇을 · 순서 · 강조) | 원칙(P번호 · 이유) | 편의성 포인트 |
// |---|---|---|---|---|---|
// | A-1 | AppBar | 상단 제목 바 | 앱 이름만, 왼쪽 정렬 | P04 · 모든 화면 같은 자리 | 어느 화면이든 같은 자리에서 위치 확인 |
// | A-2 | TextField + IconButton | AI 조건 입력창 | 첫 줄 · 가장 크게 · 예시 문장 힌트 | P06 · 키워드 대신 문장 | 키워드를 정확히 기억 안 해도 됨 |
// | A-3 | Wrap · ActionChip | 예시 조건 칩 | 입력창 바로 아래 · 3개 | P06 · 보고 고르기 | 첫 문장을 직접 안 써도 됨 |
// | A-4 | TabBar | 게시판 탭 | 장터 · 합주실 · 레슨 · 구인 · 공연 순 | P02 · 현행 잘된 점 유지 | 활동별 게시판을 탭 한 번에 이동 |
// | A-5 | ExpansionTile | 공지 접기 줄 | 기본 1줄로 접힘 · 누르면 펼침 | P08 · 공지 7줄 제거 | 매물까지 스크롤 안 해도 됨 |
// | A-6 | ListView / GridView · Card | 게시글 카드 목록 | 제목 → 가격(굵게) → 카테고리 · 지역 칩 | P08 · 판단 정보만 | 목록에서 바로 가격 · 지역 비교 |
// | A-7 | FutureBuilder · LoadingView · ErrorView · EmptyView | 목록 상태 안내 | 로딩 → 오류 + 다시 시도 → 빈 목록 안내 | P09 · 복구 방법 제시 | 오류 때 앱을 껐다 켜지 않아도 됨 |
// ────────────────────────────────────────────────────────────────────────────────────────
// 전환: A → B 쌓기(Navigator.push, 게시글 카드) · A → C 덮기(showModalBottomSheet, AI 조건 입력창 보내기)
// 적응형: LayoutBuilder 1곳 — 창 너비 600dp 미만 ListView, 600dp 이상 GridView 2열, 900dp 이상 3열 (A-6).
// 상태관리 포인트(가이드 5장): S1 입력 문장 · S2 선택된 게시판 · S3 서버 응답 상태 → `grep -rn "STATE:" lib`
// P번호 = 닐슨 원칙 번호 (docs/디자인가이드.md 2장). 그 원칙을 보여 주는 위젯 줄 끝에 `// A-5 P08` 처럼 단다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';
import 'c_result_sheet.dart';

/// 이 너비 이상이면 격자 2열 (Material 3 window size class: medium ≥ 600dp)
const wideBreakpoint = 600.0;

/// 이 너비 이상이면 격자 3열 (expanded에 가까운 넓은 창)
const extraWideBreakpoint = 900.0;

/// A-3 예시 조건 칩 — 누르면 입력창이 채워진다. responseId = C에서 보여 줄 미리 쓴 응답 (2번 칩만 빈 결과 id=2)
const exampleConditions = [
  (text: '60만 원 이하 펜더 일렉, 앰프 빼고', responseId: 1),
  (text: '강남 주말 드럼 합주실 1만 원 이하', responseId: 2),
  (text: '베이스 레슨 초보', responseId: 1),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.loadPosts = fetchPosts,
    this.loadNotices = fetchNotices,
    this.loadUsageReviews = fetchUsageReviews,
    this.loadPriceInfo = fetchPriceInfo,
    this.loadConditionCheck = fetchConditionCheck,
    this.loadAiResponse = fetchAiResponse,
    this.loadPost = fetchPost,
  });

  /// 데이터를 가져오는 함수 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final PostsLoader loadPosts;
  final NoticesLoader loadNotices;
  final UsageReviewsLoader loadUsageReviews;
  final PriceInfoLoader loadPriceInfo;
  final ConditionCheckLoader loadConditionCheck;
  final AiResponseLoader loadAiResponse;
  final PostLoader loadPost;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _query = TextEditingController();
  var _boardIndex = 0;
  late Future<List<Post>> _posts = widget.loadPosts(boardTabs.first.board);
  late Future<List<Notice>> _notices = widget.loadNotices();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// A-3 예시 조건 칩 → A-2 입력창 채우기 (컨트롤러가 다시 그리므로 setState 불필요)
  void _fillExample(String text) {
    // STATE: S1 입력 문장 → A-2 · C-1
    _query.text = text;
  }

  /// A-2 보내기 → C AI 검색 확인 시트 (덮기)
  /// 어떤 문장이든 id=1, 예시 조건 칩 2번 문장 그대로면 id=2 — 문장 해석·추천 계산은 하지 않는다.
  void _send() {
    final query = _query.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    final example = exampleConditions.where((e) => e.text == query).firstOrNull;
    AiSearchConfirmSheet.show(
      context,
      query: query,
      responseId: example?.responseId ?? 1,
      loadAiResponse: widget.loadAiResponse,
      loadPost: widget.loadPost,
      loadPriceInfo: widget.loadPriceInfo,
      loadConditionCheck: widget.loadConditionCheck,
      loadUsageReviews: widget.loadUsageReviews,
    );
  }

  /// A-4 게시판 탭 누름 → 그 게시판 글을 다시 GET
  void _selectBoard(int index) {
    if (index == _boardIndex) return;
    // STATE: S2 선택된 게시판 → A-4 · A-6
    setState(() {
      _boardIndex = index;
      _posts = widget.loadPosts(boardTabs[index].board);
    });
  }

  /// A-7 다시 시도 = Future만 새로 만드는 setState (화면 안 표시 변화 — 허용)
  // (주의) `setState(() => _posts = …)`처럼 화살표로 쓰면 Future를 돌려줘 디버그 오류가 난다 → 중괄호로 쓴다.
  void _retry() {
    // STATE: S3 서버 응답 상태 → A-7
    setState(() {
      _posts = widget.loadPosts(boardTabs[_boardIndex].board);
      _notices = widget.loadNotices();
    });
  }

  void _open(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(
          post: post,
          loadConditionCheck: widget.loadConditionCheck,
          loadPriceInfo: widget.loadPriceInfo,
          loadUsageReviews: widget.loadUsageReviews,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DefaultTabController(
      length: boardTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MuBase'),
          centerTitle: false,
        ), // A-1 P04
        body: LayoutBuilder(
          // 적응형: 기기 종류가 아니라 "이 영역의 너비"로 나눈다
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= extraWideBreakpoint
                ? 3
                : width >= wideBreakpoint
                ? 2
                : 1;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    // STATE: S1 입력 문장 → A-2 · C-1
                    child: TextField(
                      controller: _query,
                      style: text.titleMedium,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: '예: 60만 원 이하 펜더 일렉, 앰프는 빼고',
                        prefixIcon: const Icon(Icons.auto_awesome),
                        suffixIcon: IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                          tooltip: '보내기',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ), // A-2 P06
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final example in exampleConditions)
                          ActionChip(
                            label: Text(example.text),
                            onPressed: () => _fillExample(example.text),
                          ),
                      ],
                    ), // A-3 P06
                  ),
                ),
                SliverToBoxAdapter(
                  child: TabBar(
                    onTap: _selectBoard,
                    tabs: [for (final b in boardTabs) Tab(text: b.label)],
                  ), // A-4 P02
                ),
                SliverToBoxAdapter(child: _NoticeFold(future: _notices)),
                FutureBuilder<List<Post>>(
                  future: _posts,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: LoadingView(label: '게시글을 불러오는 중…'), // A-7 P09
                      );
                    }
                    if (snap.hasError) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: ErrorView(
                          title: '게시글을 불러오지 못했습니다.',
                          message: '${snap.error}',
                          onRetry: _retry,
                        ), // A-7 P09
                      );
                    }
                    final posts = snap.data ?? const <Post>[];
                    if (posts.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyView(
                          message: '이 게시판에는 아직 글이 없습니다.\n다른 게시판 탭을 눌러 보세요.',
                        ), // A-7 P09
                      );
                    }
                    return SliverToBoxAdapter(
                      child: _PostCardList(
                        posts: posts,
                        columns: columns,
                        onOpen: _open,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A-5 공지 접기 줄 — 기본 1줄로 접혀 있고 누르면 펼친다.
class _NoticeFold extends StatelessWidget {
  const _NoticeFold({required this.future});

  final Future<List<Notice>> future;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.campaign_outlined);
    return FutureBuilder<List<Notice>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const ListTile(leading: icon, title: Text('공지를 불러오는 중…'));
        }
        if (snap.hasError) {
          // 공지는 보조 정보 — 다시 시도는 A-7 버튼이 공지까지 함께 다시 가져온다
          return const ListTile(leading: icon, title: Text('공지를 불러오지 못했습니다.'));
        }
        final notices = snap.data ?? const <Notice>[];
        if (notices.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          leading: icon,
          title: Text(
            notices.first.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('공지 ${notices.length}건 · 눌러서 펼치기'),
          children: [
            for (final n in notices) ListTile(dense: true, title: Text(n.text)),
          ],
        ); // A-5 P08
      },
    );
  }
}

/// A-6 게시글 카드 목록 — 바깥 CustomScrollView가 스크롤하므로 안쪽은 shrinkWrap
class _PostCardList extends StatelessWidget {
  const _PostCardList({
    required this.posts,
    required this.columns,
    required this.onOpen,
  });

  final List<Post> posts;
  final int columns;
  final ValueChanged<Post> onOpen;

  @override
  Widget build(BuildContext context) {
    if (columns > 1) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 156,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: posts.length,
        itemBuilder: (context, i) =>
            PostCard(posts[i], grid: true, onTap: () => onOpen(posts[i])),
      ); // A-6 P08 넓은 화면: 격자 2열(≥600dp) · 3열(≥900dp)
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: posts.length,
      itemBuilder: (context, i) =>
          PostCard(posts[i], onTap: () => onOpen(posts[i])),
    ); // A-6 P08 좁은 화면: 목록
  }
}

/// 게시글 카드 한 장 — 제목 → 가격(굵게) → 카테고리 · 지역 칩 (판단 정보만)
class PostCard extends StatelessWidget {
  const PostCard(this.post, {super.key, this.onTap, this.grid = false});

  final Post post;
  final VoidCallback? onTap;

  /// true: 넓은 화면 격자용(여백 없음) · false: 폰 목록용(좌우 여백)
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: grid
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                post.title,
                style: text.titleMedium,
                maxLines: grid ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                formatWon(post.price),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ), // A-6 P08 가격 굵게
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final label in [post.category, post.region])
                    Chip(
                      label: Text(label),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
