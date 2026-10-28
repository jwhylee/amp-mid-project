// 공용 화면 조각 — GET을 쓰는 화면은 모두 이 세 상태를 그린다 (AGENTS.md MUST).
//   LoadingView  불러오는 중   P01 시스템 상태의 가시성 (예)
//   ErrorView    오류 + 다시 시도   P09 오류 인식·진단·복구 (예)
//   EmptyView    빈 목록 안내   P01 (예)
// TODO: 문구는 디자인 가이드 글의 명칭 그대로 바꾼다.
import 'package:flutter/material.dart';

import 'theme.dart';

/// 로딩 상태
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = '불러오는 중…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}

/// 오류 상태: 무엇이 잘못됐는지 + 다시 시도 버튼
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = '정보를 불러오지 못했습니다.',
    this.message = '',
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 빈 상태: 목록이 비었을 때 안내
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message = '표시할 항목이 없습니다.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// 네트워크 이미지 — 실패해도 화면은 그대로 보이게
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width, this.height});

  final String url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.image_outlined, size: 40),
      ),
    );
  }
}

/// 가격 표시 — 580000 → "580,000원", 0 → "가격 없음" (표시 형식만 바꾼다. 계산 아님)
String formatWon(int price) {
  if (price <= 0) return '가격 없음';
  final digits = '$price';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '$buf원';
}

/// 그라데이션 헤더 — 하단 메뉴 네 화면 맨 위에 같은 모양으로 (P04 일관성)
/// 아래쪽 모서리를 둥글게 깎고, 상태 표시줄 아래부터 내용을 그린다.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  /// 헤더 안 아래쪽에 넣을 위젯 (예: A-2 AI 조건 입력창)
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: muleGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: text.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
              if (bottom case final bottom?) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: bottom,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 헤더 위 둥근 네모 아이콘 버튼 (반투명 흰 바탕)
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.dot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// true면 주황 점 — 새 소식이 있다는 표시만 (숫자를 세지 않는다)
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Badge(
          isLabelVisible: dot,
          backgroundColor: muleOrange,
          child: Icon(icon),
        ),
      ),
    );
  }
}

/// 구역 제목 줄 — "내 알림 조건 ··· 전체 보기"
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (action case final action?)
            TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

/// 둥근 사진 — 카드 · 목록에서 같은 모서리로
class RoundedImage extends StatelessWidget {
  const RoundedImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.radius = 12,
  });

  final String url;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: mulePurple.withValues(alpha: 0.08),
        child: NetImage(url, width: width, height: height),
      ),
    );
  }
}

/// "새 2" 주황 배지 — 새 글 수는 db.json에 미리 정한 값 (세지 않는다)
/// 화면낭독기는 "새 글 2개"로 읽는다.
class NewBadge extends StatelessWidget {
  const NewBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '새 글 $count개',
      excludeSemantics: true,
      child: _box(),
    );
  }

  Widget _box() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: muleOrange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '새 $count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 날짜 표시 — "2026-10-22" → "10월 22일" (글자만 바꾼다. 날짜 계산 아님)
String formatDate(String ymd) {
  final parts = ymd.split('-');
  if (parts.length != 3) return ymd;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null) return ymd;
  return '$month월 $day일';
}

/// 글자 크기 설정에 맞춘 높이 — 고정 높이 카드가 큰 글자에서 넘치지 않게
/// [fixed]는 사진처럼 글자와 상관없는 부분, [text]는 글자가 차지하는 부분
double scaledHeight(BuildContext context, double fixed, double text) =>
    fixed + MediaQuery.textScalerOf(context).scale(text);

/// 쌓기 화면(B)의 위쪽 바 — 그라데이션 바탕 · 흰 글자 · 왼쪽 위 뒤로가기 (B-1)
AppBar gradientAppBar({required Widget title}) => AppBar(
  leading: const BackButton(),
  title: title,
  foregroundColor: Colors.white,
  backgroundColor: Colors.transparent,
  flexibleSpace: const DecoratedBox(
    decoration: BoxDecoration(gradient: muleGradient),
  ),
);

/// 당겨서 새로고침용 — 실패해도 RefreshIndicator가 멈추지 않게 오류는 여기서 삼키고,
/// 오류 표시는 FutureBuilder(ErrorView)가 맡는다.
Future<void> settle(Future<Object?> future) async {
  try {
    await future;
  } on Object {
    // 화면의 ErrorView가 보여 준다
  }
}

/// 알약 버튼 — A-3 예시 조건 · A-8 알림 조건. 고르면 보라 바탕.
/// (Chip 계열은 웹(CanvasKit)에서 한글 글꼴이 늦게 불러와질 때 글자 폭을 짧게 재서 가로 줄 안에서 글자가 잘린다
///  → 글자 크기대로 자라는 상자로 그린다)
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : muleInk;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? mulePurple : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? mulePurple : muleLine),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(icon == null ? 16 : 12, 9, 16, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final icon?) ...[
                  Icon(icon, size: 16, color: selected ? fg : mulePurple),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
