import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_comparison_model.dart';
import '../models/shop_model.dart';
import '../services/naver_shopping_service.dart';

class ProductComparisonScreen extends StatefulWidget {
  final List<ShopModel> allShops;

  const ProductComparisonScreen({
    super.key,
    required this.allShops,
  });

  @override
  State<ProductComparisonScreen> createState() => _ProductComparisonScreenState();
}

class _ProductComparisonScreenState extends State<ProductComparisonScreen> {
  final NaverShoppingService _service = NaverShoppingService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ProductComparisonItem> _results = [];
  int _total = 0;
  int _nextStart = 1; // API 다음 요청 start 값
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤 끝에 도달 시 자동 더보기
    if (!_isLoadingMore && _hasMore && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastQuery = query;
      _results = [];
      _total = 0;
      _nextStart = 1;
      _hasMore = false;
    });

    try {
      final result = await _service.search(
        query,
        start: 1,
        display: NaverShoppingService.defaultDisplay,
        filterByShops: widget.allShops,
      );

      if (mounted) {
        setState(() {
          _results = result.items;
          _total = result.total;
          _nextStart = result.nextStart;
          _hasMore = result.hasMore;
          _isLoading = false;
        });
      }
    } on NaverApiKeyException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _results = [];
          _total = 0;
          _nextStart = 1;
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        String message;
        if (errStr.contains('host lookup') ||
            errStr.contains('SocketException') ||
            errStr.contains('Failed host lookup')) {
          message = '네트워크 연결을 확인해주세요.\n(인터넷 연결, WiFi/데이터 상태 확인)';
        } else if (errStr.contains('024') || errStr.contains('인증에 실패')) {
          message =
              'API 인증 오류입니다.\n'
              '1. 네이버 개발자센터 API 설정에서 "검색" 사용 여부 확인\n'
              '2. Playground에서 "쇼핑 검색" API로 테스트해보세요';
        } else {
          message = '검색 중 오류가 발생했습니다: $e';
        }
        setState(() {
          _errorMessage = message;
          _results = [];
          _total = 0;
          _nextStart = 1;
          _hasMore = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastQuery.isEmpty) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _service.search(
        _lastQuery,
        start: _nextStart,
        display: NaverShoppingService.defaultDisplay,
        filterByShops: widget.allShops,
      );

      if (mounted) {
        setState(() {
          _results = [..._results, ...result.items];
          _total = result.total;
          _nextStart = result.nextStart;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('추가 로드 실패: $e')),
          );
        });
      }
    }
  }

  Future<void> _launchProductUrl(ProductComparisonItem item) async {
    final shop = _service.findShopForMall(widget.allShops, item.mallName);
    final hasDeepLink = shop != null &&
        shop.appUrl != null &&
        shop.appUrl!.isNotEmpty;

    if (hasDeepLink) {
      // 딥링크 있는 경우: 상품명 복사 + 설명 표시 + 앱 열기
      await Clipboard.setData(ClipboardData(text: item.title));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '상품명이 복사되었습니다. ${item.mallName} 앱에서 검색창에 붙여넣기 후 검색해주세요.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      final uri = Uri.parse(shop!.appUrl!);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch ${shop.appUrl}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('앱을 열 수 없습니다: $e')),
          );
        }
      }
    } else {
      // 딥링크 없는 경우: 상품 상세페이지로 바로 이동
      final uri = Uri.parse(item.link);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch ${item.link}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('링크를 열 수 없습니다: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 비교'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '상품명 검색 (쇼핑몰 설정 전체 조회)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isLoading ? null : _search,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  tooltip: '검색',
                ),
              ],
            ),
          ),

          // 안내 문구
          if (widget.allShops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Text(
                '쇼핑몰 설정에 등록된 ${widget.allShops.length}개 전체 조회됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),

          if (widget.allShops.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '쇼핑몰 설정에 등록된 쇼핑몰이 없습니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),

          // 결과 목록
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.orange[700]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty && _lastQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 검색어로 시도해보세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '상품명을 입력하고 검색하세요.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '가격순으로 정렬되어 표시됩니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _results.length + (_hasMore || _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.add),
                label: Text('더보기 (${_results.length} / $_total)'),
              ),
            ),
          );
        }
        final item = _results[index];
        final rank = index + 1;
        return _ProductItemCard(
          item: item,
          rank: rank,
          onTap: () => _launchProductUrl(item),
        );
      },
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final ProductComparisonItem item;
  final int rank;
  final VoidCallback onTap;

  const _ProductItemCard({
    required this.item,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 순위
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rank <= 3 ? Colors.amber : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: rank <= 3 ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 상품 이미지
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, color: Colors.grey),
                ),
              const SizedBox(width: 12),

              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.mallName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.priceRange,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
