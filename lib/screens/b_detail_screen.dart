// 화면 B: 게시글 상세 (GET /conditionChecks?postId= · /priceInfo?postId= · /usageReviews?postId=)
//
// ── 디자인 가이드 대응표: 화면 B — 게시글 상세 (docs/디자인가이드.md 3장과 같게) ─────────────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준 | 원칙 | 편의성 포인트 |
// |---|---|---|---|---|---|
// | B-1 | AppBar · BackButton | 뒤로가기 바 | 왼쪽 위에 항상 · 밝은 바탕에 진한 화살표 · 제목 | P03 · #8 #9 | 처음부터 다시 들어오지 않아도 됨 |
// | B-2 | CategoryArt · Text | 게시글 머리 | 카테고리 그림 → 제목 → 가격(가장 크게) → 지역 | P08 · P02 | 스크롤 없이 핵심 확인 |
// | B-3 | Chip | 내 조건과 맞는 이유 | 머리 바로 아래 · C에서 왔을 때만 | P01 | 왜 추천됐는지 다시 확인 |
// | B-4 | TabBar · TabBarView | 판단 정보 탭 | 글 내용 · AI 상태 체크 · 시세 · 사양 · 후기 (장터 글만 5탭, 다른 게시판은 글 내용 한 탭) | P07 | 시세 · 상태 · 후기를 앱 밖에서 안 찾음 |
// | B-5 | Row · LinearProgressIndicator | 시세 범위 막대 | 최저 · 평균 · 최고 + 이 매물 위치 + 평균 세로 눈금 → 막대 아래 한 줄 판단(priceInfo.label, 굵게) | P07 | 비싼지 싼지 바로 판단 |
// | B-6 | Stack · CategoryArt · ListTile | AI 상태 체크 | 사진 위 해당 위치(미리 쓴 x · y)에 번호 → 항목별 상태(좋음 · 보통 · 확인 필요) | P01 · #7 | 사진만 보고 혼자 상태를 짐작하지 않음 |
// | B-7 | FilledButton → showDialog | 판매자 연락 버튼 | 화면 아래 고정 | P03 · 취소 가능 | 잘못 눌러도 취소 가능 |
// | B-8 | FutureBuilder · LoadingView · ErrorView · EmptyView | 게시글 불러오기 상태 안내 | 누르자마자 상세로 넘어감 → 여는 중 → 오류 + 다시 시도 → 없는 글 안내 | P01 · P09 | 눌렀는데 반응 없는 순간이 없음 · 실패해도 그 자리에서 다시 시도 |
// ────────────────────────────────────────────────────────────────────────────────────────
// 전환: A(알림 새 글) · C · D · E → B 쌓기(Navigator.push) · B 안에서 옆으로(TabBar) · B-7 덮기(showDialog). 뒤로 가면 온 곳(홈 · 게시판 · 알림 또는 시트)으로.
// postId만 아는 곳(A-8 · C-5 · E-2)은 B-8이 먼저 열려 글을 받은 뒤 같은 자리에 상세를 그린다.
// 적응형: 넓은 화면에서 본문 최대 너비 720dp로 가운데 정렬.
// 상태관리 포인트(가이드 5장): S3 서버 응답 상태(B-8) · S6 선택된 판단 정보 탭 (AI 상태 체크 포함) → `grep -rn "STATE:" lib`
//
// ⚠ AI 상태 체크 · 시세 · 사양 · 후기는 미리 정한 데이터를 그대로 보여 준다.
//   이미지를 분석하거나 시세를 계산하거나 판매자에게 실제로 연락하지 않는다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// 넓은 화면에서 본문 최대 너비 (가이드 1장 적응형)
const detailMaxWidth = 720.0;

/// B 게시글 상세 열기 (쌓기) — 게시판 카드처럼 글을 이미 가진 곳에서
void openPostDetail(
  BuildContext context,
  Post post,
  AppLoaders loaders, {
  List<String> reasons = const [],
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PostDetailScreen(
        post: post,
        reasons: reasons,
        loadConditionCheck: loaders.conditionCheck,
        loadPriceInfo: loaders.priceInfo,
        loadUsageReviews: loaders.usageReviews,
      ),
    ),
  );
}

/// postId만 아는 곳(C-5 추천 결과 · 알림 새 글)에서 — 화면을 먼저 열고(쌓기) 그 안에서 GET /posts?id=
void openPostById(
  BuildContext context,
  AppLoaders loaders,
  int postId, {
  List<String> reasons = const [],
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PostLoadingScreen(postId: postId, reasons: reasons, loaders: loaders),
    ),
  );
}

/// B-8 게시글 불러오기 상태 안내 — 누르자마자 상세 화면으로 넘어가고, 글을 받는 동안 · 실패 · 없음을 여기서 보여 준다.
/// 받으면 같은 자리에 게시글 상세를 그린다 (뒤로가기 한 번이면 온 곳으로).
class PostLoadingScreen extends StatefulWidget {
  const PostLoadingScreen({
    super.key,
    required this.postId,
    this.reasons = const [],
    this.loaders = const AppLoaders(),
  });

  final int postId;
  final List<String> reasons;
  final AppLoaders loaders;

  @override
  State<PostLoadingScreen> createState() => _PostLoadingScreenState();
}

class _PostLoadingScreenState extends State<PostLoadingScreen> {
  late Future<Post?> _future = widget.loaders.post(widget.postId);

  void _retry() {
    // STATE: S3 서버 응답 상태 → B-8
    setState(() {
      _future = widget.loaders.post(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post?>(
      future: _future,
      builder: (context, snap) {
        final post = snap.data;
        if (snap.connectionState == ConnectionState.done && post != null) {
          return PostDetailScreen(
            post: post,
            reasons: widget.reasons,
            loadConditionCheck: widget.loaders.conditionCheck,
            loadPriceInfo: widget.loaders.priceInfo,
            loadUsageReviews: widget.loaders.usageReviews,
          );
        }
        final Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = const LoadingView(label: '게시글을 여는 중…'); // B-8 P01
        } else if (snap.hasError) {
          body = ErrorView(
            title: '게시글을 열지 못했습니다.',
            message: '${snap.error}',
            onRetry: _retry,
          ); // B-8 P09
        } else {
          body = const EmptyView(
            message: '삭제되었거나 찾을 수 없는 글입니다.\n뒤로 가서 다른 글을 골라 보세요.',
          ); // B-8 P09
        }
        return Scaffold(
          appBar: stackAppBar(title: const Text('게시글')),
          body: body,
        );
      },
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.reasons = const [],
    this.loadConditionCheck = fetchConditionCheck,
    this.loadPriceInfo = fetchPriceInfo,
    this.loadUsageReviews = fetchUsageReviews,
  });

  final Post post;

  /// C-5 추천 결과의 맞는 이유 — A에서 바로 들어오면 비어 있다 (B-3을 그리지 않음)
  final List<String> reasons;

  /// 데이터를 가져오는 함수 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final ConditionCheckLoader loadConditionCheck;
  final PriceInfoLoader loadPriceInfo;
  final UsageReviewsLoader loadUsageReviews;

  /// 장터 글만 AI 상태 체크 · 시세 · 사양 · 후기 탭이 있다
  bool get _isMarket => post.board == 'market';

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (label: '글 내용', view: _BodyTab(post: post)),
      if (_isMarket) ...[
        (
          label: 'AI 상태 체크',
          view: _ConditionCheckTab(
            postId: post.id,
            category: post.category,
            load: loadConditionCheck,
          ),
        ),
        (label: '시세', view: _PriceTab(post: post, load: loadPriceInfo)),
        (label: '사양', view: _SpecTab(post: post)),
        (
          label: '후기',
          view: _ReviewTab(postId: post.id, load: loadUsageReviews),
        ),
      ],
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: stackAppBar(
          title: Text(boardLabel(post.board)),
        ), // B-1 P03 진한 화살표 · 제목
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: detailMaxWidth),
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _PostHeader(post: post)),
                if (reasons.isNotEmpty)
                  SliverToBoxAdapter(child: _MatchReasons(reasons: reasons)),
                SliverToBoxAdapter(
                  // STATE: S6 선택된 판단 정보 탭 (AI 상태 체크 포함) → B-4 · B-6 (DefaultTabController가 화면 안에서만 처리)
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: TabBar(
                      isScrollable: tabs.length > 1,
                      tabAlignment: tabs.length > 1 ? TabAlignment.start : null,
                      tabs: [for (final t in tabs) Tab(text: t.label)],
                    ), // B-4 P07
                  ),
                ),
              ],
              body: TabBarView(children: [for (final t in tabs) t.view]),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: detailMaxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _contactSeller(context),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('판매자에게 연락하기'),
                  ), // B-7 P03
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// B-7 확인 창 — 취소할 수 있다. 확인해도 실제 연락 · 채팅은 없다
  Future<void> _contactSeller(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('판매자 연락'),
        content: const Text('판매자에게 연락할까요? (데모: 실제 연락은 되지 않습니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    ); // B-7 P03 취소 가능
    if (ok != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('데모 화면입니다 — 실제로 연락하지 않습니다.')));
  }
}

/// B-2 게시글 머리 — 사진 → 제목 → 가격(가장 크게) → 지역
/// 그라데이션 띠 위에 사진을 올리고, 그 아래 흰 카드에 판단 정보를 모은다.
class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final grey = text.bodyMedium?.copyWith(color: muleSubtle);
    return Stack(
      children: [
        Container(
          height: 120,
          decoration: const BoxDecoration(
            gradient: muleGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CategoryArt(post.category, radius: 20), // B-2 P02
              ), // B-2 P08
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.category,
                        style: text.labelMedium?.copyWith(color: mulePurple),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.title,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatWon(post.price),
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ), // B-2 P08 가격 가장 크게
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: muleSubtle,
                          ),
                          const SizedBox(width: 4),
                          Text(post.region, style: grey),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: muleSubtle,
                          ),
                          const SizedBox(width: 4),
                          Text(formatDate(post.createdAt), style: grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// B-3 내 조건과 맞는 이유 — C-5에서 들어왔을 때만 보인다
class _MatchReasons extends StatelessWidget {
  const _MatchReasons({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final r in reasons)
            Chip(
              avatar: Icon(Icons.check, size: 16, color: colors.primary),
              label: Text(r),
              backgroundColor: mulePurple.withValues(alpha: 0.08),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ), // B-3 P01
    );
  }
}

/// B-4 '글 내용' 탭
class _BodyTab extends StatelessWidget {
  const _BodyTab({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.body, style: text.bodyLarge),
                const SizedBox(height: 12),
                Text(
                  '작성일 ${formatDate(post.createdAt)}',
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// B-4 'AI 상태 체크' 탭 — GET /conditionChecks?postId=
class _ConditionCheckTab extends StatefulWidget {
  const _ConditionCheckTab({
    required this.postId,
    required this.category,
    required this.load,
  });

  final int postId;

  /// 자리표시 그림을 고를 카테고리
  final String category;
  final ConditionCheckLoader load;

  @override
  State<_ConditionCheckTab> createState() => _ConditionCheckTabState();
}

class _ConditionCheckTabState extends State<_ConditionCheckTab> {
  late Future<ConditionCheck?> _future = widget.load(widget.postId);

  void _retry() {
    setState(() {
      _future = widget.load(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConditionCheck?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(label: 'AI 상태 체크를 불러오는 중…');
        }
        if (snap.hasError) {
          return ErrorView(
            title: 'AI 상태 체크를 불러오지 못했습니다.',
            message: '${snap.error}',
            onRetry: _retry,
          );
        }
        final check = snap.data;
        if (check == null || check.items.isEmpty) {
          return const EmptyView(message: '이 매물은 아직 AI 상태 체크 결과가 없습니다.');
        }
        return ConditionCheckView(check: check, category: widget.category);
      },
    );
  }
}

/// B-6 AI 상태 체크 — 사진 위 해당 위치에 번호 → 항목별 상태(좋음 · 보통 · 확인 필요).
/// 결과와 번호 위치(x · y, 0–1 비율)는 db.json conditionChecks에 미리 써 둔 것 — 이미지를 분석하지 않는다.
/// 위치가 없는 항목만 사진 왼쪽 위에 모은다(위치를 지어내지 않음).
class ConditionCheckView extends StatelessWidget {
  const ConditionCheckView({
    super.key,
    required this.check,
    this.category = '',
  });

  final ConditionCheck check;

  /// 자리표시 그림을 고를 카테고리
  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color levelColor(String level) => switch (level) {
      '좋음' => const Color(0xFF2E9E6B), // 보라 그림 위에서도 보이게 초록
      '보통' => colors.tertiary,
      _ => colors.error, // 확인 필요
    };
    Widget badge(ConditionCheckItem item) => CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: levelColor(item.level),
        child: Text(
          '${item.no}',
          style: TextStyle(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: LayoutBuilder(
              builder: (context, box) {
                final placed = [
                  for (final item in check.items)
                    if (item.x != null && item.y != null) item,
                ];
                final loose = [
                  for (final item in check.items)
                    if (item.x == null || item.y == null) item,
                ];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CategoryArt(category, radius: 0),
                    // 미리 쓴 비율 위치에 번호를 올린다 (번호 원 반지름 14만큼 가운데 맞춤)
                    for (final item in placed)
                      Positioned(
                        left: item.x! * box.maxWidth - 14,
                        top: item.y! * box.maxHeight - 14,
                        child: badge(item),
                      ),
                    if (loose.isNotEmpty)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Wrap(
                          spacing: 6,
                          children: [for (final item in loose) badge(item)],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ), // B-6 P01 사진 위 번호
        const SizedBox(height: 8),
        for (final item in check.items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: badge(item),
              title: Text('${item.part} — ${item.level}'),
              subtitle: Text(item.note),
              trailing: Icon(
                item.level == '좋음'
                    ? Icons.check_circle_outline
                    : item.level == '보통'
                    ? Icons.info_outline
                    : Icons.help_outline,
                color: levelColor(item.level),
              ),
            ),
          ), // B-6 P01 항목별 상태
      ],
    );
  }
}

/// B-4 '시세' 탭 — GET /priceInfo?postId=
class _PriceTab extends StatefulWidget {
  const _PriceTab({required this.post, required this.load});

  final Post post;
  final PriceInfoLoader load;

  @override
  State<_PriceTab> createState() => _PriceTabState();
}

class _PriceTabState extends State<_PriceTab> {
  late Future<PriceInfo?> _future = widget.load(widget.post.id);

  void _retry() {
    setState(() {
      _future = widget.load(widget.post.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PriceInfo?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(label: '시세를 불러오는 중…');
        }
        if (snap.hasError) {
          return ErrorView(
            title: '시세를 불러오지 못했습니다.',
            message: '${snap.error}',
            onRetry: _retry,
          );
        }
        final info = snap.data;
        if (info == null) {
          return const EmptyView(message: '이 매물의 시세 정보가 아직 없습니다.');
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PriceRangeBar(info: info, price: widget.post.price),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// B-5 시세 범위 막대 — 최저 · 평균 · 최고 + 이 매물 위치 + 평균 눈금 + 한 줄 판단(priceInfo.label).
/// 시세 값은 미리 정한 데이터 그대로이고, 막대 위 위치(비율)만 그리기 위해 정한다.
class PriceRangeBar extends StatelessWidget {
  const PriceRangeBar({super.key, required this.info, required this.price});

  final PriceInfo info;
  final int price;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final span = info.high - info.low;
    final position = span <= 0
        ? 0.5
        : ((price - info.low) / span).clamp(0.0, 1.0);
    // 평균 눈금을 그릴 자리 — 막대 위 위치(비율)만 정한다. 싼지 비싼지는 label 문장 그대로 쓴다
    final avgAt = span <= 0
        ? 0.5
        : ((info.avg - info.low) / span).clamp(0.0, 1.0);
    Widget label(String name, int value, CrossAxisAlignment align) => Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(name, style: text.labelMedium),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatWon(value), style: text.bodyMedium),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이 매물 ${formatWon(price)}', style: text.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 22,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              alignment: Alignment.centerLeft,
              children: [
                LinearProgressIndicator(
                  value: position,
                  minHeight: 12,
                  color: muleOrange,
                  backgroundColor: mulePurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  semanticsLabel: '시세 범위 안 이 매물 위치',
                ),
                Positioned(
                  left: avgAt * box.maxWidth - 1,
                  top: 0,
                  bottom: 0,
                  child: Semantics(
                    label: '평균 위치',
                    child: Container(width: 2, color: muleInk),
                  ),
                ), // B-5 P07 평균 눈금
              ],
            ),
          ),
        ), // B-5 P07
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            label('최저', info.low, CrossAxisAlignment.start),
            label('평균', info.avg, CrossAxisAlignment.center),
            label('최고', info.high, CrossAxisAlignment.end),
          ],
        ), // B-5 P07
        if (info.label.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            info.label,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ), // B-5 P07 미리 쓴 한 줄 판단
        ],
      ],
    );
  }
}

/// B-4 '사양' 탭 — 브랜드 · 모델 · specs
class _SpecTab extends StatelessWidget {
  const _SpecTab({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (post.brand.isNotEmpty) ('브랜드', post.brand),
      if (post.model.isNotEmpty) ('모델', post.model),
      ...post.specs,
    ];
    if (rows.isEmpty) {
      return const EmptyView(message: '등록된 사양이 없습니다.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              for (final (name, value) in rows)
                ListTile(
                  dense: true,
                  title: Text(name),
                  trailing: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// B-4 '후기' 탭 — GET /usageReviews?postId= · 별점 → 한 줄 후기
class _ReviewTab extends StatefulWidget {
  const _ReviewTab({required this.postId, required this.load});

  final int postId;
  final UsageReviewsLoader load;

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab> {
  late Future<List<UsageReview>> _future = widget.load(widget.postId);

  void _retry() {
    setState(() {
      _future = widget.load(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UsageReview>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(label: '후기를 불러오는 중…');
        }
        if (snap.hasError) {
          return ErrorView(
            title: '후기를 불러오지 못했습니다.',
            message: '${snap.error}',
            onRetry: _retry,
          );
        }
        final reviews = snap.data ?? const <UsageReview>[];
        if (reviews.isEmpty) {
          return const EmptyView(message: '아직 후기가 없습니다.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = reviews[i];
            return Card(
              child: ListTile(
                leading: Text(
                  '★' * r.rating.clamp(0, 5) + '☆' * (5 - r.rating).clamp(0, 5),
                  style: const TextStyle(color: muleOrange),
                  semanticsLabel: '별점 ${r.rating}점',
                ),
                title: Text(r.text),
              ),
            );
          },
        ); // B-4 P07 후기
      },
    );
  }
}
