import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_oritimer/controllers/controllers_mixin.dart';
import 'package:flutter_oritimer/model/tokyo_train_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/station_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.tokyoTrainList,
    required this.tokyoTrainMap,
    required this.tokyoStationTokyoTrainModelListMap,
  });

  final List<TokyoTrainModel> tokyoTrainList;
  final Map<String, TokyoTrainModel> tokyoTrainMap;
  final Map<String, List<TokyoTrainModel>> tokyoStationTokyoTrainModelListMap;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with ControllersMixin<HomeScreen> {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  StationModel? _selected;

  bool _permissionsGranted = false;

  StreamSubscription<Position>? _positionStream;

  ///
  final List<StationModel> _stations = const <StationModel>[
    StationModel('東京', 35.681236, 139.767125),
    StationModel('神田', 35.691690, 139.770883),
    StationModel('秋葉原', 35.698683, 139.774219),
    StationModel('御徒町', 35.707438, 139.774632),
    StationModel('上野', 35.713768, 139.777254),
    StationModel('鶯谷', 35.721484, 139.778969),
    StationModel('日暮里', 35.727772, 139.770987),
    StationModel('西日暮里', 35.732135, 139.766787),
    StationModel('田端', 35.738079, 139.761210),
    StationModel('駒込', 35.736489, 139.746875),
    StationModel('巣鴨', 35.733492, 139.739345),
    StationModel('大塚', 35.731401, 139.728662),
    StationModel('池袋', 35.728926, 139.710380),
    StationModel('目白', 35.721204, 139.706587),
    StationModel('高田馬場', 35.712777, 139.703643),
    StationModel('新大久保', 35.701273, 139.700309),
    StationModel('新宿', 35.690921, 139.700258),
    StationModel('代々木', 35.683061, 139.702042),
    StationModel('原宿', 35.670168, 139.702687),
    StationModel('渋谷', 35.658034, 139.701636),
    StationModel('恵比寿', 35.646690, 139.710106),
    StationModel('目黒', 35.633998, 139.715828),
    StationModel('五反田', 35.626446, 139.723444),
    StationModel('大崎', 35.619700, 139.728553),
    StationModel('品川', 35.628471, 139.738760),
    StationModel('高輪ゲートウェイ', 35.635191, 139.740083),
    StationModel('田町', 35.645736, 139.747575),
    StationModel('浜松町', 35.655646, 139.757091),
    StationModel('新橋', 35.666195, 139.758587),
    StationModel('有楽町', 35.675069, 139.763328),
  ];

  ///
  @override
  void initState() {
    super.initState();
    _initPlugins();
  }

  ///
  Future<void> _initPlugins() async {
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(settings: initSettings);

    await NativeGeofenceManager.instance.initialize();

    await _checkPermissions();
  }

  ///
  Future<void> _checkPermissions() async {
    final PermissionStatus location = await Permission.location.status;
    final PermissionStatus locationAlways = await Permission.locationAlways.status;
    final PermissionStatus notification = await Permission.notification.status;

    final bool granted = location.isGranted && locationAlways.isGranted && notification.isGranted;

    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
      });
    }
  }

  ///
  Future<void> _requestPermissions() async {
    await Permission.location.request();

    await Permission.locationAlways.request();

    await Permission.notification.request();

    await _checkPermissions();
  }

  ///
  void _startLocationStream() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position pos) {}, onError: (Object e) {});
  }

  ///
  Future<void> _registerSelectedStation() async {
    final StationModel? s = _selected;

    if (s == null) {
      return;
    }

    final Geofence zone = Geofence(
      id: 'station_${s.name}',
      location: Location(latitude: s.lat, longitude: s.lng),
      radiusMeters: 500,
      triggers: <GeofenceEvent>{GeofenceEvent.enter},
      iosSettings: const IosGeofenceSettings(initialTrigger: true),
      androidSettings: const AndroidGeofenceSettings(
        initialTriggers: <GeofenceEvent>{GeofenceEvent.enter},
        expiration: Duration(days: 7),
        loiteringDelay: Duration(minutes: 1),
        notificationResponsiveness: Duration(seconds: 10),
      ),
    );

    try {
      await NativeGeofenceManager.instance.createGeofence(zone, geofenceCallback);

      _startLocationStream();
    } catch (_) {}
  }

  ///
  Future<void> _removeAllGeofences() async {
    await NativeGeofenceManager.instance.removeAllGeofences();
    _positionStream?.cancel();
    _positionStream = null;
  }

  ///
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ///
  // Future<void> _showTestNotification() async {
  //   final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     'test',
  //     'Test',
  //     channelDescription: 'test notification',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     vibrationPattern: Int64List.fromList(<int>[0, 400, 200, 400]),
  //   );
  //
  //   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
  //
  //   await _notifications.show(
  //     id: 1,
  //     title: 'テスト通知',
  //     body: '通知が出れば OK（振動も確認）',
  //     notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
  //   );
  // }

  ///
  @override
  Widget build(BuildContext context) {
    final StationModel? selected = _selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('この駅で降りタイマー'),
        actions: <Widget>[
          //          IconButton(onPressed: _showTestNotification, icon: const Icon(Icons.notifications_active), tooltip: '通知テスト'),
          GestureDetector(
            onTap: () {
              _requestPermissions();
            },
            child: Column(
              children: [
                Icon(Icons.security, color: (_permissionsGranted) ? Colors.yellowAccent : Colors.white),
                SizedBox(height: 5),
                Text(
                  'request',
                  style: TextStyle(fontSize: 10, color: (_permissionsGranted) ? Colors.yellowAccent : Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(width: 20),

          GestureDetector(
            onTap: () {
              _removeAllGeofences();
            },
            child: Column(
              children: [
                Icon(Icons.close),
                SizedBox(height: 5),
                Text('stop', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),

          SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('駅を選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                Text('選択中: ${selected?.name ?? "(未選択)"}'),
              ],
            ),

            Divider(color: Colors.white.withValues(alpha: 0.5), thickness: 5),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _stations.map((StationModel s) {
                    final bool isSel = selected?.name == s.name;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                      ),
                      padding: const EdgeInsets.all(5),

                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selected = s;
                        }),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 24,
                              child: Text(
                                s.name.characters.take(2).toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                decoration: isSel ? TextDecoration.underline : TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: _registerSelectedStation,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('この駅で監視開始'),
            ),
          ],
        ),
      ),
    );
  }
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

  final String stationNames = params.geofences.map((ActiveGeofence g) => g.id).join(', ');

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'geofence',
    'Geofence',
    channelDescription: 'Notify when entering the selected station area',
    importance: Importance.max,
    priority: Priority.high,
    vibrationPattern: Int64List.fromList(<int>[0, 800, 200, 800, 200, 1200]),
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await notifications.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: '降りる駅アラーム',
    body: '到着（または進入）しました: $stationNames / event=${params.event}',
    notificationDetails: details,
  );
}
