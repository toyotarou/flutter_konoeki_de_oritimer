import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/http/client.dart';
import '../../../data/http/path.dart';
import '../../../extensions/extensions.dart';
import '../../../model/tokyo_train_model.dart';
import '../../../utility/utility.dart';

part 'tokyo_train.freezed.dart';

part 'tokyo_train.g.dart';

@freezed
class TokyoTrainState with _$TokyoTrainState {
  const factory TokyoTrainState({
    @Default(<TokyoTrainModel>[]) List<TokyoTrainModel> tokyoTrainList,
    @Default(<String, TokyoTrainModel>{}) Map<String, TokyoTrainModel> tokyoTrainMap,
    @Default(<String, List<TokyoTrainModel>>{}) Map<String, List<TokyoTrainModel>> tokyoStationTokyoTrainModelListMap,
  }) = _TokyoTrainState;
}

@Riverpod(keepAlive: true)
class TokyoTrain extends _$TokyoTrain {
  final Utility utility = Utility();

  ///
  @override
  TokyoTrainState build() => const TokyoTrainState();

  //============================================== api

  ///
  Future<TokyoTrainState> fetchAllTokyoTrainData() async {
    final HttpClient client = ref.read(httpClientProvider);

    try {
      final List<TokyoTrainModel> list = <TokyoTrainModel>[];
      final Map<String, TokyoTrainModel> map = <String, TokyoTrainModel>{};
      final Map<String, List<TokyoTrainModel>> map2 = <String, List<TokyoTrainModel>>{};

      // ignore: always_specify_types
      await client.post(path: APIPath.getTokyoTrainStation).then((value) {
        // ignore: avoid_dynamic_calls
        for (int i = 0; i < value['data'].length.toString().toInt(); i++) {
          // ignore: avoid_dynamic_calls
          final TokyoTrainModel val = TokyoTrainModel.fromJson(value['data'][i] as Map<String, dynamic>);

          list.add(val);

          map[val.trainName] = val;

          for (final TokyoStationModel element in val.station) {
            (map2[element.stationName] ??= <TokyoTrainModel>[]).add(
              TokyoTrainModel(trainNumber: val.trainNumber, trainName: val.trainName, station: <TokyoStationModel>[]),
            );
          }
        }
      });

      return state.copyWith(tokyoTrainList: list, tokyoTrainMap: map, tokyoStationTokyoTrainModelListMap: map2);
    } catch (e) {
      utility.showError('予期せぬエラーが発生しました');
      rethrow; // これにより呼び出し元でキャッチできる
    }
  }

  ///
  Future<void> getAllTokyoTrain() async {
    try {
      final TokyoTrainState newState = await fetchAllTokyoTrainData();

      state = newState;
    } catch (_) {}
  }

  //============================================== api
}
