import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_oritimer/const/const.dart';
import 'package:flutter_oritimer/model/tokyo_train_model.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:vibration/vibration.dart';

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

/// =======================
/// Geofence コールバック（トップレベル必須）
/// =======================
@pragma('vm:entry-point')
Future<void> geofenceCallback(GeofenceCallbackParams params) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (_) {}

  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  await notifications.initialize(settings: initSettings);

  // 音量を最大に上げる（Android のみ・音楽ストリーム）
  // システム UI のスライダーを出さずに音量を変更する
  if (Platform.isAndroid) {
    try {
      await FlutterVolumeController.updateShowSystemUI(false);
      await FlutterVolumeController.setVolume(1.0, stream: AudioStream.music);
    } catch (_) {}
  }

  final String stationNames = params.geofences.map((ActiveGeofence g) => g.id).join(', ');

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'geofence',
    'Geofence',
    channelDescription: 'Notify when entering the selected station area',
    importance: Importance.max,
    priority: Priority.high,
    vibrationPattern: Int64List.fromList(kVibrationPattern),
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await notifications.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: '降りる駅アラーム',
    body: stationNames,
    notificationDetails: details,
  );

  // ループバイブレーション開始（Android のみ）
  // repeat: 0 → パターンの先頭から繰り返し → Vibration.cancel() で確実に停止
  if (Platform.isAndroid) {
    final bool hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(pattern: kVibrationPattern, intensities: kVibrationIntensities, repeat: 0);
    }
  }
}
