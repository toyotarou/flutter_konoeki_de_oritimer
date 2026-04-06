import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../model/tokyo_train_model.dart';
import 'utility.dart';

/// 現在地と指定駅の距離を文字列で返す（例: "320m", "1.2km", "---"）
String distanceText({
  required String stationName,
  required Position? currentPosition,
  required List<TokyoTrainModel> trainList,
}) {
  if (currentPosition == null) return '---';

  for (final TokyoTrainModel train in trainList) {
    for (final TokyoStationModel station in train.station) {
      if (station.stationName == stationName) {
        final double meters = Utility().calculateDistance(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          LatLng(station.lat, station.lng),
        );
        return meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters.toStringAsFixed(0)}m';
      }
    }
  }
  return '---';
}
