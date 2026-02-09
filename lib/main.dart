import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data/shop_data.dart';
import 'models/shop_model.dart';
import 'screens/settings_screen.dart';
import 'screens/product_comparison_screen.dart';
import 'services/storage_service.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ShoppingLauncherApp());
}

class ShoppingLauncherApp extends StatelessWidget {
  const ShoppingLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '원클릭 쇼핑몰',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  List<ShopModel> _activeShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    
    // 1. Fetch latest shop data (Network -> Cache -> Code)
    final List<ShopModel> allAvailableShops = await _remoteConfigService.fetchShopData(forceRefresh: forceRefresh);
    
    // 2. Load active IDs
    final activeIds = await _storageService.loadActiveShopIds();
    
    // 3. Map IDs to ShopModels using the FETCHED list
    final List<ShopModel> shops = [];
    for (var id in activeIds) {
      try {
        final shop = allAvailableShops.firstWhere((s) => s.id == id);
        shops.add(shop);
      } catch (e) {
        // Shop ID might not exist in master list anymore
      }
    }
    
    setState(() {
      _activeShops = shops;
      _isLoading = false;
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL을 열 수 없습니다: $e')),
        );
      }
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ).then((_) {
      // Refresh list with latest remote data when returning from settings
      _loadData(forceRefresh: true);
    });
  }

  void _openProductComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductComparisonScreen(
          activeShops: _activeShops,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원클릭 쇼핑몰'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: _openProductComparison,
            tooltip: '상품 비교',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('쇼핑몰 정보를 업데이트하는 중...'), duration: Duration(seconds: 1)),
              );
              await _loadData(forceRefresh: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('업데이트 완료!'), duration: Duration(seconds: 1)),
                );
              }
            },
            tooltip: '정보 새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '쇼핑몰 설정',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeShops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '선택된 쇼핑몰이 없습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _openSettings,
                        child: const Text('쇼핑몰 추가하기'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _loadData(forceRefresh: true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _activeShops.length,
                              itemBuilder: (context, index) {
                                final shop = _activeShops[index];
                                return _buildShopButton(
                                  context,
                                  shop: shop,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          '이 앱을 통한 구매는 운영자에게 도움이 됩니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSettings,
        tooltip: '쇼핑몰 추가/삭제',
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _isDeepLink(String url) {
    final deepLinkKeywords = ['link.coupang.com', 'app.ac', 'temu.to'];
    return deepLinkKeywords.any((keyword) => url.contains(keyword));
  }

  Widget _buildShopButton(BuildContext context, {required ShopModel shop}) {
    final color = Color(shop.colorValue);
    final isDeepLink = _isDeepLink(shop.url);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 80,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Main Area (Web / Fallback)
            Expanded(
              child: InkWell(
                onTap: () => _launchURL(shop.url),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        isDeepLink ? Icons.shopping_bag_outlined : Icons.shopping_bag,
                        size: 30,
                        color: color,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Divider
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[200],
            ),

            // App Button
            InkWell(
              onTap: () => _launchURL(shop.appUrl ?? shop.url),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '앱 실행',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
