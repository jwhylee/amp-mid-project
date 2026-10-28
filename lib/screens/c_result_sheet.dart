// 화면 C: AI 검색 확인 시트 (GET /aiResponses?id= — 미리 정한 응답)
//
// ── 디자인 가이드 대응표: 화면 C — AI 검색 확인 시트 (docs/디자인가이드.md 3장과 같게) ───────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준 | 원칙 | 편의성 포인트 |
// |---|---|---|---|---|---|
// | C-1 | Text | 내가 말한 문장 | 시트 맨 위 · 작게 · 회색 | P01 | 무엇을 물었는지 기억 안 해도 됨 |
// | C-2 | Wrap + InputChip | AI가 알아들은 조건 영역 | 예: [일렉기타] [펜더] [60만 원 이하] [앰프 빼기 X] · 연보라 채움 + 진한 글자(홈 예시 칩과 구분) · 추가 키워드는 보라 테두리 · 제거 키워드는 빨간 테두리 · 시트에서 가장 크게 · 뺀 뒤 "되돌리기"(알림은 4초 뒤 · 시트를 닫으면 사라짐) · 칩 줄 아래 "추천 결과 n개 · 게시판 이름" | P05 · P03 · P01 · P07 · P04 · #1 #2 | 결과를 보기 전에 오해를 고침 · 잘못 빼도 되돌림 · 결과가 몇 개 어디서 왔는지 미리 앎 |
// | C-3 | TextButton + showDialog | 키워드 제거 버튼 | 조건 줄 끝 "− 키워드 제거" · 비어 있으면 "추가" 꺼짐 | P05 · #2 요청 | "esp"→"lespaul" 같은 엉뚱한 결과를 미리 막음 |
// | C-4 | Card + Text + InkWell | AI 조언 카드 | 목적 요약 → 1순위와 이유 → 비교표 → 확인할 것 → 예산 바꾸면 → 근거 (접힘: 목적 요약 · 1순위 한 줄 · "자세히 보기" · "미리 써 둔 예시 답변이에요 · 참고용" / 펼침 마지막 줄은 근거 + " · 참고용" 한 줄 / 1순위 없는 응답은 목적 · 예산 · 근거만) | P10 · P06 · P05 · P01 · P08 · #7 | 시세 · 상태를 혼자 따져 보지 않아도 됨 |
// | C-5 | ListView + ListTile | 추천 결과 목록 | 게시판 라벨 → 제목 → 가격 → 추천 이유 줄 · 조건을 고치면 위에 "조건이 바뀌었어요 — 다시 찾기" 배너 | P06 · P01 | 왜 나왔는지 상세에 안 들어가도 앎 · 결과가 옛 조건 기준임을 앎 |
// | C-6 | FutureBuilder + LoadingView + ErrorView + EmptyView | AI 응답 상태 안내 | 찾는 중 → 오류 + 다시 시도 → 결과 없음(조건 하나 빼기 제안) | P09 | 결과 0건에서 막히지 않음 |
// | C-7 | FilledButton + OutlinedButton | 다시 찾기 · 알림 받기 | 시트 맨 아래 한 줄 | P03 · P04 | 처음부터 다시 말하지 않아도 됨 · 검색과 알림 조건을 두 번 설정 안 함 |
// | C-8 | IconButton + showDialog | 닫기 확인 창 | 시트 오른쪽 위 닫기 · 조건을 고친 적이 있으면 닫기 · 바깥 누르기 · 끌어 내리기 때 "고친 조건을 버릴까요?"(취소 / 버리기) · 저장 없음 | P03 · P05 | 실수로 닫아 고친 조건을 잃지 않음 |
// | C-9 | TextButton + showDialog | 키워드 추가 버튼 | 조건 줄 끝 "+ 키워드 추가" (키워드 제거 버튼 앞) · 확인하면 [○○ 포함] 칩(보라 테두리) · 비어 있으면 "추가" 꺼짐 | P07 · P05 | 꼭 들어가야 할 단어("하드케이스" 등)를 처음부터 다시 말하지 않고 덧붙임 |
// ────────────────────────────────────────────────────────────────────────────────────────
// 전환: A · E → C 덮기(showModalBottomSheet, A-2 보내기 · 알림 조건의 AI 검색) · C → B 쌓기(Navigator.push, C-5 추천 결과) — B에서 뒤로 가면 시트로.
// 적응형: 넓은 화면에서 시트 최대 너비 720dp로 가운데 정렬.
// 상태관리 포인트(가이드 5장): S1 입력 문장 · S3 서버 응답 상태 · S4 AI가 알아들은 조건 목록(고친 적 있음 → C-8 닫기 확인 창 · C-5 배너) · S5 AI 조언 펼침 / 접힘 → `grep -rn "STATE:" lib`
//
// ⚠ 실제 문장 해석·추천 계산 없음 (안내 5장: "실제 비즈니스 로직"은 감점).
//   어떤 문장이든 미리 쓴 응답(id=1, 예시 조건 칩 2번 id=2 · 3번 id=3, 알림 조건은 각자의 responseId)을 그대로 보여 준다.
//   조건을 빼거나 추가 키워드 · 제거 키워드를 넣어도 화면 표시만 바뀌고, 다시 찾기는 같은 응답을 다시 GET한다.
//   AI 조언 카드(C-4) 컨설팅도 db.json aiResponses.consulting에 미리 쓴 문자열 그대로다 — 계산 · 비교 · 정렬하지 않는다.
//   알림 받기(C-7)는 SnackBar만 띄운다. 닫기 확인 창(C-8)은 고친 조건을 저장하지 않고 버릴지만 묻는다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';

/// 넓은 화면에서 시트 최대 너비 (가이드 1장 적응형)
const sheetMaxWidth = 720.0;

/// C-2 AI가 알아들은 조건 영역의 표시 순서 (가이드 4장) — 모르는 type은 맨 뒤
const _conditionTypes = [
  'category',
  'brand',
  'price',
  'region',
  'include',
  'exclude',
];

/// C-2 칩 글자 — 추가 키워드는 "○○ 포함", 제거 키워드는 "○○ 빼기"
String _conditionLabel(AiCondition c) => switch (c.type) {
  'include' => '${c.label} 포함',
  'exclude' => '${c.label} 빼기',
  _ => c.label,
};

int _conditionOrder(String type) {
  final i = _conditionTypes.indexOf(type);
  return i < 0 ? _conditionTypes.length : i;
}

class AiSearchConfirmSheet extends StatefulWidget {
  const AiSearchConfirmSheet({
    super.key,
    required this.query,
    this.responseId = 1,
    this.loaders = const AppLoaders(),
  });

  /// A-2에서 보낸 문장 — C-1에 그대로 보여 준다 (해석하지 않는다)
  final String query;

  /// 미리 쓴 응답 번호 — 1: 결과 있음 · 2: 결과 없음(예시 조건 칩 2번)
  final int responseId;

  /// 데이터를 가져오는 함수 묶음 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final AppLoaders loaders;

  /// 덮기(modal): 통합 홈 위에 시트를 띄운다.
  static Future<void> show(
    BuildContext context, {
    required String query,
    int responseId = 1,
    AppLoaders loaders = const AppLoaders(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // 기본 끌기 손잡이는 끌어 내리면 PopScope를 거치지 않고 닫힌다 → 시트 안 손잡이(_DragToClose)가 대신 maybePop
      enableDrag: false,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: sheetMaxWidth),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: AiSearchConfirmSheet(
          query: query,
          responseId: responseId,
          loaders: loaders,
        ),
      ),
    );
  }

  @override
  State<AiSearchConfirmSheet> createState() => _AiSearchConfirmSheetState();
}

class _AiSearchConfirmSheetState extends State<AiSearchConfirmSheet> {
  /// 시트 안 SnackBar — 바깥 Scaffold에 띄우면 시트에 가려진다
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  late Future<AiResponse?> _future = _load();

  /// C-2 AI가 알아들은 조건 영역 — 첫 응답에서 한 번만 채우고, 이후로는 화면에서 고친 그대로 둔다
  List<AiCondition>? _conditions;

  /// C-4 AI 조언 카드 펼침 여부
  var _adviceExpanded = false;

  /// C-8 조건을 한 번이라도 고쳤는지 — 닫을 때 확인 창을 띄운다 (저장하지 않는다)
  var _edited = false;

  /// C-5 위 배너 — 조건을 고친 뒤 아직 다시 찾지 않았으면 true
  var _stale = false;

  /// 손잡이를 끄는 동안 시트가 따라 내려가는 거리 (놓으면 0)
  var _drag = 0.0;

  Future<AiResponse?> _load() async {
    final response = await widget.loaders.aiResponse(widget.responseId);
    _conditions ??= [...?response?.conditions];
    return response;
  }

  /// C-6 다시 시도 · C-7 다시 찾기 — 같은 응답을 다시 GET (계산하지 않는다)
  void _retry() {
    // STATE: S3 서버 응답 상태 → C-6 · S4 배너 닫힘 → C-5
    setState(() {
      _future = _load();
      _stale = false;
    });
  }

  /// 조건을 고쳤다는 표시 — C-8 닫기 확인 창 · C-5 배너
  void _markEdited() {
    _edited = true;
    _stale = true;
  }

  /// C-8 닫기 확인 창 — 고친 조건이 있으면 버릴지 묻는다 (취소 / 버리기)
  Future<void> _confirmClose() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고친 조건을 버릴까요?'),
        content: const Text('시트를 닫으면 빼거나 더한 조건이 사라져요. 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('버리기'),
          ),
        ],
      ),
    ); // C-8 P03 · P05
    if (discard != true || !mounted) return;
    // STATE: S4 AI가 알아들은 조건 목록 → 버림 (시트를 닫는다)
    setState(() {
      _edited = false;
    });
    Navigator.of(context).pop();
  }

  /// C-2 조건 빼기 — 잘못 눌러도 SnackBar의 "되돌리기"로 같은 자리에 돌려놓는다
  void _removeCondition(AiCondition condition) {
    final list = _conditions;
    if (list == null) return;
    final index = list.indexOf(condition);
    // STATE: S4 AI가 알아들은 조건 목록 → C-2 · C-5 배너 · C-8
    setState(() {
      list.remove(condition);
      _markEdited();
    });
    _showSnack(
      '"${_conditionLabel(condition)}" 조건을 뺐어요',
      action: SnackBarAction(
        label: '되돌리기',
        onPressed: () {
          // STATE: S4 AI가 알아들은 조건 목록 → C-2 (되돌리기)
          setState(() {
            list.insert(index.clamp(0, list.length), condition);
          });
        },
      ), // C-2 P03 되돌리기
    );
  }

  /// C-3 키워드 제거 · C-9 키워드 추가 — 입력한 단어를 조건 칩으로 붙이기만 한다 (거르거나 저장하지 않는다)
  Future<void> _addWord({required String type}) async {
    final include = type == 'include';
    final word = await showDialog<String>(
      context: context,
      builder: (_) => _ConditionWordDialog(
        title: include ? '키워드 추가' : '키워드 제거',
        hint: include ? '예: 하드케이스, 픽업 교체' : '예: 앰프, lespaul',
      ),
    ); // C-3 P05 · C-9 P05
    if (!mounted || word == null || word.trim().isEmpty) return;
    // STATE: S4 AI가 알아들은 조건 목록 → C-2 · C-5 배너 · C-8 (저장하지 않는다)
    setState(() {
      _conditions = [
        ...?_conditions,
        AiCondition(type: type, label: word.trim()),
      ];
      _markEdited();
    });
  }

  void _toggleAdvice() {
    // STATE: S5 AI 조언 펼침 / 접힘 → C-4
    setState(() {
      _adviceExpanded = !_adviceExpanded;
    });
  }

  /// C-7 알림 받기 — SnackBar만. 실제 알림 등록은 없다
  void _subscribe() {
    _showSnack('이 조건으로 새 글 알림을 받아요 (데모: 실제 등록은 없습니다)');
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          // 요즘 Flutter는 action이 있으면 기본으로 닫지 않는다 → 4초 뒤 사라지게
          persist: false,
          duration: const Duration(seconds: 4),
        ),
      ); // C-2 P03 · P01 되돌리기 알림은 4초 뒤 닫힘
  }

  /// C-5 추천 결과 → B 게시글 상세 (쌓기 — 뒤로 가면 이 시트로 돌아온다)
  void _openResult(AiResult result) {
    openPostById(
      context,
      widget.loaders,
      result.postId,
      reasons: result.reasons, // → B-3 내 조건과 맞는 이유
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    // C-8 닫기 확인 창 — 닫기 버튼 · 바깥 누르기 · 끌어 내리기 모두 여기를 지난다
    return PopScope(
      canPop: !_edited,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmClose();
          return;
        }
        // 시트가 닫히면 되돌리기 알림도 남기지 않는다 (시트 안 · 바깥 둘 다)
        _messenger.currentState?.hideCurrentSnackBar();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Transform.translate(
        offset: Offset(0, _drag),
        child: ScaffoldMessenger(
          key: _messenger,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            // 끌어 내리기 — 충분히 내리면 maybePop → 고친 조건이 있으면 C-8 확인 창
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: _DragToClose(
                onDrag: (dy) => setState(() {
                  _drag = (_drag + dy).clamp(0.0, 400.0);
                }),
                onRelease: (fling) {
                  final close = fling || _drag > 80;
                  setState(() {
                    _drag = 0;
                  });
                  if (close) Navigator.of(context).maybePop();
                },
              ), // C-8 P03 · P05 끌어 내리기도 확인을 거침
            ),
            body: FutureBuilder<AiResponse?>(
              future: _future,
              builder: (context, snap) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  // STATE: S1 입력 문장 → A-2 · C-1
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: mulePurple,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'AI가 이렇게 알아들었어요',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                      ), // C-8 P03 · P05
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '“${widget.query}”',
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ), // C-1 P01
                  const SizedBox(height: 12),
                  ..._body(snap, text, colors),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 찾기'),
                      ), // C-7 P03
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _subscribe,
                        icon: const Icon(Icons.notifications_none),
                        label: const Text('이 조건으로 알림'),
                      ), // C-7 P04
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// C-6 상태에 따라 C-2 ~ C-5를 그린다
  List<Widget> _body(
    AsyncSnapshot<AiResponse?> snap,
    TextTheme text,
    ColorScheme colors,
  ) {
    if (snap.connectionState != ConnectionState.done) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: LoadingView(label: '조건에 맞는 글을 찾는 중…'),
        ), // C-6 P09
      ];
    }
    if (snap.hasError) {
      return [
        ErrorView(
          title: 'AI 응답을 불러오지 못했습니다.',
          message: '${snap.error}',
          onRetry: _retry,
        ), // C-6 P09
      ];
    }
    // 가이드 순서(카테고리 → 브랜드 → 가격 → 지역 → 추가 키워드 → 제거 키워드)로 보여 주기만 한다 — 표시 순서 정렬, 계산 아님
    final conditions = [...?_conditions]
      ..sort(
        (a, b) => _conditionOrder(a.type).compareTo(_conditionOrder(b.type)),
      );
    final advice = snap.data?.advice ?? '';
    final consulting = snap.data?.consulting;
    final results = snap.data?.results ?? const <AiResult>[];
    // 응답에 들어 있는 결과를 세고 게시판 이름을 나온 순서대로 적을 뿐 — 거르거나 계산하지 않는다
    final boards = {for (final r in results) r.board}.join(' · ');
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final c in conditions)
            InputChip(
              label: Text(
                _conditionLabel(c),
                style: text.titleMedium?.copyWith(
                  color: muleInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              avatar: switch (c.type) {
                'include' => const Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: mulePurple,
                ),
                'exclude' => Icon(Icons.block, size: 18, color: colors.error),
                _ => null,
              },
              // 연보라 채움 — 홈의 흰 예시 칩(A-3)과 역할을 구분한다
              backgroundColor: mulePurple.withValues(alpha: 0.12),
              side: switch (c.type) {
                'include' => const BorderSide(color: mulePurple, width: 1.5),
                'exclude' => BorderSide(color: colors.error, width: 1.5),
                _ => BorderSide.none,
              },
              deleteIconColor: muleInk,
              deleteButtonTooltipMessage: '조건 빼기',
              onDeleted: () => _removeCondition(c),
            ), // C-2 P05 · P04 연보라 채움
          TextButton(
            onPressed: () => _addWord(type: 'include'),
            child: const Text('+ 키워드 추가'),
          ), // C-9 P07 · P05
          TextButton(
            onPressed: () => _addWord(type: 'exclude'),
            child: const Text('− 키워드 제거'),
          ), // C-3 P05
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: Text(
          results.isEmpty ? '추천 결과 없음' : '추천 결과 ${results.length}개 · $boards',
          style: text.bodyMedium?.copyWith(color: muleSubtle),
        ), // C-2 P01 · P07 결과 수와 게시판을 미리 알림
      ),
      if (consulting != null)
        _ConsultingCard(
          consulting: consulting,
          expanded: _adviceExpanded,
          onToggle: _toggleAdvice,
          onOpenPost: (postId) => openPostById(context, widget.loaders, postId),
        )
      else if (advice.isNotEmpty)
        _AdviceCard(
          advice: advice,
          expanded: _adviceExpanded,
          onToggle: _toggleAdvice,
        ), // C-4 P10
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          '추천 결과',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      if (_stale)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            color: muleOrange.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: muleOrange.withValues(alpha: 0.4)),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: muleOrange),
              title: const Text('조건이 바뀌었어요 — 다시 찾기'),
              subtitle: const Text('아래 결과는 바꾸기 전 조건으로 찾은 것이에요'),
              trailing: TextButton(
                onPressed: _retry,
                child: const Text('다시 찾기'),
              ),
            ),
          ),
        ), // C-5 P01 결과가 옛 조건 기준임을 알림
      if (results.isEmpty)
        const EmptyView(message: '조건에 맞는 글이 없습니다.\n조건을 하나 빼 보세요.') // C-6 P09
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = results[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.board,
                      style: text.labelMedium?.copyWith(color: colors.primary),
                    ),
                    Text(r.title, style: text.titleMedium),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatWon(r.price),
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: muleInk,
                      ),
                    ),
                    Text(
                      r.reasons.join(' · '),
                      style: const TextStyle(color: muleOrange),
                    ), // C-5 P01 추천 이유 줄
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openResult(r),
              ),
            );
          },
        ), // C-5 P06
    ];
  }
}

/// 시트 맨 위 끌기 손잡이 — 아래로 끌면 시트가 따라 내려가고, 놓을 때 충분히 내렸거나 빠르게 튕겼으면 닫기를 요청한다
class _DragToClose extends StatelessWidget {
  const _DragToClose({required this.onDrag, required this.onRelease});

  final ValueChanged<double> onDrag;

  /// true: 빠르게 아래로 튕김
  final ValueChanged<bool> onRelease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '끌어 내려 닫기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
        onVerticalDragEnd: (d) => onRelease((d.primaryVelocity ?? 0) > 700),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: muleSubtle.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// C-4 AI 조언 카드 — 컨설팅 6칸. 모든 문장 · 값은 db.json에 미리 쓴 그대로 (계산 · 비교 · 정렬 없음)
/// 접힘: ① 내 목적 요약 · ② 1순위 한 줄 · "자세히 보기"
/// 펼침: ② 1순위 이유 → ③ 비교표 → ④ 사기 전 확인할 것 → ⑤ 예산을 바꾸면 → ⑥ 근거 · 한계
/// 1순위가 없는 응답(결과 없음)은 ②③④를 숨기고 ①⑤⑥만.
class _ConsultingCard extends StatelessWidget {
  const _ConsultingCard({
    required this.consulting,
    required this.expanded,
    required this.onToggle,
    required this.onOpenPost,
  });

  final AiConsulting consulting;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<int> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pick = consulting.pick;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: text.labelLarge?.copyWith(
          color: mulePurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    Widget line(IconData icon, Color color, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
    return Card(
      color: mulePurple.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: mulePurple,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI 조언',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ① 내 목적 요약 — 작은 칩 한 줄
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final g in consulting.goal)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: muleLine),
                      ),
                      child: Text(g, style: text.labelMedium),
                    ),
                ],
              ),
            ), // C-4 P10 내 목적 요약
            // ② 1순위 한 줄
            if (pick != null) ...[
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '1순위 · ',
                      style: TextStyle(
                        color: muleOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: pick.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' — ${pick.headline}'),
                  ],
                ),
                style: text.bodyMedium,
              ),
            ],
            if (expanded) ...[
              if (pick != null) ...[
                section('1순위 추천 이유'),
                for (final r in pick.reasons)
                  line(Icons.check_circle, mulePurple, r), // C-4 P10
                if (consulting.compare.isNotEmpty) ...[
                  section('비교'),
                  for (final row in consulting.compare)
                    _CompareRow(row: row, onTap: () => onOpenPost(row.postId)),
                ],
                if (consulting.checklist.isNotEmpty) ...[
                  section('사기 전 확인할 것'),
                  for (final c in consulting.checklist)
                    line(Icons.help_outline, muleOrange, c), // C-4 P05
                ],
              ],
              if (consulting.budgetTips.isNotEmpty) ...[
                section('예산을 바꾸면'),
                for (final t in consulting.budgetTips)
                  line(Icons.swap_vert, mulePurple, t), // C-4 P10
              ],
              section('근거 · 한계'),
              // 펼치면 근거 줄 하나로 끝낸다 — 아래 "참고용" 줄과 같은 말이 두 번 나오지 않게
              Text(
                consulting.basis.isNotEmpty
                    ? '${consulting.basis} · 참고용'
                    : '미리 써 둔 예시 답변이에요 · 참고용',
                style: text.bodySmall,
              ), // C-4 P08 · P01 근거 · 한계 한 줄
            ],
            Row(
              children: [
                Expanded(
                  child: expanded
                      ? const SizedBox.shrink()
                      : Text(
                          '미리 써 둔 예시 답변이에요 · 참고용',
                          style: text.labelSmall?.copyWith(color: muleSubtle),
                        ), // C-4 P01 근거 · 한계를 알림
                ),
                TextButton(
                  onPressed: onToggle,
                  child: Text(expanded ? '접기' : '자세히 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// C-4 ③ 비교표 한 줄 — 제목 · 가격(굵게) · 시세 · 상태 · 메모. 누르면 B 게시글 상세로 쌓기
class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.row, required this.onTap});

  final ConsultingRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final grey = text.bodySmall?.copyWith(color: muleSubtle);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.title,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatWon(row.price),
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('시세 ${row.market} · 상태 ${row.condition}', style: grey),
                    if (row.note.isNotEmpty) Text(row.note, style: grey),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: muleSubtle),
            ],
          ),
        ),
      ),
    ); // C-4 P06 비교표 — 보고 고르기
  }
}

/// C-4 AI 조언 카드 — 컨설팅이 없는 응답일 때만: 첫 문장(핵심)만 굵게, 접혀 있으면 2줄까지
class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.advice,
    required this.expanded,
    required this.onToggle,
  });

  final String advice;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // 표시 형식만: 첫 문장 끝(". ")에서 나눠 앞부분을 굵게 — 문장을 해석하지 않는다
    final cut = advice.indexOf('. ');
    final head = cut < 0 ? advice : advice.substring(0, cut + 1);
    final rest = cut < 0 ? '' : advice.substring(cut + 1);
    return Card(
      color: mulePurple.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text('AI 조언', style: text.labelLarge),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: head,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: rest),
                ],
              ),
              style: text.bodyMedium,
              maxLines: expanded ? null : 2,
              overflow: expanded ? null : TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '미리 써 둔 예시 답변이에요 · 참고용',
                    style: text.labelSmall?.copyWith(color: muleSubtle),
                  ), // C-4 P10 AI 답변의 한계를 알림
                ),
                TextButton(
                  onPressed: onToggle,
                  child: Text(expanded ? '접기' : '더 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// C-3 키워드 제거 버튼 · C-9 키워드 추가 버튼 — 확인하면 단어를 돌려주고, 저장하지 않는다
class _ConditionWordDialog extends StatefulWidget {
  const _ConditionWordDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_ConditionWordDialog> createState() => _ConditionWordDialogState();
}

class _ConditionWordDialogState extends State<_ConditionWordDialog> {
  final _word = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _word,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.of(context).pop(value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        // 비어 있으면 "추가"를 끈다 — 빈 조건이 생기지 않게
        ValueListenableBuilder(
          valueListenable: _word,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_word.text),
            child: const Text('추가'),
          ),
        ), // C-3 P05 · C-9 P05
      ],
    );
  }
}
