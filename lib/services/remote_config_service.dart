import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_model.dart';
import '../data/shop_data.dart'; // Fallback data

class RemoteConfigService {
  // Real GitHub Raw URL
  static const String _remoteConfigUrl = 'https://raw.githubusercontent.com/parkjaiwoong/NBerONE/main/shops.json';
  static const String _cachedShopsKey = 'cached_shops_data';
  static const String _lastUpdateKey = 'last_remote_update';

  // Fetch and update shop data
  Future<List<ShopModel>> fetchShopData() async {
    try {
      // 1. Try to fetch from network
      final response = await http.get(Uri.parse(_remoteConfigUrl));

      if (response.statusCode == 200) {
        // Success: Parse and cache
        final String jsonBody = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(jsonBody);
        final List<ShopModel> remoteShops = jsonList
            .map((json) => ShopModel.fromJson(json))
            .toList();
            
        await _cacheShopData(jsonBody);
        return remoteShops;
      } else {
        throw Exception('Failed to load remote config');
      }
    } catch (e) {
      // 2. Error or Offline: Try to load from local cache
      return await _loadCachedShopData();
    }
  }

  // Save to SharedPreferences
  Future<void> _cacheShopData(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedShopsKey, jsonString);
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Load from SharedPreferences, fallback to local code
  Future<List<ShopModel>> _loadCachedShopData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedJson = prefs.getString(_cachedShopsKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(cachedJson);
        return jsonList.map((json) => ShopModel.fromJson(json)).toList();
      } catch (e) {
        // Corrupt cache
      }
    }

    // 3. Fallback: Use the hardcoded list in shop_data.dart
    return allShops;
  }
}
