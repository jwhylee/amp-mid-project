// 화면 D: 게시판 (GET /posts?board=) — 하단 메뉴 '게시판'
//
// ── 디자인 가이드 대응표: 화면 D — 게시판 (docs/디자인가이드.md 3장과 같게) ────────────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준 | 원칙 | 편의성 포인트 |
// |---|---|---|---|---|---|
// | D-1 | GradientHeader | 게시판 머리 | 화면 이름 + 한 줄 설명 | P04 · 모든 메뉴 같은 자리 | 지금 어느 메뉴인지 바로 앎 |
// | D-2 | TabBar(알약) | 게시판 탭 | 장터 · 합주실 · 레슨 · 구인 · 공연 순 | P02 · 현행 잘된 점 유지 | 활동별 게시판을 탭 한 번에 이동 |
// | D-3 | ListView / GridView · Card | 게시글 카드 목록 | 사진 → 카테고리 · 지역 · 날짜 → 제목 → 가격(굵게) | P08 · 판단 정보만 | 목록에서 바로 가격 · 지역 비교 |
// | D-4 | FutureBuilder · LoadingView · ErrorView · EmptyView · RefreshIndicator | 목록 상태 안내 | 로딩 → 오류 + 다시 시도 → 빈 목록 안내 · 아래로 당겨 새로고침 | P09 · 복구 방법 제시 | 오류 때 앱을 껐다 켜지 않아도 됨 |
// ────────────────────────────────────────────────────────────────────────────────────────
// 전환: D → B 쌓기(Navigator.push, 게시글 카드) · 게시판 탭은 화면 안 표시 변화(옆으로 TabBar).
// 적응형: LayoutBuilder — 창 너비 600dp 미만 ListView, 600dp 이상 GridView 2열, 900dp 이상 3열 (D-3).
// 상태관리 포인트: S2 선택된 게시판 (MainShell이 들고 있다 — A-9 바로가기와 함께 쓰려고) · S3 서버 응답 상태
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';

/// 이 너비 이상이면 격자 2열 (Material 3 window size class: medium ≥ 600dp)
const wideBreakpoint = 600.0;

/// 이 너비 이상이면 격자 3열 (expanded에 가까운 넓은 창)
const extraWideBreakpoint = 900.0;

class BoardScreen extends StatefulWidget {
  const BoardScreen({
    super.key,
    this.loaders = const AppLoaders(),
    this.boardIndex = 0,
    this.onBoardChanged,
  });

  final AppLoaders loaders;

  /// 지금 고른 게시판 (boardTabs 순서)
  final int boardIndex;
  final ValueChanged<int>? onBoardChanged;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: boardTabs.length,
    initialIndex: widget.boardIndex,
    vsync: this,
  );
  late Future<List<Post>> _posts = _load();

  Future<List<Post>> _load() =>
      widget.loaders.posts(boardTabs[widget.boardIndex].board);

  @override
  void didUpdateWidget(BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boardIndex != widget.boardIndex) {
      // A-9 바로가기 또는 D-2 탭으로 게시판이 바뀜 → 그 게시판 글을 다시 GET
      _tabs.index = widget.boardIndex;
      _posts = _load();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// D-4 다시 시도 · 당겨서 새로고침
  Future<void> _retry() {
    // STATE: S3 서버 응답 상태 → D-4
    setState(() {
      _posts = _load();
    });
    return settle(_posts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GradientHeader(
          title: '게시판',
          subtitle: '활동별 게시판을 골라 보세요',
        ), // D-1 P04
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          // STATE: S2 선택된 게시판 → D-2 · D-3
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (i) {
              if (i != widget.boardIndex) widget.onBoardChanged?.call(i);
            },
            tabs: [for (final b in boardTabs) Tab(text: b.label)],
          ), // D-2 P02
        ),
        Expanded(
          child: LayoutBuilder(
            // 적응형: 기기 종류가 아니라 "이 영역의 너비"로 나눈다
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= extraWideBreakpoint
                  ? 3
                  : width >= wideBreakpoint
                  ? 2
                  : 1;
              return FutureBuilder<List<Post>>(
                // 게시판이 바뀌면 새 FutureBuilder — 다른 게시판 글이 잠깐 보이지 않게
                key: ValueKey(widget.boardIndex),
                future: _posts,
                builder: (context, snap) {
                  // 당겨서 새로고침 중에는 이전 목록을 그대로 둔다
                  if (snap.connectionState != ConnectionState.done &&
                      !snap.hasData) {
                    return const LoadingView(label: '게시글을 불러오는 중…'); // D-4 P09
                  }
                  if (snap.hasError) {
                    return ErrorView(
                      title: '게시글을 불러오지 못했습니다.',
                      message: '${snap.error}',
                      onRetry: _retry,
                    ); // D-4 P09
                  }
                  final posts = snap.data ?? const <Post>[];
                  if (posts.isEmpty) {
                    return const EmptyView(
                      message: '이 게시판에는 아직 글이 없습니다.\n다른 게시판 탭을 눌러 보세요.',
                    ); // D-4 P09
                  }
                  return RefreshIndicator(
                    onRefresh: _retry,
                    child: _PostCardList(
                      posts: posts,
                      columns: columns,
                      onOpen: (post) =>
                          openPostDetail(context, post, widget.loaders),
                    ),
                  ); // D-4 P09 당겨서 다시 불러오기
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// D-3 게시글 카드 목록
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
        physics: const AlwaysScrollableScrollPhysics(), // 글이 적어도 당겨서 새로고침
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          // 사진 + 글자 줄 — 글자 크기 설정이 커져도 넘치지 않게
          mainAxisExtent: scaledHeight(context, 170, 90),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: posts.length,
        itemBuilder: (context, i) =>
            PostCard(posts[i], grid: true, onTap: () => onOpen(posts[i])),
      ); // D-3 P08 넓은 화면: 격자 2열(≥600dp) · 3열(≥900dp)
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(), // 글이 적어도 당겨서 새로고침
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          PostCard(posts[i], onTap: () => onOpen(posts[i])),
    ); // D-3 P08 좁은 화면: 목록
  }
}

/// 게시글 카드 한 장 — 사진 → 제목 → 가격(굵게) → 카테고리 · 지역 (판단 정보만)
class PostCard extends StatelessWidget {
  const PostCard(this.post, {super.key, this.onTap, this.grid = false});

  final Post post;
  final VoidCallback? onTap;

  /// true: 넓은 화면 격자용(사진 위) · false: 폰 목록용(사진 왼쪽)
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${post.category} · ${post.region} · ${formatDate(post.createdAt)}',
          style: text.labelMedium?.copyWith(color: mulePurple),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          post.title,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          formatWon(post.price),
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ), // D-3 P08 가격 굵게
      ],
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: grid
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: RoundedImage(post.image),
                      ),
                    ),
                    const SizedBox(height: 10),
                    info,
                  ],
                )
              : Row(
                  children: [
                    RoundedImage(post.image, width: 88, height: 88),
                    const SizedBox(width: 12),
                    Expanded(child: info),
                  ],
                ),
        ),
      ),
    );
  }
}
