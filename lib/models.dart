// 데이터 모양 — db.json의 한 항목을 화면이 쓰기 좋은 객체로 바꾼다.
// 형식이 틀린 항목은 null을 돌려준다 → 목록에서 빠질 뿐 앱이 멈추지 않는다 (Dart 3 패턴 매칭).
// 필드 이름은 mock_server/db.json의 키와 같다 (posts · notices · alerts · aiResponses · priceInfo · usageReviews · conditionChecks).

/// 게시판 — D-2 게시판 탭 · A-9 게시판 바로가기 라벨과 GET /posts?board= 값 · B-1 제목에도 쓴다
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

/// 문자열 필드: 없거나 모양이 다르면 빈 문자열
String _string(Object? json) => json is String ? json : '';

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

/// 알림 조건에 걸린 새 글 미리보기 — 누르면 postId로 B 게시글 상세를 연다
class AlertMatch {
  const AlertMatch({
    required this.postId,
    required this.board,
    required this.title,
    required this.price,
    required this.image,
    this.category = '',
  });

  final int postId;

  /// 화면에 그대로 쓰는 한글 라벨(예: "장터")
  final String board;
  final String title;
  final int price;
  final String image;

  /// 카테고리(예: "일렉기타") — 자리표시 그림을 고를 때만 쓴다
  final String category;

  static AlertMatch? fromJson(Object? json) {
    return switch (json) {
      {
        'postId': int postId,
        'board': String board,
        'title': String title,
        'price': int price,
        'image': String image,
      } =>
        AlertMatch(
          postId: postId,
          board: board,
          title: title,
          price: price,
          image: image,
          category: _string(json['category']),
        ),
      _ => null,
    };
  }
}

/// 알림 조건 — GET /alerts (미리 걸어 둔 조건과 새 글. 실제 알림 등록 · 매칭 계산은 없다)
class SearchAlert {
  const SearchAlert({
    required this.id,
    required this.name,
    required this.query,
    this.responseId = 1,
    this.labels = const [],
    this.newCount = 0,
    this.matches = const [],
  });

  final int id;

  /// 짧은 이름 — A-8 조건 칩에 쓴다 (예: "펜더 일렉")
  final String name;

  /// 알림을 걸 때 쓴 문장 — 누르면 이 문장으로 C 시트를 연다
  final String query;

  /// C 시트에서 보여 줄 미리 쓴 응답 번호 (aiResponses.id)
  final int responseId;
  final List<String> labels;

  /// 새 글 수 — 미리 정한 값 (세지 않는다)
  final int newCount;
  final List<AlertMatch> matches;

  static SearchAlert? fromJson(Object? json) {
    return switch (json) {
      {'id': int id, 'name': String name, 'query': String query} => SearchAlert(
        id: id,
        name: name,
        query: query,
        responseId: switch (json['responseId']) {
          int r => r,
          _ => 1,
        },
        labels: _strings(json['labels']),
        newCount: switch (json['newCount']) {
          int n => n,
          _ => 0,
        },
        matches: _objects(json['matches'], AlertMatch.fromJson),
      ),
      _ => null,
    };
  }
}

/// AI가 이해한 조건 하나 — type: category · brand · price · region · include · exclude
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
    this.consulting,
  });

  final int id;
  final String query;

  /// C-4 AI 조언 카드 — 미리 쓴 2–3문장
  final String advice;
  final List<AiCondition> conditions;
  final List<AiResult> results;

  /// C-4 AI 조언 카드 컨설팅 — 없으면 null (그때는 advice 문장만)
  final AiConsulting? consulting;

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
        consulting: AiConsulting.fromJson(json['consulting']),
      ),
      _ => null,
    };
  }
}

/// C-4 1순위 추천 — 제목 · 한 줄 요약 · 이유 3개 (모두 미리 쓴 문장)
class ConsultingPick {
  const ConsultingPick({
    required this.postId,
    required this.title,
    required this.headline,
    this.reasons = const [],
  });

  final int postId;
  final String title;
  final String headline;
  final List<String> reasons;

  static ConsultingPick? fromJson(Object? json) {
    return switch (json) {
      {
        'postId': int postId,
        'title': String title,
        'headline': String headline,
      } =>
        ConsultingPick(
          postId: postId,
          title: title,
          headline: headline,
          reasons: _strings(json['reasons']),
        ),
      _ => null,
    };
  }
}

/// C-4 비교표 한 줄 — market · condition · note도 미리 쓴 문자열 (앱에서 비교 · 정렬하지 않는다)
class ConsultingRow {
  const ConsultingRow({
    required this.postId,
    required this.title,
    required this.price,
    this.market = '',
    this.condition = '',
    this.note = '',
  });

  final int postId;
  final String title;
  final int price;
  final String market;
  final String condition;
  final String note;

  static ConsultingRow? fromJson(Object? json) {
    return switch (json) {
      {'postId': int postId, 'title': String title, 'price': int price} =>
        ConsultingRow(
          postId: postId,
          title: title,
          price: price,
          market: _string(json['market']),
          condition: _string(json['condition']),
          note: _string(json['note']),
        ),
      _ => null,
    };
  }
}

/// C-4 AI 조언 카드 컨설팅 — aiResponses[*].consulting 그대로 (목적 → 1순위 → 비교 → 확인할 것 → 예산 바꾸면 → 근거)
class AiConsulting {
  const AiConsulting({
    this.goal = const [],
    this.pick,
    this.compare = const [],
    this.checklist = const [],
    this.budgetTips = const [],
    this.basis = '',
  });

  final List<String> goal;

  /// 1순위 — 결과 없음 응답(id=2)이면 null
  final ConsultingPick? pick;
  final List<ConsultingRow> compare;
  final List<String> checklist;
  final List<String> budgetTips;
  final String basis;

  static AiConsulting? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    return AiConsulting(
      goal: _strings(json['goal']),
      pick: ConsultingPick.fromJson(json['pick']),
      compare: _objects(json['compare'], ConsultingRow.fromJson),
      checklist: _strings(json['checklist']),
      budgetTips: _strings(json['budgetTips']),
      basis: _string(json['basis']),
    );
  }
}

/// 시세 — GET /priceInfo?postId= (미리 정한 값, 앱에서 계산하지 않는다)
class PriceInfo {
  const PriceInfo({
    required this.postId,
    required this.low,
    required this.avg,
    required this.high,
    this.label = '',
  });

  final int postId;
  final int low;
  final int avg;
  final int high;

  /// B-5 한 줄 판단 — 미리 쓴 문장 (예: "시세 평균보다 2만 원 싸요")
  final String label;

  static PriceInfo? fromJson(Object? json) {
    return switch (json) {
      {
        'postId': int postId,
        'low': int low,
        'avg': int avg,
        'high': int high,
      } =>
        PriceInfo(
          postId: postId,
          low: low,
          avg: avg,
          high: high,
          label: _string(json['label']),
        ),
      _ => null,
    };
  }
}

/// 후기 (db.json usageReviews) — GET /usageReviews?postId=
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

/// 0–1 비율 필드 — 숫자가 아니거나 범위 밖이면 null
double? _ratio(Object? json) => switch (json) {
  num n when n >= 0 && n <= 1 => n.toDouble(),
  _ => null,
};

/// AI 상태 체크 항목 하나 — 사진 위 번호(no) · 부위 · 상태(좋음 · 보통 · 확인 필요) · 설명
class ConditionCheckItem {
  const ConditionCheckItem({
    required this.no,
    required this.part,
    required this.level,
    required this.note,
    this.x,
    this.y,
  });

  final int no;
  final String part;
  final String level;
  final String note;

  /// 사진 위 번호 위치(0–1 비율, db.json에 미리 씀) — 없으면 사진 왼쪽 위에 모은다
  final double? x;
  final double? y;

  static ConditionCheckItem? fromJson(Object? json) {
    return switch (json) {
      {
        'no': int no,
        'part': String part,
        'level': String level,
        'note': String note,
      } =>
        ConditionCheckItem(
          no: no,
          part: part,
          level: level,
          note: note,
          x: _ratio(json['x']),
          y: _ratio(json['y']),
        ),
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
