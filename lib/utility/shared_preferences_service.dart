import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences への読み書きをまとめたユーティリティクラス
class SharedPreferencesService {
  SharedPreferencesService._();

  // ─── キー定数 ───────────────────────────────────────
  static const String kIsSetStation = 'isSetStation';
  static const String _kMultiGoalPrefix = 'multiGoal_';

  // ─── isSetStation ────────────────────────────────────

  /// isSetStation を読み込む
  static Future<bool> loadIsSetStation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kIsSetStation) ?? false;
  }

  /// isSetStation を保存する（false の場合はキーを削除）
  static Future<void> saveIsSetStation(bool flag) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (flag) {
      await prefs.setBool(kIsSetStation, true);
    } else {
      await prefs.remove(kIsSetStation);
    }
  }

  // ─── multiGoal ───────────────────────────────────────

  /// 番号と駅名を紐づけて保存する
  static Future<void> saveMultiGoalEntry({required int number, required String stationName}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kMultiGoalPrefix$number', stationName);
  }

  /// 指定した番号の駅名を読み込む
  static Future<String?> loadMultiGoalEntry({required int number}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kMultiGoalPrefix$number');
  }

  /// 指定した番号のエントリを削除する
  static Future<void> deleteMultiGoalEntry({required int number}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kMultiGoalPrefix$number');
  }

  /// 登録済みの全エントリを読み込む（番号 → 駅名）
  static Future<Map<int, String>> loadAllMultiGoalEntries() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<int, String> result = <int, String>{};
    for (int i = 0; i < 10; i++) {
      final String? name = prefs.getString('$_kMultiGoalPrefix$i');
      if (name != null && name.isNotEmpty) {
        result[i] = name;
      }
    }
    return result;
  }

  // ─── selectedStation ─────────────────────────────────

  /// 選択駅の JSON 文字列を保存する
  static Future<void> saveSelectedStation(String json) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedStation', json);
  }

  /// 選択駅の JSON 文字列を読み込む
  static Future<String?> loadSelectedStation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedStation');
  }

  /// 選択駅を削除する
  static Future<void> removeSelectedStation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedStation');
  }
}
