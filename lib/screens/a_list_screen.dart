// 화면 A: 통합 홈 (GET /alerts · /notices) — 하단 메뉴 '홈'
//
// ── 디자인 가이드 대응표: 화면 A — 통합 홈 (docs/디자인가이드.md 3장과 같게) ────────────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준(무엇을 · 순서 · 강조) | 원칙(P번호 · 이유) | 편의성 포인트 |
// |---|---|---|---|---|---|
// | A-1 | GradientHeader · HeaderIconButton | 상단 인사 바 | 앱 이름 → 음악 활동 전체를 아우르는 인사 한 줄("오늘은 어떤 음악 활동을 펼쳐볼까요?") · 오른쪽 알림 아이콘(새 글 있으면 주황 점) | P04 · P02 · 모든 메뉴 같은 자리 · 커뮤니티 전체를 부름 | 새 글이 있는지 첫눈에 앎 |
// | A-2 | TextField + IconButton | AI 조건 입력창 | 헤더 안 흰 입력창 · 예시 문장 힌트 · 쓴 글이 있으면 지우기(X) · 비어 있으면 보내기 꺼짐 | P06 · P05 · P03 · 키워드 대신 문장 · 빈 문장 막기 · 한 번에 지우기 | 키워드를 정확히 기억 안 해도 됨 |
// | A-3 | SingleChildScrollView(가로) · PillButton | 예시 조건 칩 | 입력창 아래 안내 한 줄 "AI에게 이렇게 물어보세요" → 가로 한 줄 · 3개 | P06 · 보고 고르기 | 첫 문장을 직접 안 써도 됨 · 알림 조건이 첫 화면에 들어옴 |
// | A-9 | Row · InkWell | 게시판 바로가기 | 장터 · 합주실 · 레슨 · 구인 · 공연 아이콘 5개 | P02 · P07 | 누르면 게시판 메뉴의 그 게시판으로 |
// | A-8 | PillButton · ListView(가로) · Card | 내 알림 조건 | 게시판 바로가기 아래 · 조건 알약(새 글 수는 숫자만 주황 배지) → 그 조건의 새 글 낮은 가로 카드(사진 → 제목 → 게시판 · 가격) · "AI 검색으로 보기"(E-2와 같은 이름) | P01 · P04 · P07 · P08 · P02 | 게시판을 돌지 않아도 걸어 둔 조건의 새 글을 바로 봄 |
// | A-5 | Card · ExpansionTile | 공지 접기 줄 | 기본 1줄로 접힘 · 누르면 펼침 | P08 · 공지 7줄 제거 | 새 글까지 스크롤 안 해도 됨 |
// | A-10 | FutureBuilder · LoadingView · ErrorView · EmptyView · RefreshIndicator | 알림 조건 상태 안내 | 로딩 → 오류 + 다시 시도 → 빈 목록 안내(알림 거는 법) · 아래로 당겨 새로고침 | P09 · 복구 방법 제시 | 오류 때 앱을 껐다 켜지 않아도 됨 |
// ────────────────────────────────────────────────────────────────────────────────────────
// (예전 A-4 게시판 탭 · A-6 게시글 카드 목록 · A-7 목록 상태 안내는 하단 메뉴 '게시판' = 화면 D의 D-2 · D-3 · D-4로 옮겼다)
// 전환: A → C 덮기(showModalBottomSheet: A-2 보내기 · A-8 AI 검색) · A → B 쌓기(A-8 새 글 카드)
//       A → D 옆으로(A-9 바로가기 → 하단 메뉴 게시판) · A → E 옆으로(A-1 알림 아이콘 · A-8 전체 보기)
// 적응형: 넓은 창에서도 본문은 최대 720dp로 가운데 (헤더만 가로 전체).
// 상태관리 포인트: S1 입력 문장 · S3 서버 응답 상태 · S7 선택된 알림 조건 → `grep -rn "STATE:" lib`
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';
import 'c_result_sheet.dart';

/// 홈 본문 최대 너비 — 넓은 창에서 줄이 너무 길어지지 않게
const homeMaxWidth = 720.0;

/// A-3 예시 조건 칩 — 누르면 입력창이 채워진다. responseId = C에서 보여 줄 미리 쓴 응답 (2번 칩 빈 결과 id=2 · 3번 칩 베이스 레슨 id=3)
const exampleConditions = [
  (text: '60만 원 이하 펜더 일렉, 앰프 빼고', responseId: 1),
  (text: '강남 주말 드럼 합주실 1만 원 이하', responseId: 2),
  (text: '베이스 레슨 초보', responseId: 3),
];

/// A-9 게시판 바로가기 아이콘 (boardTabs 순서)
const boardIcons = [
  Icons.storefront_outlined, // 장터
  Icons.graphic_eq, // 합주실
  Icons.school_outlined, // 레슨
  Icons.group_add_outlined, // 구인
  Icons.mic_none, // 공연
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.loaders = const AppLoaders(),
    this.onOpenBoard,
    this.onOpenAlerts,
  });

  /// 데이터를 가져오는 함수 묶음 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final AppLoaders loaders;

  /// A-9 → 하단 메뉴 '게시판'의 그 게시판 (boardTabs 번호)
  final ValueChanged<int>? onOpenBoard;

  /// A-1 알림 아이콘 · A-8 전체 보기 → 하단 메뉴 '알림'
  final VoidCallback? onOpenAlerts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _query = TextEditingController();
  late Future<List<SearchAlert>> _alerts = widget.loaders.alerts();
  late Future<List<Notice>> _notices = widget.loaders.notices();

  /// A-8에서 고른 알림 조건 번호
  var _alertIndex = 0;

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
    // 띄어쓰기만 다르면 같은 예시로 본다 (직접 칠 때 빈칸 실수로 다른 응답이 나오지 않게) — 문장 해석 아님
    String bare(String t) => t.replaceAll(RegExp(r'\s'), '');
    final example = exampleConditions
        .where((e) => bare(e.text) == bare(query))
        .firstOrNull;
    AiSearchConfirmSheet.show(
      context,
      query: query,
      responseId: example?.responseId ?? 1,
      loaders: widget.loaders,
    );
  }

  /// A-8 AI 검색 → 알림을 걸 때 쓴 문장으로 C 시트를 연다
  void _searchAlert(SearchAlert alert) {
    AiSearchConfirmSheet.show(
      context,
      query: alert.query,
      responseId: alert.responseId,
      loaders: widget.loaders,
    );
  }

  /// A-8 새 글 카드 → B 게시글 상세 (쌓기)
  void _openMatch(AlertMatch match) {
    openPostById(context, widget.loaders, match.postId);
  }

  void _selectAlert(int index) {
    // STATE: S7 선택된 알림 조건 → A-8
    setState(() {
      _alertIndex = index;
    });
  }

  /// A-10 · A-5 다시 시도 · 당겨서 새로고침 = Future만 새로 만드는 setState
  Future<void> _retry() {
    // STATE: S3 서버 응답 상태 → A-10 · A-5
    setState(() {
      _alerts = widget.loaders.alerts();
      _notices = widget.loaders.notices();
    });
    return settle(Future.wait([_alerts, _notices]));
  }

  void _clearQuery() {
    // STATE: S1 입력 문장 → A-2 · C-1
    _query.clear();
  }

  @override
  Widget build(BuildContext context) {
    // A-10 P09 당겨서 다시 불러오기 (알림 조건 · 공지)
    return RefreshIndicator(
      onRefresh: _retry,
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FutureBuilder<List<SearchAlert>>(
              future: _alerts,
              builder: (context, snap) => GradientHeader(
                title: 'MuBase',
                subtitle:
                    '오늘은 어떤 음악 활동을 펼쳐볼까요?', // A-1 P02 음악 활동 전체
                actions: [
                  HeaderIconButton(
                    icon: Icons.notifications_none,
                    tooltip: '알림 보기',
                    dot: (snap.data ?? const []).any((a) => a.newCount > 0),
                    onPressed: () => widget.onOpenAlerts?.call(),
                  ),
                ], // A-1 P04
                // STATE: S1 입력 문장 → A-2 · C-1
                bottom: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    hintText: '예: 60만 원 이하 펜더 일렉, 앰프는 빼고',
                    prefixIcon: const Icon(
                      Icons.auto_awesome,
                      color: mulePurple,
                    ),
                    // 비어 있으면 보내기를 끄고, 쓴 글이 있으면 지우기(X)를 보인다
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: _query,
                      builder: (context, value, _) {
                        final empty = value.text.trim().isEmpty;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (value.text.isNotEmpty)
                              IconButton(
                                onPressed: _clearQuery,
                                icon: const Icon(
                                  Icons.cancel,
                                  color: muleSubtle,
                                ),
                                tooltip: '지우기',
                              ), // A-2 P03 지우기
                            IconButton(
                              onPressed: empty ? null : _send,
                              icon: const Icon(Icons.send),
                              color: mulePurple,
                              tooltip: '보내기',
                            ), // A-2 P05 빈 문장은 보내지 않음
                          ],
                        );
                      },
                    ),
                  ),
                ), // A-2 P06
              ),
            ),
          ),
          _section(
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(
                'AI에게 이렇게 물어보세요',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: muleSubtle),
              ),
            ),
          ),
          _section(
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final example in exampleConditions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PillButton(
                        label: example.text,
                        icon: Icons.auto_awesome,
                        onTap: () => _fillExample(example.text),
                      ),
                    ),
                ],
              ), // A-3 P06 가로 한 줄
            ),
          ),
          _section(const SectionTitle('게시판 바로가기')),
          _section(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final (i, b) in boardTabs.indexed)
                    Expanded(
                      child: _BoardShortcut(
                        icon: boardIcons[i],
                        label: b.label,
                        onTap: () => widget.onOpenBoard?.call(i),
                      ),
                    ),
                ],
              ), // A-9 P02 · P07
            ),
          ),
          _section(
            SectionTitle(
              '내 알림 조건',
              action: '전체 보기',
              onAction: widget.onOpenAlerts,
            ),
          ),
          _section(
            FutureBuilder<List<SearchAlert>>(
              future: _alerts,
              builder: (context, snap) {
                // 당겨서 새로고침 중에는 이전 목록을 그대로 둔다 (깜빡이지 않게)
                if (snap.connectionState != ConnectionState.done &&
                    !snap.hasData) {
                  return const SizedBox(
                    height: 160,
                    child: LoadingView(label: '알림 조건을 불러오는 중…'),
                  ); // A-10 P09
                }
                if (snap.hasError) {
                  return ErrorView(
                    title: '알림 조건을 불러오지 못했습니다.',
                    message: '${snap.error}',
                    onRetry: _retry,
                  ); // A-10 P09
                }
                final alerts = snap.data ?? const <SearchAlert>[];
                if (alerts.isEmpty) {
                  return const EmptyView(
                    message:
                        '아직 알림을 건 조건이 없어요.\n입력창에 찾는 조건을 말하고 "이 조건으로 알림"을 눌러 보세요.',
                  ); // A-10 P09
                }
                return _AlertShelf(
                  alerts: alerts,
                  selected: _alertIndex.clamp(0, alerts.length - 1),
                  onSelect: _selectAlert,
                  onOpenMatch: _openMatch,
                  onSearch: _searchAlert,
                ); // A-8 P01 · P07
              },
            ),
          ),
          _section(const SectionTitle('공지')),
          _section(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _NoticeFold(future: _notices, onRetry: _retry),
            ),
          ),
        ],
      ),
    );
  }

  /// 본문 한 구역 — 넓은 창에서 가운데 최대 720dp
  Widget _section(Widget child) => SliverToBoxAdapter(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: homeMaxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

/// A-8 내 알림 조건 — 조건 칩을 고르면 그 조건에 걸린 새 글이 가로로 나온다
class _AlertShelf extends StatelessWidget {
  const _AlertShelf({
    required this.alerts,
    required this.selected,
    required this.onSelect,
    required this.onOpenMatch,
    required this.onSearch,
  });

  final List<SearchAlert> alerts;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<AlertMatch> onOpenMatch;
  final ValueChanged<SearchAlert> onSearch;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final alert = alerts[selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final (i, a) in alerts.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8),
                  // 새 글 수는 칩 오른쪽 위 주황 배지로 (칩 안에 넣으면 글자가 잘린다)
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PillButton(
                        label: a.name,
                        selected: i == selected,
                        onTap: () => onSelect(i),
                      ),
                      if (a.newCount > 0)
                        Positioned(
                          right: -6,
                          top: -8,
                          child: NewBadge(count: a.newCount), // A-8 P08 숫자만
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 14),
          decoration: BoxDecoration(
            color: mulePurple.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      alert.labels.join(' · '),
                      style: text.bodySmall?.copyWith(color: muleSubtle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onSearch(alert),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('AI 검색으로 보기'),
                  ), // A-8 P04 알림 화면(E-2)과 같은 이름
                ],
              ),
              if (alert.matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  child: Text(
                    '아직 새 글이 없어요. 새 글이 올라오면 여기에 보여요.',
                    style: text.bodyMedium,
                  ),
                )
              else
                SizedBox(
                  // 사진 100 + 글자 줄 — 글자 크기 설정이 커져도 카드가 넘치지 않게
                  height: scaledHeight(context, 24, 62),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 8),
                    itemCount: alert.matches.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _MatchCard(
                      match: alert.matches[i],
                      onTap: () => onOpenMatch(alert.matches[i]),
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

/// A-8 새 글 카드 한 장 — 낮은 가로 카드: 카테고리 그림 → 제목 → 게시판 · 가격 (홈에서 알림이 다시 크게 강조되지 않게)
class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});

  final AlertMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 236,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                PostImage(
                  match.image,
                  category: match.category,
                  width: 56,
                  height: 56,
                ), // A-8 P02
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        match.title,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${match.board} · ${formatWon(match.price)}',
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A-9 게시판 바로가기 한 칸 — 둥근 네모 아이콘 + 이름
class _BoardShortcut extends StatelessWidget {
  const _BoardShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: muleLine),
              ),
              child: Icon(icon, color: mulePurple),
            ),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// A-5 공지 접기 줄 — 기본 1줄로 접혀 있고 누르면 펼친다.
class _NoticeFold extends StatelessWidget {
  const _NoticeFold({required this.future, required this.onRetry});

  final Future<List<Notice>> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.campaign_outlined, color: muleOrange);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<List<Notice>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const ListTile(leading: icon, title: Text('공지를 불러오는 중…'));
          }
          if (snap.hasError) {
            return ListTile(
              leading: icon,
              title: const Text('공지를 불러오지 못했습니다.'),
              trailing: TextButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            );
          }
          final notices = snap.data ?? const <Notice>[];
          if (notices.isEmpty) {
            return const ListTile(leading: icon, title: Text('새 공지가 없습니다.'));
          }
          return ExpansionTile(
            leading: icon,
            title: Text(
              notices.first.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('공지 ${notices.length}건 · 눌러서 펼치기'),
            children: [
              for (final n in notices)
                ListTile(dense: true, title: Text(n.text)),
            ],
          ); // A-5 P08
        },
      ),
    );
  }
}
