// 화면 C: AI 검색 확인 시트 (GET /aiResponses?id= — 미리 정한 응답)
//
// ── 디자인 가이드 대응표: 화면 C — AI 검색 확인 시트 (docs/디자인가이드.md 3장과 같게) ───────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준 | 원칙 | 편의성 포인트 |
// |---|---|---|---|---|---|
// | C-1 | Text | 내가 말한 문장 | 시트 맨 위 · 작게 · 회색 | P01 | 무엇을 물었는지 기억 안 해도 됨 |
// | C-2 | Wrap · InputChip | AI가 알아들은 조건 | 예: [일렉기타] [펜더] [60만 원 이하] [앰프 빼기 X] · 빼는 단어는 빨간 테두리 · 시트에서 가장 크게 | P05 · #1 #2 | 결과를 보기 전에 오해를 고침 |
// | C-3 | TextButton → showDialog | 빼는 단어 추가 | 조건 줄 끝 "+ 빼는 단어" | P05 · #2 요청 | "esp"→"lespaul" 같은 엉뚱한 결과를 미리 막음 |
// | C-4 | Card · Text | AI 조언 (예산 맞춤) | 조건 아래 · 2–3문장 · 예산 대비 핵심만 굵게 | P10 · #7 | 시세 · 상태를 혼자 따져 보지 않아도 됨 |
// | C-5 | ListView · ListTile | 추천 결과 목록 | 게시판 라벨 → 제목 → 가격 → 추천 이유 줄 | P06 · P01 | 왜 나왔는지 상세에 안 들어가도 앎 |
// | C-6 | FutureBuilder · LoadingView · ErrorView · EmptyView | AI 응답 상태 안내 | 찾는 중 → 오류 + 다시 시도 → 결과 없음(조건 하나 빼기 제안) | P09 | 결과 0건에서 막히지 않음 |
// | C-7 | FilledButton · OutlinedButton | 다시 찾기 · 알림 받기 | 시트 맨 아래 한 줄 | P03 · P04 | 처음부터 다시 말하지 않아도 됨 · 검색과 알림 조건을 두 번 설정 안 함 |
// ────────────────────────────────────────────────────────────────────────────────────────
// 전환: A → C 덮기(showModalBottomSheet, A-2 보내기) · C → B 쌓기(Navigator.push, C-5 추천 결과) — B에서 뒤로 가면 시트로.
// 적응형: 넓은 화면에서 시트 최대 너비 720dp로 가운데 정렬.
// 상태관리 포인트(가이드 5장): S1 입력 문장 · S3 서버 응답 상태 · S4 AI가 알아들은 조건 목록 · S5 AI 조언 펼침 / 접힘 → `grep -rn "STATE:" lib`
//
// ⚠ 실제 문장 해석·추천 계산 없음 (안내 5장: "실제 비즈니스 로직"은 감점).
//   어떤 문장이든 미리 쓴 응답(id=1, 예시 조건 칩 2번만 id=2)을 그대로 보여 준다.
//   조건을 빼거나 빼는 단어를 더해도 화면 표시만 바뀌고, 다시 찾기는 같은 응답을 다시 GET한다.
//   AI 조언(C-4)도 db.json aiResponses.advice에 미리 쓴 문장 그대로다. 알림 받기(C-7)는 SnackBar만 띄운다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';

/// 넓은 화면에서 시트 최대 너비 (가이드 1장 적응형)
const sheetMaxWidth = 720.0;

/// C-2 AI가 알아들은 조건의 표시 순서 (가이드 4장) — 모르는 type은 맨 뒤
const _conditionTypes = ['category', 'brand', 'price', 'region', 'exclude'];

int _conditionOrder(String type) {
  final i = _conditionTypes.indexOf(type);
  return i < 0 ? _conditionTypes.length : i;
}

class AiSearchConfirmSheet extends StatefulWidget {
  const AiSearchConfirmSheet({
    super.key,
    required this.query,
    this.responseId = 1,
    this.loadAiResponse = fetchAiResponse,
    this.loadPost = fetchPost,
    this.loadPriceInfo = fetchPriceInfo,
    this.loadConditionCheck = fetchConditionCheck,
    this.loadUsageReviews = fetchUsageReviews,
  });

  /// A-2에서 보낸 문장 — C-1에 그대로 보여 준다 (해석하지 않는다)
  final String query;

  /// 미리 쓴 응답 번호 — 1: 결과 있음 · 2: 결과 없음(예시 조건 칩 2번)
  final int responseId;

  /// 데이터를 가져오는 함수 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final AiResponseLoader loadAiResponse;
  final PostLoader loadPost;
  final PriceInfoLoader loadPriceInfo;
  final ConditionCheckLoader loadConditionCheck;
  final UsageReviewsLoader loadUsageReviews;

  /// 덮기(modal): 통합 홈 위에 시트를 띄운다.
  static Future<void> show(
    BuildContext context, {
    required String query,
    int responseId = 1,
    AiResponseLoader loadAiResponse = fetchAiResponse,
    PostLoader loadPost = fetchPost,
    PriceInfoLoader loadPriceInfo = fetchPriceInfo,
    ConditionCheckLoader loadConditionCheck = fetchConditionCheck,
    UsageReviewsLoader loadUsageReviews = fetchUsageReviews,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: sheetMaxWidth),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: AiSearchConfirmSheet(
          query: query,
          responseId: responseId,
          loadAiResponse: loadAiResponse,
          loadPost: loadPost,
          loadPriceInfo: loadPriceInfo,
          loadConditionCheck: loadConditionCheck,
          loadUsageReviews: loadUsageReviews,
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

  /// C-2 AI가 알아들은 조건 — 첫 응답에서 한 번만 채우고, 이후로는 화면에서 고친 그대로 둔다
  List<AiCondition>? _conditions;

  /// C-4 AI 조언 펼침 여부
  var _adviceExpanded = false;

  Future<AiResponse?> _load() async {
    final response = await widget.loadAiResponse(widget.responseId);
    _conditions ??= [...?response?.conditions];
    return response;
  }

  /// C-6 다시 시도 · C-7 다시 찾기 — 같은 응답을 다시 GET (계산하지 않는다)
  void _retry() {
    // STATE: S3 서버 응답 상태 → C-6
    setState(() {
      _future = _load();
    });
  }

  void _removeCondition(AiCondition condition) {
    // STATE: S4 AI가 알아들은 조건 목록 → C-2
    setState(() {
      _conditions?.remove(condition);
    });
  }

  Future<void> _addExcludedWord() async {
    final word = await showDialog<String>(
      context: context,
      builder: (_) => const _ExcludedWordDialog(),
    ); // C-3 P05
    if (!mounted || word == null || word.trim().isEmpty) return;
    // STATE: S4 AI가 알아들은 조건 목록 → C-2 (저장하지 않는다)
    setState(() {
      _conditions = [
        ...?_conditions,
        AiCondition(type: 'exclude', label: word.trim()),
      ];
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

  void _showSnack(String message) {
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// C-5 추천 결과 → B 게시글 상세 (쌓기 — 뒤로 가면 이 시트로 돌아온다)
  Future<void> _openResult(AiResult result) async {
    final Post? post;
    try {
      post = await widget.loadPost(result.postId);
    } on Exception catch (e) {
      _showSnack('게시글을 열지 못했습니다. $e');
      return;
    }
    if (!mounted) return;
    if (post == null) {
      _showSnack('게시글을 찾지 못했습니다.');
      return;
    }
    final found = post; // 클로저 안에서도 Post(널 아님)로 쓰기 위해
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(
          post: found,
          reasons: result.reasons, // → B-3 내 조건과 맞는 이유
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
    final colors = Theme.of(context).colorScheme;
    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FutureBuilder<AiResponse?>(
          future: _future,
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              // STATE: S1 입력 문장 → A-2 · C-1
              Text(
                '“${widget.query}”',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
    // 가이드 순서(카테고리 → 브랜드 → 가격 → 지역 → 빼는 단어)로 보여 주기만 한다 — 표시 순서 정렬, 계산 아님
    final conditions = [...?_conditions]
      ..sort(
        (a, b) => _conditionOrder(a.type).compareTo(_conditionOrder(b.type)),
      );
    final advice = snap.data?.advice ?? '';
    final results = snap.data?.results ?? const <AiResult>[];
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final c in conditions)
            InputChip(
              label: Text(
                c.type == 'exclude' ? '${c.label} 빼기' : c.label,
                style: text.titleMedium,
              ),
              avatar: c.type == 'exclude'
                  ? Icon(Icons.block, size: 18, color: colors.error)
                  : null,
              side: c.type == 'exclude'
                  ? BorderSide(color: colors.error, width: 1.5)
                  : null,
              deleteButtonTooltipMessage: '조건 빼기',
              onDeleted: () => _removeCondition(c),
            ), // C-2 P05
          TextButton(
            onPressed: _addExcludedWord,
            child: const Text('+ 빼는 단어'),
          ), // C-3 P05
        ],
      ),
      const SizedBox(height: 12),
      if (advice.isNotEmpty)
        _AdviceCard(
          advice: advice,
          expanded: _adviceExpanded,
          onToggle: _toggleAdvice,
        ), // C-4 P10
      const Divider(height: 24),
      if (results.isEmpty)
        const EmptyView(message: '조건에 맞는 글이 없습니다.\n조건을 하나 빼 보세요.') // C-6 P09
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final r = results[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(r.reasons.join(' · ')), // C-5 P01 추천 이유 줄
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openResult(r),
            );
          },
        ), // C-5 P06
    ];
  }
}

/// C-4 AI 조언 (예산 맞춤) — 첫 문장(핵심)만 굵게, 접혀 있으면 2줄까지
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
      margin: EdgeInsets.zero,
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onToggle,
                child: Text(expanded ? '접기' : '더 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// C-3 빼는 단어 추가 — 확인하면 단어를 돌려주고, 저장하지 않는다
class _ExcludedWordDialog extends StatefulWidget {
  const _ExcludedWordDialog();

  @override
  State<_ExcludedWordDialog> createState() => _ExcludedWordDialogState();
}

class _ExcludedWordDialogState extends State<_ExcludedWordDialog> {
  final _word = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('빼는 단어 추가'),
      content: TextField(
        controller: _word,
        autofocus: true,
        decoration: const InputDecoration(hintText: '예: 앰프, lespaul'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_word.text),
          child: const Text('추가'),
        ),
      ],
    );
  }
}
