import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_param.freezed.dart';

part 'app_param.g.dart';

const String _kIsSetStation = 'isSetStation';

@freezed
class AppParamState with _$AppParamState {
  const factory AppParamState({@Default(false) bool isSetStation}) = _AppParamState;
}

@riverpod
class AppParam extends _$AppParam {
  ///
  @override
  AppParamState build() => AppParamState();

  /// アプリ起動時に SharedPreferences から状態を復元する
  Future<void> loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool saved = prefs.getBool(_kIsSetStation) ?? false;
    state = state.copyWith(isSetStation: saved);
  }

  /// 監視ON/OFFを切り替えつつ SharedPreferences に保存する
  void setIsSetStation({required bool flag}) {
    state = state.copyWith(isSetStation: flag);
    _persistFlag(flag);
  }

  Future<void> _persistFlag(bool flag) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (flag) {
      await prefs.setBool(_kIsSetStation, true);
    } else {
      await prefs.remove(_kIsSetStation);
    }
  }
}
