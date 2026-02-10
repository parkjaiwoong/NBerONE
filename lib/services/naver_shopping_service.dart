import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/product_comparison_model.dart';
import '../models/shop_model.dart';

/// 네이버 쇼핑 검색 API 서비스
/// .env 파일에 NAVER_CLIENT_ID, NAVER_CLIENT_SECRET을 설정하세요.
/// https://developers.naver.com/apps/#/list 에서 애플리케이션 등록 후 발급
class NaverShoppingService {
  static const String _baseUrl = 'https://openapi.naver.com/v1/search/shop.json';

  String get _clientId => (dotenv.env['NAVER_CLIENT_ID'] ?? '').trim();
  String get _clientSecret => (dotenv.env['NAVER_CLIENT_SECRET'] ?? '').trim();

  /// 우리 앱 쇼핑몰 ID -> 네이버 API mallName 매칭 키워드
  static const Map<String, List<String>> _mallNameKeywords = {
    'coupang': ['쿠팡', 'coupang'],
    '11st': ['11번가', '11st', '일일번가'],
    'gmarket': ['G마켓', '지마켓', 'gmarket', 'g마켓'],
    'auction': ['옥션', 'auction'],
    'ali': ['알리', '알리익스프레스', 'aliexpress'],
    'ssg': ['SSG', '에스에스지', 'ssg'],
    'wemakeprice': ['위메프', 'wemakeprice'],
    'tmon': ['티몬', 'tmon'],
    'interpark': ['인터파크', 'interpark'],
    'lotteon': ['롯데온', '롯데', 'lotte'],
    'hmall': ['현대', 'Hmall', 'hmall', '에이치몰'],
    'gsshop': ['GS샵', 'GS SHOP', 'gsshop', '지에스샵'],
    'cjonstyle': ['CJ온스타일', '온스타일', 'cjonstyle'],
    'lotte_home': ['롯데홈쇼핑', 'lotteimall'],
    'nsmall': ['NS홈쇼핑', 'nsmall', '엔에스'],
    'shinsegaetv': ['신세계', 'shinsegae'],
    'akmall': ['AK몰', 'akmall', '에이케이몰'],
    'musinsa': ['무신사', 'musinsa'],
    'zigzag': ['지그재그', 'zigzag'],
    'ably': ['에이블리', 'ably'],
    'brandi': ['브랜디', 'brandi'],
    'wconcept': ['W컨셉', 'wconcept'],
    '29cm': ['29CM', '29cm'],
    'oliveyoung': ['올리브영', 'oliveyoung'],
    'kream': ['크림', 'kream'],
    'kurly': ['마켓컬리', '컬리', 'kurly'],
    'emart': ['이마트', '이마트몰', 'emart'],
    'homeplus': ['홈플러스', 'homeplus'],
    'oasis': ['오아시스', 'oasis'],
    'yanolja': ['야놀자', 'yanolja'],
    'yeogi': ['여기어때', 'goodchoice'],
    'agoda': ['아고다', 'agoda'],
    'tripcom': ['트립닷컴', '트립컴', 'trip'],
    'hotelscom': ['호텔스닷컴', 'hotels'],
    'airbnb': ['에어비앤비', 'airbnb'],
    'myrealtrip': ['마이리얼트립', 'myrealtrip'],
    'klook': ['클룩', 'klook'],
    'yes24': ['예스24', 'yes24'],
    'aladin': ['알라딘', 'aladin'],
    'kyobo': ['교보', '교보문고', 'kyobo'],
    'ridibooks': ['리디', '리디북스', 'ridi'],
    'class101': ['클래스101', 'class101'],
    'fastcampus': ['패스트캠퍼스', 'fastcampus'],
    'danawa': ['다나와', 'danawa'],
    'himart': ['하이마트', 'himart'],
    'etland': ['전자랜드', 'etland'],
    'compuzone': ['컴퓨존', 'compuzone'],
    'samsungcard': ['삼성카드', 'samsung'],
    'hyundaicard': ['현대카드', 'hyundai'],
    'direct_ins': ['삼성화재', 'samsungfire'],
    'coway': ['코웨이', 'coway'],
    'sk_magic': ['SK매직', 'skmagic'],
    'lg_electronics': ['LG전자', 'lg'],
    'amazon': ['아마존', 'amazon'],
    'qoo10': ['큐텐', 'qoo10'],
    'temu': ['테무', 'temu'],
    'yoox': ['육스', 'yoox'],
    'farfetch': ['파페치', 'farfetch'],
    'shein': ['쉬인', 'shein'],
    'uniqlo': ['유니클로', 'uniqlo'],
    'clio': ['클리오', 'clio'],
    'pulmuone': ['풀무원', 'pulmuone'],
    'cjthemarket': ['CJ더마켓', 'cjthemarket'],
    'lego': ['레고', 'lego'],
    'adidas': ['아디다스', 'adidas'],
    'stockx': ['스탁엑스', 'stockx'],
    'ohou': ['오늘의집', 'ohou'],
    'soomgo': ['숨고', 'soomgo'],
    'iherb': ['아이허브', 'iherb'],
    'jestina': ['제이에스티나', 'jestina'],
    'lensbank': ['렌즈뱅크', 'lensbank'],
    'lululemon': ['룰루레몬', 'lululemon'],
    'crocs': ['크록스', 'crocs'],
  };

  /// 네이버 쇼핑 검색 결과 (페이징 지원)
  static const int defaultDisplay = 50;

  /// 네이버 쇼핑 검색 (가격 오름차순)
  /// [start] 검색 시작 위치 (1~1000), [display] 한 번에 가져올 개수 (기본 50)
  Future<NaverSearchResult> search(
    String query, {
    int start = 1,
    int display = defaultDisplay,
    List<ShopModel>? filterByShops,
  }) async {
    if (query.trim().isEmpty) {
      return NaverSearchResult(items: [], total: 0, start: 1, display: 0);
    }

    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      throw NaverApiKeyException(
        '네이버 API 키가 설정되지 않았습니다. '
        '.env 파일에 NAVER_CLIENT_ID, NAVER_CLIENT_SECRET을 설정하세요. '
        '(developers.naver.com에서 애플리케이션 등록 후 발급)',
      );
    }

    final displayVal = display.clamp(1, 100);
    final startVal = start.clamp(1, 1000);

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'query': query.trim(),
        'display': displayVal.toString(),
        'start': startVal.toString(),
        'sort': 'asc', // 가격 낮은 순
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'X-Naver-Client-Id': _clientId,
        'X-Naver-Client-Secret': _clientSecret,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      // 네이버 API 에러 응답 파싱 (errorCode 024 = 인증 실패 등)
      String errDetail = response.body;
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>?;
        if (errJson != null && errJson['errorMessage'] != null) {
          errDetail = '${errJson['errorMessage']} (코드: ${errJson['errorCode'] ?? ''})';
        }
      } catch (_) {}
      throw Exception('API 오류: ${response.statusCode} - $errDetail');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final startFrom = (json['start'] as num?)?.toInt() ?? startVal;
    final displayCount = (json['display'] as num?)?.toInt() ?? displayVal;
    final items = (json['items'] as List<dynamic>?)
        ?.map((e) => ProductComparisonItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    // 활성 쇼핑몰만 필터링
    List<ProductComparisonItem> filtered = items;
    if (filterByShops != null && filterByShops.isNotEmpty) {
      final activeIds = filterByShops.map((s) => s.id).toSet();
      filtered = items.where((item) {
        for (final shopId in activeIds) {
          if (_matchesMall(shopId, item.mallName)) return true;
        }
        return false;
      }).toList();
    }

    return NaverSearchResult(
      items: filtered,
      total: total,
      start: startFrom,
      display: displayCount,
    );
  }

  bool _matchesMall(String shopId, String mallName) {
    final keywords = _mallNameKeywords[shopId];
    if (keywords == null) return false;
    final normalizedMall = mallName.replaceAll(' ', '').toLowerCase();
    for (final kw in keywords) {
      final normalizedKw = kw.replaceAll(' ', '').toLowerCase();
      if (normalizedMall.contains(normalizedKw) || normalizedKw.contains(normalizedMall)) {
        return true;
      }
    }
    return false;
  }

  /// ShopModel 목록으로 mallName에 해당하는 shop 찾기
  ShopModel? findShopForMall(List<ShopModel> shops, String mallName) {
    for (final shop in shops) {
      if (_matchesMall(shop.id, mallName)) return shop;
    }
    return null;
  }
}

/// 네이버 쇼핑 검색 결과 (페이징 지원)
class NaverSearchResult {
  final List<ProductComparisonItem> items;
  final int total;
  final int start;
  final int display;

  NaverSearchResult({
    required this.items,
    required this.total,
    required this.start,
    required this.display,
  });

  bool get hasMore => start + display <= total && total > 0;
  int get nextStart => start + display;
}

class NaverApiKeyException implements Exception {
  final String message;
  NaverApiKeyException(this.message);
  @override
  String toString() => message;
}
