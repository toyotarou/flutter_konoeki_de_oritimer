import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_param.freezed.dart';

part 'app_param.g.dart';

@freezed
class AppParamState with _$AppParamState {
  const factory AppParamState({@Default(false) bool isSetStation}) = _AppParamState;
}

@riverpod
class AppParam extends _$AppParam {
  ///
  @override
  AppParamState build() => AppParamState();

  ///
  void setIsSetStation({required bool flag}) => state = state.copyWith(isSetStation: flag);
}
