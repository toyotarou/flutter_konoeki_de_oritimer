import '../model/tokyo_train_model.dart';

/// 指定した駅名を含む路線のインデックス一覧を返す
List<int> getTrainIndicesForStation({required String stationName, required List<TokyoTrainModel> trainList}) {
  final List<int> indices = <int>[];
  for (int i = 0; i < trainList.length; i++) {
    if (trainList[i].station.any((TokyoStationModel s) => s.stationName == stationName)) {
      indices.add(i);
    }
  }
  return indices;
}
