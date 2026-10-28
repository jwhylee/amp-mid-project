// 데이터 가져오기 — GET만 쓴다 (중간고사 안내 5장: POST/PUT/DELETE·저장은 감점)
// 화면 코드는 이 파일의 fetch…() 함수만 부른다. (관심사 분리)
// 모든 경로는 json-server의 배열 응답이다. 하나만 필요한 것도 쿼리(?id=1)로 받아 첫 항목을 쓴다.
//
// 서버 주소 (코드 수정 없이 실행할 때 바꾼다):
//   기본값  Android 에뮬레이터 → http://10.0.2.2:3000   그 외(Chrome·macOS·iOS 시뮬레이터) → http://localhost:3000
//   실기기  flutter run --dart-define=API_BASE=http://192.168.0.10:3000   (같은 Wi-Fi의 PC IP)
//   배포    flutter build web --dart-define=API_BASE=https://<프로젝트>.vercel.app/api   (가산점)
//
// 발표·데모용 상태 스위치 (로딩·오류·빈 상태를 눈으로 보여 주기):
//   --dart-define=DEMO_STATE=loading → 3초 늦게 응답 (로딩 상태)
//   --dart-define=DEMO_STATE=error   → 항상 실패 (오류 상태 + 다시 시도)
//   --dart-define=DEMO_STATE=empty   → 빈 목록 (빈 상태)
//   앱을 다시 켜지 않고 바꾸려면: 하단 메뉴 '설정' → F-4 데모 상태 (영상 한 번에 3상태를 찍을 때)
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

const _apiBaseOverride = String.fromEnvironment('API_BASE');

/// json-server 주소. API_BASE를 넘기면 그 값, 아니면 실행 대상에 맞는 기본값.
String get apiBase {
  if (_apiBaseOverride.isNotEmpty) return _apiBaseOverride;
  // Android 에뮬레이터 안의 localhost는 에뮬레이터 자신 → PC는 10.0.2.2
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

/// loading(=slow) · error · empty — 그 외 값이면 평소처럼 서버에서 가져온다.
/// 처음 값은 --dart-define, 실행 중에는 F-4 데모 상태가 바꾼다 (메모리에만 — 저장하지 않는다)
var demoState = const String.fromEnvironment('DEMO_STATE');

/// 화면에 그대로 보여 줄 수 있는 오류 문장
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// GET {apiBase}/{path} → JSON 배열
Future<List<Object?>> _getList(String path) async {
  switch (demoState) {
    case 'loading' || 'slow':
      await Future<void>.delayed(const Duration(seconds: 3));
    case 'error':
      throw const ApiException('데모 상태 [오류]로 일부러 낸 오류입니다.');
    case 'empty':
      return const [];
  }
  final url = '$apiBase/$path';
  final http.Response res;
  try {
    res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
  } on Exception catch (e) {
    debugPrint('[GET 실패] $url — $e');
    throw ApiException('서버에 연결하지 못했습니다.\n$apiBase\nmock_server가 켜져 있는지 확인하세요.');
  }
  if (res.statusCode != 200) {
    throw ApiException('서버 응답 오류 (HTTP ${res.statusCode})\n$url');
  }
  // 한글이 깨지지 않도록 bytes를 UTF-8로 직접 디코딩
  final decoded = jsonDecode(utf8.decode(res.bodyBytes));
  if (decoded is! List) {
    throw ApiException('$url 의 응답이 배열이 아닙니다. db.json을 확인하세요.');
  }
  return decoded;
}

/// D 게시판 탭: GET /posts?board=market (market · studio · lesson · recruit · show)
Future<List<Post>> fetchPosts(String board) async {
  final list = await _getList('posts?board=$board');
  return list.map(Post.fromJson).nonNulls.toList();
}

/// C 추천 결과 · 알림 새 글 → B 게시글 상세: GET /posts?id=1 — 없으면 null
Future<Post?> fetchPost(int id) async {
  final list = await _getList('posts?id=$id');
  return list.map(Post.fromJson).nonNulls.firstOrNull;
}

/// A-5 공지 접기 줄: GET /notices
Future<List<Notice>> fetchNotices() async {
  final list = await _getList('notices');
  return list.map(Notice.fromJson).nonNulls.toList();
}

/// A-8 내 알림 조건 · E 알림: GET /alerts — 미리 걸어 둔 조건과 새 글
Future<List<SearchAlert>> fetchAlerts() async {
  final list = await _getList('alerts');
  return list.map(SearchAlert.fromJson).nonNulls.toList();
}

/// C AI 검색 확인 시트: GET /aiResponses?id=1 — 미리 쓴 응답. 없으면 null(빈 상태)
Future<AiResponse?> fetchAiResponse(int id) async {
  final list = await _getList('aiResponses?id=$id');
  return list.map(AiResponse.fromJson).nonNulls.firstOrNull;
}

/// B 게시글 상세 '시세' 탭: GET /priceInfo?postId=1 — 장터 글이 아니면 null
Future<PriceInfo?> fetchPriceInfo(int postId) async {
  final list = await _getList('priceInfo?postId=$postId');
  return list.map(PriceInfo.fromJson).nonNulls.firstOrNull;
}

/// B 게시글 상세 'AI 상태 체크' 탭: GET /conditionChecks?postId=1 — 미리 쓴 결과. 없으면 null
Future<ConditionCheck?> fetchConditionCheck(int postId) async {
  final list = await _getList('conditionChecks?postId=$postId');
  return list.map(ConditionCheck.fromJson).nonNulls.firstOrNull;
}

/// B 게시글 상세 '후기' 탭: GET /usageReviews?postId=1
Future<List<UsageReview>> fetchUsageReviews(int postId) async {
  final list = await _getList('usageReviews?postId=$postId');
  return list.map(UsageReview.fromJson).nonNulls.toList();
}

/// 화면이 데이터를 받는 함수 모양 — 테스트에서는 가짜 함수를 넣는다.
typedef PostsLoader = Future<List<Post>> Function(String board);
typedef PostLoader = Future<Post?> Function(int id);
typedef NoticesLoader = Future<List<Notice>> Function();
typedef AiResponseLoader = Future<AiResponse?> Function(int id);
typedef ConditionCheckLoader = Future<ConditionCheck?> Function(int postId);
typedef PriceInfoLoader = Future<PriceInfo?> Function(int postId);
typedef UsageReviewsLoader = Future<List<UsageReview>> Function(int postId);
typedef AlertsLoader = Future<List<SearchAlert>> Function();

/// 화면들이 함께 쓰는 loader 묶음 — 하단 메뉴의 네 화면과 C 시트에 한 번에 넘긴다.
class AppLoaders {
  const AppLoaders({
    this.posts = fetchPosts,
    this.post = fetchPost,
    this.notices = fetchNotices,
    this.alerts = fetchAlerts,
    this.aiResponse = fetchAiResponse,
    this.priceInfo = fetchPriceInfo,
    this.conditionCheck = fetchConditionCheck,
    this.usageReviews = fetchUsageReviews,
  });

  final PostsLoader posts;
  final PostLoader post;
  final NoticesLoader notices;
  final AlertsLoader alerts;
  final AiResponseLoader aiResponse;
  final PriceInfoLoader priceInfo;
  final ConditionCheckLoader conditionCheck;
  final UsageReviewsLoader usageReviews;
}
