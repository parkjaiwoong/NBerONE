import 'dart:convert';
import 'dart:io';

import '../lib/data/shop_data.dart';

void main() async {
  final list = allShops.map((s) => s.toJson()).toList();
  final json = JsonEncoder.withIndent('  ').convert(list);
  await File('shops.json').writeAsString(json, encoding: utf8);
  print('shops.json generated with ${list.length} shops');
}
