import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utility/shared_preferences_service.dart';

part 'app_param.freezed.dart';

part 'app_param.g.dart';

@freezed
class AppParamState with _$AppParamState {
  const factory AppParamState({
    @Default(false) bool isSetStation,
    @Default(-1) int selectedMultiNumber,
    @Default('') String selectedStationName,
    @Default('') String selectedPatternDispString,
  }) = _AppParamState;
}

@riverpod
class AppParam extends _$AppParam {
  ///
  @override
  AppParamState build() => AppParamState();

  /// アプリ起動時に SharedPreferences から状態を復元する
  Future<void> loadFromPrefs() async {
    final bool saved = await SharedPreferencesService.loadIsSetStation();
    state = state.copyWith(isSetStation: saved);
  }

  /// 監視ON/OFFを切り替えつつ SharedPreferences に保存する
  void setIsSetStation({required bool flag}) {
    state = state.copyWith(isSetStation: flag);
    SharedPreferencesService.saveIsSetStation(flag);
  }

  ///
  void setSelectedMultiNumber({required int number}) => state = state.copyWith(selectedMultiNumber: number);

  ///
  void setSelectedStationName({required String name}) => state = state.copyWith(selectedStationName: name);

  /// selectedMultiNumber と selectedStationName の組み合わせを SharedPreferences に保存する
  /// 保存できた場合は true、バリデーション失敗の場合は false を返す
  Future<bool> saveMultiGoalEntry() async {
    final int number = state.selectedMultiNumber;
    final String stationName = state.selectedStationName;

    if (number < 0 || stationName.isEmpty) return false;

    await SharedPreferencesService.saveMultiGoalEntry(number: number, stationName: stationName);
    return true;
  }

  /// 指定した番号のマルチゴールを読み込む
  Future<String?> loadMultiGoalEntry({required int number}) =>
      SharedPreferencesService.loadMultiGoalEntry(number: number);

  /// 指定した番号のマルチゴールを削除する
  Future<void> deleteMultiGoalEntry({required int number}) =>
      SharedPreferencesService.deleteMultiGoalEntry(number: number);

  /// 登録済みの全マルチゴールを読み込む（番号 → 駅名）
  Future<Map<int, String>> loadAllMultiGoalEntries() => SharedPreferencesService.loadAllMultiGoalEntries();

  ///
  void setSelectedPatternDispString({required String str}) => state = state.copyWith(selectedPatternDispString: str);
}
