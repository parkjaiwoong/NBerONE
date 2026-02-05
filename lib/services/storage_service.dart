import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _activeShopIdsKey = 'active_shop_ids';
  
  // Default shops that should be active initially
  static const List<String> _defaultActiveIds = [
    'coupang', 
    '11st', 
    'gmarket', 
    'auction', 
    'ali'
  ];

  // Load active shop IDs
  Future<List<String>> loadActiveShopIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? ids = prefs.getStringList(_activeShopIdsKey);
    
    // If no preference found, return default list
    if (ids == null) {
      // Save defaults immediately so next load is consistent
      // But we can just return defaults
      return List.from(_defaultActiveIds);
    }
    
    return ids;
  }

  // Save active shop IDs
  Future<void> saveActiveShopIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_activeShopIdsKey, ids);
  }

  // Toggle a shop ID (Add if missing, Remove if present)
  Future<void> toggleShopId(String id) async {
    final ids = await loadActiveShopIds();
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await saveActiveShopIds(ids);
  }
  
  // Add shop ID
  Future<void> addShopId(String id) async {
    final ids = await loadActiveShopIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await saveActiveShopIds(ids);
    }
  }

  // Remove shop ID
  Future<void> removeShopId(String id) async {
    final ids = await loadActiveShopIds();
    if (ids.contains(id)) {
      ids.remove(id);
      await saveActiveShopIds(ids);
    }
  }

  // Reset to default
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeShopIdsKey);
  }
}
