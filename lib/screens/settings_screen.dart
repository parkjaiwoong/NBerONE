import 'package:flutter/material.dart';
import '../models/shop_model.dart';
import '../services/storage_service.dart';
import '../services/remote_config_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final RemoteConfigService _remoteConfigService = RemoteConfigService(); // Add service
  List<ShopModel> _allShops = []; // State for dynamic shop list
  List<String> _activeShopIds = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data
  }

  Future<void> _loadData() async {
    // Fetch dynamic shops
    final shops = await _remoteConfigService.fetchShopData();
    final ids = await _storageService.loadActiveShopIds();
    
    setState(() {
      _allShops = shops;
      _activeShopIds = ids;
    });
  }

  Future<void> _toggleShop(String id) async {
    await _storageService.toggleShopId(id);
    final ids = await _storageService.loadActiveShopIds(); // Refresh IDs
    setState(() {
      _activeShopIds = ids;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter shops based on search query
    final filteredShops = _allShops.where((shop) {
      final name = shop.name.replaceAll(' ', '').toLowerCase();
      final category = shop.category.replaceAll(' ', '').toLowerCase();
      final query = _searchQuery.replaceAll(' ', '').toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    // Group by category
    final Map<String, List<ShopModel>> groupedShops = {};
    for (var shop in filteredShops) {
      if (!groupedShops.containsKey(shop.category)) {
        groupedShops[shop.category] = [];
      }
      groupedShops[shop.category]!.add(shop);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('쇼핑몰 설정'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '쇼핑몰 또는 카테고리 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Categorized List
          Expanded(
            child: ListView.builder(
              itemCount: groupedShops.keys.length,
              itemBuilder: (context, index) {
                final category = groupedShops.keys.elementAt(index);
                final shops = groupedShops[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey[100],
                      width: double.infinity,
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    // Shop Items
                    ...shops.map((shop) {
                      final isActive = _activeShopIds.contains(shop.id);
                      final color = Color(shop.colorValue);

                      return CheckboxListTile(
                        activeColor: color,
                        title: Row(
                          children: [
                            Icon(Icons.shopping_bag, color: color, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                shop.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        value: isActive,
                        onChanged: (bool? value) {
                          _toggleShop(shop.id);
                        },
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
