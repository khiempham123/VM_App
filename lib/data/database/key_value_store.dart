import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStorage {
  Future<bool> containsKey(String key);
  Future<bool> removeKey(String key);
  Future<String?> getString(String key);
  Future<bool> setString(String key, String? value);
  Future<List<String>?> getStringList(String key);
  Future<bool> setStringList(String key, List<String>? value);
  Future<bool?> getBool(String key);
  Future<bool> setBool(String key, bool? value);
  Future<int?> getInt(String key);
  Future<bool> setInt(String key, int? value);
  Future<Map<String, dynamic>?> getMap(String key);
  Future<bool> setMap(String key, Map<String, dynamic>? value);
  Future<bool> clear();
  Future<Set<String>> keys();
  Future<bool> remove(String key);
}

class SharedPreferencesKeyValueStorage implements KeyValueStorage {
  static const String kTag = "VM";
  late SharedPreferences _pref;
  final _prefLoaded = Completer<bool>();

  SharedPreferencesKeyValueStorage._(Future<SharedPreferences> pref) {
    pref.then((value) {
      _pref = value;
      _prefLoaded.complete(true);
    });
  }

  factory SharedPreferencesKeyValueStorage.newInstance() {
    return SharedPreferencesKeyValueStorage._(SharedPreferences.getInstance());
  }

  factory SharedPreferencesKeyValueStorage.newInstanceWithSharePreferences(
    SharedPreferences pref,
  ) {
    return SharedPreferencesKeyValueStorage._(Future.value(pref));
  }

  // client should call this mehtod to ensure SharedPreferences loaded
  Future ensureLoaded() async {
    if (_prefLoaded.isCompleted) return true;
    return _prefLoaded.future;
  }

  @override
  Future<bool> containsKey(String key) async {
    await ensureLoaded();
    return _pref.containsKey(key);
  }

  @override
  Future<bool> removeKey(String key) async {
    await ensureLoaded();
    return _pref.remove(key);
  }

  @override
  Future<String?> getString(String key) async {
    await ensureLoaded();
    return _pref.getString(key);
  }

  @override
  Future<bool> setString(String key, String? value) async {
    if (value == null) {
      return removeKey(key);
    }

    await ensureLoaded();
    return _pref.setString(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    await ensureLoaded();
    return _pref.getStringList(key);
  }

  @override
  Future<bool> setStringList(String key, List<String>? value) async {
    if (value == null) {
      return removeKey(key);
    }

    await ensureLoaded();
    return _pref.setStringList(key, value);
  }

  @override
  Future<Map<String, dynamic>?> getMap(String key) async {
    await ensureLoaded();
    String? str = _pref.getString(key);
    if (str != null) {
      try {
        return jsonDecode(str);
      } catch (e, st) {
        debugPrint("$e\n$st");
      }
    }

    return null;
  }

  @override
  Future<bool> setMap(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      return removeKey(key);
    }

    try {
      await ensureLoaded();
      String str = jsonEncode(value);
      return _pref.setString(key, str);
    } catch (e, st) {
      debugPrint("$e\n$st");
    }

    return false;
  }

  @override
  Future<bool> clear() async {
    await ensureLoaded();
    return _pref.clear();
  }

  @override
  Future<bool?> getBool(String key) async {
    await ensureLoaded();
    return _pref.getBool(key);
  }

  @override
  Future<bool> setBool(String key, bool? value) async {
    await ensureLoaded();
    if (value == null) {
      return _pref.remove(key);
    }
    return _pref.setBool(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    await ensureLoaded();
    return _pref.getInt(key);
  }

  @override
  Future<bool> setInt(String key, int? value) async {
    await ensureLoaded();
    if (value == null) {
      return _pref.remove(key);
    }
    return _pref.setInt(key, value);
  }

  @override
  Future<Set<String>> keys() async {
    await ensureLoaded();
    return _pref.getKeys();
  }

  @override
  Future<bool> remove(String key) async {
    await ensureLoaded();
    return _pref.remove(key);
  }
}
