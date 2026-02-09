/// Naver Shopping API 검색 결과 상품 모델
class ProductComparisonItem {
  final String title;
  final String link;
  final String? imageUrl;
  final int lprice; // 최저가
  final int hprice; // 최고가 (0이면 없음)
  final String mallName;
  final String? brand;
  final String? maker;
  final String? category1;
  final String? category2;

  ProductComparisonItem({
    required this.title,
    required this.link,
    this.imageUrl,
    required this.lprice,
    this.hprice = 0,
    required this.mallName,
    this.brand,
    this.maker,
    this.category1,
    this.category2,
  });

  factory ProductComparisonItem.fromJson(Map<String, dynamic> json) {
    // API 응답에서 HTML 태그 제거
    String cleanTitle = (json['title'] as String? ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '');
    return ProductComparisonItem(
      title: cleanTitle,
      link: json['link'] as String? ?? '',
      imageUrl: json['image'] as String?,
      lprice: _parsePrice(json['lprice']),
      hprice: _parsePrice(json['hprice']),
      mallName: json['mallName'] as String? ?? '네이버',
      brand: json['brand'] as String?,
      maker: json['maker'] as String?,
      category1: json['category1'] as String?,
      category2: json['category2'] as String?,
    );
  }

  static int _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get formattedPrice => _formatPrice(lprice);
  String get priceRange {
    if (hprice > 0 && hprice != lprice) {
      return '${_formatPrice(lprice)} ~ ${_formatPrice(hprice)}';
    }
    return formattedPrice;
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      return '${(price / 10000).toStringAsFixed(price % 10000 == 0 ? 0 : 1)}만원';
    }
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}원';
  }
}
