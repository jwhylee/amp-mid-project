// 데이터 모양 — db.json의 한 항목을 화면이 쓰기 좋은 객체로 바꾼다.
// 형식이 틀린 항목은 null을 돌려준다 → 목록에서 빠질 뿐 앱이 멈추지 않는다 (Dart 3 패턴 매칭).
// 필드 이름은 mock_server/db.json의 키와 같다 (posts · notices · aiResponses · priceInfo · usageReviews · conditionChecks).

/// 게시판 — A-4 게시판 탭 라벨과 GET /posts?board= 값 (순서는 가이드 그대로) · B-1 제목에도 쓴다
const boardTabs = [
  (label: '장터', board: 'market'),
  (label: '합주실', board: 'studio'),
  (label: '레슨', board: 'lesson'),
  (label: '구인', board: 'recruit'),
  (label: '공연', board: 'show'),
];

/// board 값 → 화면 라벨 (예: market → 장터). 모르는 값이면 그대로
String boardLabel(String board) =>
    boardTabs.where((b) => b.board == board).firstOrNull?.label ?? board;

/// 문자열 배열 필드: 모양이 다르면 빈 목록
List<String> _strings(Object? json) => switch (json) {
  List<Object?> l => l.whereType<String>().toList(),
  _ => const [],
};

/// 객체 배열 필드: 항목마다 fromJson을 적용하고 형식이 틀린 항목은 뺀다
List<T> _objects<T extends Object>(
  Object? json,
  T? Function(Object?) fromJson,
) {
  if (json is! List<Object?>) return const [];
  return json.map(fromJson).nonNulls.toList();
}

/// 게시글 — GET /posts?board=
class Post {
  const Post({
    required this.id,
    required this.board,
    required this.category,
    required this.brand,
    required this.model,
    required this.title,
    required this.price,
    required this.region,
    required this.body,
    required this.image,
    required this.createdAt,
    this.specs = const [],
  });

  final int id;

  /// market · studio · lesson · recruit · show
  final String board;
  final String category;
  final String brand;

  /// 기초 설계 제안 필드(가이드 1-1) — 비어 있을 수 있다
  final String model;
  final String title;
  final int price;
  final String region;
  final String body;
  final String image;
  final String createdAt;

  /// 사양 [이름, 값] 쌍 — 예: ("바디", "앨더")
  final List<(String, String)> specs;

  static Post? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'board': String board,
        'category': String category,
        'brand': String brand,
        'model': String model,
        'title': String title,
        'price': int price,
        'region': String region,
        'body': String body,
        'image': String image,
        'createdAt': String createdAt,
      } =>
        Post(
          id: id,
          board: board,
          category: category,
          brand: brand,
          model: model,
          title: title,
          price: price,
          region: region,
          body: body,
          image: image,
          createdAt: createdAt,
          specs: switch (json['specs']) {
            List<Object?> l => [
              for (final s in l)
                if (s case [String name, String value]) (name, value),
            ],
            _ => const [],
          },
        ),
      _ => null,
    };
  }
}

/// 공지 — GET /notices
class Notice {
  const Notice({required this.id, required this.text});

  final int id;
  final String text;

  static Notice? fromJson(Object? json) {
    return switch (json) {
      {'id': int id, 'text': String text} => Notice(id: id, text: text),
      _ => null,
    };
  }
}

/// AI가 이해한 조건 하나 — type: category · brand · price · region · exclude
class AiCondition {
  const AiCondition({required this.type, required this.label});

  final String type;
  final String label;

  static AiCondition? fromJson(Object? json) {
    return switch (json) {
      {'type': String type, 'label': String label} => AiCondition(
        type: type,
        label: label,
      ),
      _ => null,
    };
  }
}

/// 추천 결과 하나 — board는 화면에 그대로 쓰는 한글 라벨(예: "장터")
class AiResult {
  const AiResult({
    required this.postId,
    required this.board,
    required this.title,
    required this.price,
    this.reasons = const [],
  });

  final int postId;
  final String board;
  final String title;
  final int price;
  final List<String> reasons;

  static AiResult? fromJson(Object? json) {
    return switch (json) {
      {
        'postId': int postId,
        'board': String board,
        'title': String title,
        'price': int price,
      } =>
        AiResult(
          postId: postId,
          board: board,
          title: title,
          price: price,
          reasons: _strings(json['reasons']),
        ),
      _ => null,
    };
  }
}

/// 미리 쓴 가짜 AI 응답 — GET /aiResponses?id= (문장을 해석하지 않는다)
class AiResponse {
  const AiResponse({
    required this.id,
    required this.query,
    this.advice = '',
    this.conditions = const [],
    this.results = const [],
  });

  final int id;
  final String query;

  /// C-4 AI 조언 (예산 맞춤) — 미리 쓴 2–3문장
  final String advice;
  final List<AiCondition> conditions;
  final List<AiResult> results;

  static AiResponse? fromJson(Object? json) {
    return switch (json) {
      {'id': int id, 'query': String query} => AiResponse(
        id: id,
        query: query,
        advice: switch (json['advice']) {
          String a => a,
          _ => '',
        },
        conditions: _objects(json['conditions'], AiCondition.fromJson),
        results: _objects(json['results'], AiResult.fromJson),
      ),
      _ => null,
    };
  }
}

/// 시세 — GET /priceInfo?postId= (미리 정한 값, 앱에서 계산하지 않는다)
class PriceInfo {
  const PriceInfo({
    required this.postId,
    required this.low,
    required this.avg,
    required this.high,
  });

  final int postId;
  final int low;
  final int avg;
  final int high;

  static PriceInfo? fromJson(Object? json) {
    return switch (json) {
      {
        'postId': int postId,
        'low': int low,
        'avg': int avg,
        'high': int high,
      } =>
        PriceInfo(postId: postId, low: low, avg: avg, high: high),
      _ => null,
    };
  }
}

/// 사용 후기 — GET /usageReviews?postId=
class UsageReview {
  const UsageReview({
    required this.id,
    required this.postId,
    required this.rating,
    required this.text,
  });

  final int id;
  final int postId;
  final int rating;
  final String text;

  static UsageReview? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'postId': int postId,
        'rating': int rating,
        'text': String text,
      } =>
        UsageReview(id: id, postId: postId, rating: rating, text: text),
      _ => null,
    };
  }
}

/// AI 상태 체크 항목 하나 — 사진 위 번호(no) · 부위 · 상태(좋음 · 보통 · 확인 필요) · 설명
class ConditionCheckItem {
  const ConditionCheckItem({
    required this.no,
    required this.part,
    required this.level,
    required this.note,
  });

  final int no;
  final String part;
  final String level;
  final String note;

  static ConditionCheckItem? fromJson(Object? json) {
    return switch (json) {
      {
        'no': int no,
        'part': String part,
        'level': String level,
        'note': String note,
      } =>
        ConditionCheckItem(no: no, part: part, level: level, note: note),
      _ => null,
    };
  }
}

/// AI 상태 체크 — GET /conditionChecks?postId= (미리 쓴 결과, 사진을 분석하지 않는다)
class ConditionCheck {
  const ConditionCheck({
    required this.id,
    required this.postId,
    required this.image,
    this.items = const [],
  });

  final int id;
  final int postId;
  final String image;
  final List<ConditionCheckItem> items;

  static ConditionCheck? fromJson(Object? json) {
    return switch (json) {
      {'id': int id, 'postId': int postId, 'image': String image} =>
        ConditionCheck(
          id: id,
          postId: postId,
          image: image,
          items: _objects(json['items'], ConditionCheckItem.fromJson),
        ),
      _ => null,
    };
  }
}
