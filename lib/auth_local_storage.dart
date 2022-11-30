import 'dart:convert';

import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStorage {
  const AuthLocalStorage(this.prefs);
  final SharedPreferences prefs;

  Future<void> clear() async {
    await prefs.remove("model");
  }

  Future<void> saveAuthRecord(RecordAuth record) async {
    await prefs.setString("model", jsonEncode(record.toJson()));
  }

  Future<void> saveProviderRecord(AuthMethodProvider provider) async {
    await prefs.setString("provider", jsonEncode(provider.toJson()));
  }

  Map<String, dynamic>? loadJsonRecord(String key) {
    String modelJson = prefs.getString(key) ?? "";
    if (modelJson.isNotEmpty) {
      return jsonDecode(modelJson);
    }
  }
}
