import 'dart:convert';
import 'dart:io';
import 'lib/data/shop_data.dart';

void main() {
  final List<Map<String, dynamic>> jsonList = allShops.map((shop) => shop.toJson()).toList();
  final String jsonString = jsonEncode(jsonList);
  
  final file = File('shops.json');
  file.writeAsStringSync(jsonString);
  
  print('shops.json created successfully with ${allShops.length} shops.');
}
