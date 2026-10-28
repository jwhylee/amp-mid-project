// 화면 E: 알림 (GET /alerts) — 하단 메뉴 '알림'
//
// ── 디자인 가이드 대응표: 화면 E — 알림 (docs/디자인가이드.md 3장과 같게) ────────────
// | 번호 | Flutter 위젯명 | 비즈니스 명칭(한글) | 정보 전달 기준 | 원칙 | 편의성 포인트 |
// |---|---|---|---|---|---|
// | E-1 | GradientHeader | 알림 머리 | 화면 이름 + 한 줄 설명 | P04 · 모든 메뉴 같은 자리 | 지금 어느 메뉴인지 바로 앎 |
// | E-2 | Card · Switch · ListTile | 알림 조건 카드 | 조건 이름(새 글 수는 숫자만 주황 배지) → 문장 → 조건 칩 → 새 글 목록(사진) → AI 검색으로 보기 · 끄고 켠 뒤 "되돌리기" | P01 · P03 · P04 · P08 · P02 | 알림을 끄고 켜기를 한 자리에서 · 검색과 같은 조건으로 새 글을 바로 열기 |
// | E-3 | FutureBuilder · LoadingView · ErrorView · EmptyView · RefreshIndicator | 알림 상태 안내 | 로딩 → 오류 + 다시 시도 → 빈 목록 안내 · 아래로 당겨 새로고침 | P09 | 오류 때 앱을 껐다 켜지 않아도 됨 |
// ────────────────────────────────────────────────────────────────────────────────────────
// 전환: E → C 덮기(AI 검색으로 보기) · E → B 쌓기(새 글 줄).
// 적응형: 넓은 창에서 본문 최대 720dp로 가운데.
// 상태관리 포인트: S3 서버 응답 상태 · S9 알림 켜짐 / 꺼짐 → `grep -rn "STATE:" lib`
//
// ⚠ 알림 켜기 · 끄기는 화면 표시만 바꾼다 (저장 · 실제 알림 등록 없음 → SnackBar로 안내).
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';
import 'c_result_sheet.dart';

/// 알림 본문 최대 너비
const alertsMaxWidth = 720.0;

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.loaders = const AppLoaders()});

  final AppLoaders loaders;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<SearchAlert>> _alerts = widget.loaders.alerts();

  /// 이 화면에서 끈 알림 조건 id — 앱을 다시 켜면 처음대로 (저장하지 않는다)
  final _muted = <int>{};

  /// E-3 다시 시도 · 당겨서 새로고침
  Future<void> _retry() {
    // STATE: S3 서버 응답 상태 → E-3
    setState(() {
      _alerts = widget.loaders.alerts();
    });
    return settle(_alerts);
  }

  /// E-2 켜기 · 끄기 — SnackBar의 "되돌리기"로 바로 원래대로
  void _toggle(SearchAlert alert, bool on, {bool undo = false}) {
    // STATE: S9 알림 켜짐 / 꺼짐 → E-2 (저장하지 않는다)
    setState(() {
      if (on) {
        _muted.remove(alert.id);
      } else {
        _muted.add(alert.id);
      }
    });
    if (undo) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            on
                ? '"${alert.name}" 알림을 켰어요 (데모: 저장하지 않습니다)'
                : '"${alert.name}" 알림을 껐어요 (데모: 저장하지 않습니다)',
          ),
          action: SnackBarAction(
            label: '되돌리기',
            onPressed: () => _toggle(alert, !on, undo: true),
          ), // E-2 P03 되돌리기
          // action이 있어도 4초 뒤 사라지게 (C-2와 같은 규칙)
          persist: false,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GradientHeader(
          title: '알림',
          subtitle: '알림을 걸어 둔 조건과 새 글',
        ), // E-1 P04
        Expanded(
          child: FutureBuilder<List<SearchAlert>>(
            future: _alerts,
            builder: (context, snap) {
              // 당겨서 새로고침 중에는 이전 목록을 그대로 둔다
              if (snap.connectionState != ConnectionState.done &&
                  !snap.hasData) {
                return const LoadingView(label: '알림 조건을 불러오는 중…'); // E-3 P09
              }
              if (snap.hasError) {
                return ErrorView(
                  title: '알림 조건을 불러오지 못했습니다.',
                  message: '${snap.error}',
                  onRetry: _retry,
                ); // E-3 P09
              }
              final alerts = snap.data ?? const <SearchAlert>[];
              if (alerts.isEmpty) {
                return const EmptyView(
                  message:
                      '아직 알림을 건 조건이 없어요.\n홈에서 찾는 조건을 말하고 "이 조건으로 알림"을 눌러 보세요.',
                ); // E-3 P09
              }
              return RefreshIndicator(
                onRefresh: _retry,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: alertsMaxWidth),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: alerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final alert = alerts[i];
                        return _AlertCard(
                          alert: alert,
                          on: !_muted.contains(alert.id),
                          onToggle: (on) => _toggle(alert, on),
                          onSearch: () => AiSearchConfirmSheet.show(
                            context,
                            query: alert.query,
                            responseId: alert.responseId,
                            loaders: widget.loaders,
                          ),
                          onOpenMatch: (m) =>
                              openPostById(context, widget.loaders, m.postId),
                        );
                      },
                    ),
                  ),
                ),
              ); // E-3 P09 당겨서 다시 불러오기
            },
          ),
        ),
      ],
    );
  }
}

/// E-2 알림 조건 카드
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.on,
    required this.onToggle,
    required this.onSearch,
    required this.onOpenMatch,
  });

  final SearchAlert alert;
  final bool on;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSearch;
  final ValueChanged<AlertMatch> onOpenMatch;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final grey = text.bodySmall?.copyWith(color: muleSubtle);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          alert.name,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (on && alert.newCount > 0) ...[
                        const SizedBox(width: 8),
                        NewBadge(count: alert.newCount), // E-2 P08 숫자만
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: on,
                  onChanged: onToggle,
                ), // E-2 P03 켜고 끄기 (되돌릴 수 있음)
              ],
            ),
            Text('“${alert.query}”', style: grey), // E-2 P01
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final label in alert.labels)
                  Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            if (!on)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('알림이 꺼져 있어요. 켜면 새 글이 여기에 보여요.', style: grey),
              )
            else if (alert.matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('아직 새 글이 없어요.', style: grey),
              )
            else
              for (final m in alert.matches)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: PostImage(
                    m.image,
                    category: m.category,
                    width: 52,
                    height: 52,
                  ), // E-2 P02
                  title: Text(
                    m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${m.board} · ${formatWon(m.price)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenMatch(m),
                ), // E-2 P01 새 글
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onSearch,
                icon: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: mulePurple,
                ),
                label: const Text('AI 검색으로 보기'),
              ),
            ), // E-2 P04 검색과 같은 조건
          ],
        ),
      ),
    );
  }
}
