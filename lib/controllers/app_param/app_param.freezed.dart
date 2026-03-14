// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_param.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppParamState {
  bool get isSetStation => throw _privateConstructorUsedError;
  int get selectedMultiNumber => throw _privateConstructorUsedError;
  String get selectedStationName => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppParamStateCopyWith<AppParamState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppParamStateCopyWith<$Res> {
  factory $AppParamStateCopyWith(
          AppParamState value, $Res Function(AppParamState) then) =
      _$AppParamStateCopyWithImpl<$Res, AppParamState>;
  @useResult
  $Res call(
      {bool isSetStation, int selectedMultiNumber, String selectedStationName});
}

/// @nodoc
class _$AppParamStateCopyWithImpl<$Res, $Val extends AppParamState>
    implements $AppParamStateCopyWith<$Res> {
  _$AppParamStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSetStation = null,
    Object? selectedMultiNumber = null,
    Object? selectedStationName = null,
  }) {
    return _then(_value.copyWith(
      isSetStation: null == isSetStation
          ? _value.isSetStation
          : isSetStation // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedMultiNumber: null == selectedMultiNumber
          ? _value.selectedMultiNumber
          : selectedMultiNumber // ignore: cast_nullable_to_non_nullable
              as int,
      selectedStationName: null == selectedStationName
          ? _value.selectedStationName
          : selectedStationName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppParamStateImplCopyWith<$Res>
    implements $AppParamStateCopyWith<$Res> {
  factory _$$AppParamStateImplCopyWith(
          _$AppParamStateImpl value, $Res Function(_$AppParamStateImpl) then) =
      __$$AppParamStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isSetStation, int selectedMultiNumber, String selectedStationName});
}

/// @nodoc
class __$$AppParamStateImplCopyWithImpl<$Res>
    extends _$AppParamStateCopyWithImpl<$Res, _$AppParamStateImpl>
    implements _$$AppParamStateImplCopyWith<$Res> {
  __$$AppParamStateImplCopyWithImpl(
      _$AppParamStateImpl _value, $Res Function(_$AppParamStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSetStation = null,
    Object? selectedMultiNumber = null,
    Object? selectedStationName = null,
  }) {
    return _then(_$AppParamStateImpl(
      isSetStation: null == isSetStation
          ? _value.isSetStation
          : isSetStation // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedMultiNumber: null == selectedMultiNumber
          ? _value.selectedMultiNumber
          : selectedMultiNumber // ignore: cast_nullable_to_non_nullable
              as int,
      selectedStationName: null == selectedStationName
          ? _value.selectedStationName
          : selectedStationName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AppParamStateImpl implements _AppParamState {
  const _$AppParamStateImpl(
      {this.isSetStation = false,
      this.selectedMultiNumber = -1,
      this.selectedStationName = ''});

  @override
  @JsonKey()
  final bool isSetStation;
  @override
  @JsonKey()
  final int selectedMultiNumber;
  @override
  @JsonKey()
  final String selectedStationName;

  @override
  String toString() {
    return 'AppParamState(isSetStation: $isSetStation, selectedMultiNumber: $selectedMultiNumber, selectedStationName: $selectedStationName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppParamStateImpl &&
            (identical(other.isSetStation, isSetStation) ||
                other.isSetStation == isSetStation) &&
            (identical(other.selectedMultiNumber, selectedMultiNumber) ||
                other.selectedMultiNumber == selectedMultiNumber) &&
            (identical(other.selectedStationName, selectedStationName) ||
                other.selectedStationName == selectedStationName));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isSetStation, selectedMultiNumber, selectedStationName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppParamStateImplCopyWith<_$AppParamStateImpl> get copyWith =>
      __$$AppParamStateImplCopyWithImpl<_$AppParamStateImpl>(this, _$identity);
}

abstract class _AppParamState implements AppParamState {
  const factory _AppParamState(
      {final bool isSetStation,
      final int selectedMultiNumber,
      final String selectedStationName}) = _$AppParamStateImpl;

  @override
  bool get isSetStation;
  @override
  int get selectedMultiNumber;
  @override
  String get selectedStationName;
  @override
  @JsonKey(ignore: true)
  _$$AppParamStateImplCopyWith<_$AppParamStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
