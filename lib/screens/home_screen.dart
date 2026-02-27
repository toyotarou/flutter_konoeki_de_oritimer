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

  TokyoStationModel? _selected;

  bool _permissionsGranted = false;

  StreamSubscription<Position>? _positionStream;

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
    final TokyoStationModel? s = _selected;

    if (s == null) {
      return;
    }

    final Geofence zone = Geofence(
      id: 'station_${s.stationName}',
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
    final TokyoStationModel? selected = _selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('この駅で降りタイマー'),
        actions: <Widget>[
          //          IconButton(onPressed: _showTestNotification, icon: const Icon(Icons.notifications_active), tooltip: '通知テスト'),

          //////
          GestureDetector(
            onTap: () => _requestPermissions(),
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
              appParamNotifier.setIsSetStation(flag: true);

              _registerSelectedStation();
            },
            child: Column(
              children: [
                Icon(Icons.remove_red_eye, color: (appParamState.isSetStation) ? Colors.yellowAccent : Colors.white),
                SizedBox(height: 5),
                Text(
                  'setting',
                  style: TextStyle(
                    fontSize: 10,
                    color: (appParamState.isSetStation) ? Colors.yellowAccent : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 20),

          GestureDetector(
            onTap: () {
              appParamNotifier.setIsSetStation(flag: false);

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

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('選択中: ${selected?.stationName ?? "(未選択)"}'), SizedBox.shrink()],
              ),

              Divider(color: Colors.white.withValues(alpha: 0.5), thickness: 5),

              Expanded(child: displayStationList()),
            ],
          ),
        ),
      ),
    );
  }

  ///
  Widget displayStationList() {
    final List<Widget> list = <Widget>[];

    for (var element in widget.tokyoTrainList) {
      List<Widget> list2 = <Widget>[];
      for (var element2 in element.station) {
        list2.add(
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
            ),
            padding: const EdgeInsets.all(5),

            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selected = element2),

                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: (_selected != null && _selected!.stationName == element2.stationName)
                        ? Colors.yellowAccent.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                  ),
                ),

                SizedBox(width: 20),

                Expanded(flex: 2, child: Text(element2.stationName, maxLines: 1, overflow: TextOverflow.ellipsis)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(element2.lat.toString()), Text(element2.lng.toString())],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      list.add(
        Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.yellowAccent.withValues(alpha: 0.1)),
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(element.trainName), SizedBox.shrink()],
              ),
            ),

            Row(
              children: [
                SizedBox(width: 30),
                Expanded(child: Column(children: list2)),
              ],
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => list[index],
            childCount: list.length,
          ),
        ),
      ],
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
    body: stationNames,
    notificationDetails: details,
  );
}
