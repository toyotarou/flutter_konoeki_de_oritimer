import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../controllers/controllers_mixin.dart';
import '../model/tokyo_train_model.dart';
import '../utility/distance_text.dart';
import '../utility/functions.dart';
import '../utility/shared_preferences_service.dart';
import '../utility/train_indices.dart';
import 'components/multi_goal_display_alert.dart';
import 'parts/geofence_alert_dialog.dart';
import 'parts/oritimer_dialog.dart';

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

class _HomeScreenState extends ConsumerState<HomeScreen> with ControllersMixin<HomeScreen>, WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final TextEditingController _searchController = TextEditingController();

  TokyoStationModel? _selected;
  int _destinationOccurrenceIndex = 0;

  bool _permissionsGranted = false;

  Map<int, String> _multiGoalMap = <int, String>{};
  Position? _currentPosition;

  final ReceivePort _geofencePort = ReceivePort();
  bool _isAlertDialogShowing = false;
  final FocusNode _dummyFocusNode = FocusNode();

  ///
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlugins();
    _loadMultiGoals();
    _fetchCurrentPosition();
    _registerGeofencePort();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndShowPendingGeofenceAlert();
    }
  }

  ///
  Future<void> _fetchCurrentPosition() async {
    try {
      final Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (_) {}
  }

  ///
  Future<void> _loadMultiGoals() async {
    final Map<int, String> map = await SharedPreferencesService.loadAllMultiGoalEntries();
    if (mounted) {
      setState(() => _multiGoalMap = map);
    }
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

    // アプリ再起動後も監視状態を復元する
    await appParamNotifier.loadFromPrefs();

    // 選択駅を復元する
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stationJson = prefs.getString('selectedStation');
    if (stationJson != null && mounted) {
      try {
        final Map<String, dynamic> map = jsonDecode(stationJson) as Map<String, dynamic>;
        setState(() => _selected = TokyoStationModel.fromJson(map));
      } catch (_) {}
    }

    // マルチゴールのジオフェンスを復元する
    await _restoreMultiGoalGeofences();

    // 起動前にジオフェンスが発火していた場合はダイアログを表示する
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowPendingGeofenceAlert());
  }

  ///
  Future<void> _restoreMultiGoalGeofences() async {
    final Map<int, String> entries = await SharedPreferencesService.loadAllMultiGoalEntries();

    for (final MapEntry<int, String> entry in entries.entries) {
      final ({double? lat, double? lng}) location = await SharedPreferencesService.loadMultiGoalLocation(
        number: entry.key,
      );

      if (location.lat == null || location.lng == null) {
        continue;
      }

      final Geofence zone = Geofence(
        id: 'multiGoal_${entry.key}',
        location: Location(latitude: location.lat!, longitude: location.lng!),
        radiusMeters: 1000,
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
      } catch (_) {}
    }
  }

  ///
  Future<void> _saveSelectedStation(TokyoStationModel station) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedStation', jsonEncode(station.toJson()));
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
  Future<void> _registerSelectedStation() async {
    final TokyoStationModel? s = _selected;

    if (s == null) {
      return;
    }

    final Geofence zone = Geofence(
      id: 'station_${s.stationName}',
      location: Location(latitude: s.lat, longitude: s.lng),
      radiusMeters: 1000,
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
    } catch (_) {}
  }

  ///
  Future<void> _removeAllGeofences() async {
    await NativeGeofenceManager.instance.removeAllGeofences();
    if (Platform.isAndroid) {
      await Vibration.cancel();
    }
    await SharedPreferencesService.clearGeofencePendingAlert();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedStation');
    if (mounted) {
      setState(() => _selected = null);
    }
  }

  ///
  Future<void> _checkAndShowPendingGeofenceAlert() async {
    final bool pending = await SharedPreferencesService.loadGeofencePendingAlert();
    if (pending && mounted && !_isAlertDialogShowing) {
      _showGeofenceAlertDialog();
    }
  }

  ///
  void _registerGeofencePort() {
    IsolateNameServer.removePortNameMapping('geofence_alert_port');
    IsolateNameServer.registerPortWithName(_geofencePort.sendPort, 'geofence_alert_port');
    _geofencePort.listen((_) {
      if (mounted && !_isAlertDialogShowing) {
        _dummyFocusNode.requestFocus();
        _showGeofenceAlertDialog();
      }
    });
  }

  ///
  Future<void> _showGeofenceAlertDialog() async {
    if (!mounted) {
      return;
    }
    _isAlertDialogShowing = true;

    int? multiGoalNumber;
    String stationName;

    if (_multiGoalMap.isNotEmpty) {
      final List<int> sortedKeys = _multiGoalMap.keys.toList()..sort();
      multiGoalNumber = sortedKeys.first;
      stationName = _multiGoalMap[multiGoalNumber]!;
    } else {
      stationName = _selected?.stationName ?? '目的地';
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => GeofenceAlertDialog(
        stationName: stationName,
        onStop: () async {
          Navigator.pop(ctx);
          await _stopFirstGoal(multiGoalNumber);
        },
      ),
    );

    _isAlertDialogShowing = false;
  }

  ///
  Future<void> _stopFirstGoal(int? multiGoalNumber) async {
    await SharedPreferencesService.clearGeofencePendingAlert();
    if (multiGoalNumber != null) {
      // マルチゴール：最初の1件だけ停止
      if (Platform.isAndroid) {
        await Vibration.cancel();
      }
      try {
        await NativeGeofenceManager.instance.removeGeofenceById('multiGoal_$multiGoalNumber');
      } catch (_) {}
      await SharedPreferencesService.deleteMultiGoalEntry(number: multiGoalNumber);
      _loadMultiGoals();
    } else {
      // 単一駅モード：全停止
      appParamNotifier.setIsSetStation(flag: false);
      await _removeAllGeofences();
    }
  }

  ///
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    IsolateNameServer.removePortNameMapping('geofence_alert_port');
    _geofencePort.close();
    _dummyFocusNode.dispose();
    _searchController.dispose();
    if (Platform.isAndroid) {
      Vibration.cancel();
    }
    super.dispose();
  }

  ///
  void _jumpToIndex(int index) {
    if (!_itemScrollController.isAttached) {
      return;
    }
    _itemScrollController.scrollTo(index: index, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  ///
  List<int> _getTrainIndicesForStation(String stationName) =>
      getTrainIndicesForStation(stationName: stationName, trainList: widget.tokyoTrainList);

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
    final String? effectiveStationName =
        selected?.stationName ?? (_multiGoalMap.length == 1 ? _multiGoalMap.values.first : null);

    // 路線名 -> リスト内インデックス
    final Map<String, int> firstIndexByTrainName = <String, int>{};
    for (int i = 0; i < widget.tokyoTrainList.length; i++) {
      firstIndexByTrainName[widget.tokyoTrainList[i].trainName] = i;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('この駅で降りタイマー'),
        actions: <Widget>[
          //          IconButton(onPressed: _showTestNotification, icon: const Icon(Icons.notifications_active), tooltip: '通知テスト'),

          //////
          GestureDetector(
            onTap: () => _requestPermissions(),
            child: Column(
              children: <Widget>[
                Icon(Icons.security, color: _permissionsGranted ? Colors.yellowAccent : Colors.white),
                const SizedBox(height: 5),
                Text(
                  'request',
                  style: TextStyle(fontSize: 10, color: _permissionsGranted ? Colors.yellowAccent : Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          GestureDetector(
            onTap: () {
              appParamNotifier.setIsSetStation(flag: true);

              _registerSelectedStation();
            },
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.remove_red_eye,
                  color: (appParamState.isSetStation || _multiGoalMap.isNotEmpty) ? Colors.yellowAccent : Colors.white,
                ),
                const SizedBox(height: 5),
                Text(
                  'setting',
                  style: TextStyle(
                    fontSize: 10,
                    color: (appParamState.isSetStation || _multiGoalMap.isNotEmpty)
                        ? Colors.yellowAccent
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          if (_multiGoalMap.length >= 2)
            PopupMenuButton<int>(
              padding: EdgeInsets.zero,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.more_vert),
                  SizedBox(height: 5),
                  Text('stop', style: TextStyle(fontSize: 10)),
                ],
              ),
              onSelected: (int number) async {
                // ジオフェンス削除
                try {
                  await NativeGeofenceManager.instance.removeGeofenceById('multiGoal_$number');
                } catch (_) {}

                // バイブレーション停止（Android のみ）
                if (Platform.isAndroid) {
                  await Vibration.cancel();
                }

                await SharedPreferencesService.deleteMultiGoalEntry(number: number);
                _loadMultiGoals();
              },
              itemBuilder: (BuildContext context) {
                final List<int> sortedKeys = _multiGoalMap.keys.toList()..sort();
                return sortedKeys.map((int number) {
                  return PopupMenuItem<int>(
                    value: number,
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text(_multiGoalMap[number]!)),
                        const Icon(Icons.close, size: 16),
                      ],
                    ),
                  );
                }).toList();
              },
            )
          else
            GestureDetector(
              onTap: () async {
                appParamNotifier.setIsSetStation(flag: false);
                _removeAllGeofences();

                // 1件だけ登録されていた場合はそのエントリも削除する
                if (_multiGoalMap.length == 1) {
                  final int number = _multiGoalMap.keys.first;
                  await SharedPreferencesService.deleteMultiGoalEntry(number: number);
                  _loadMultiGoals();
                }
              },
              child: const Column(
                children: <Widget>[
                  Icon(Icons.close),
                  SizedBox(height: 5),
                  Text('stop', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),

          const SizedBox(width: 20),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Focus(focusNode: _dummyFocusNode, autofocus: true, child: const SizedBox.shrink()),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '駅名を検索',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (_, TextEditingValue value, _) {
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        final String query = _searchController.text;
                        _searchController.clear();
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext ctx) {
                            final List<MapEntry<String, List<TokyoTrainModel>>> results = widget
                                .tokyoStationTokyoTrainModelListMap
                                .entries
                                .where((MapEntry<String, List<TokyoTrainModel>> e) => e.key.startsWith(query))
                                .toList();

                            final List<({bool isHeader, String stationName, TokyoTrainModel? train})> flatItems =
                                <({bool isHeader, String stationName, TokyoTrainModel? train})>[];
                            for (final MapEntry<String, List<TokyoTrainModel>> entry in results) {
                              flatItems.add((isHeader: true, stationName: entry.key, train: null));
                              for (final TokyoTrainModel train in entry.value) {
                                flatItems.add((isHeader: false, stationName: entry.key, train: train));
                              }
                            }

                            return AlertDialog(
                              title: Text(query.isEmpty ? '検索結果' : '"$query" の検索結果'),
                              content: query.isEmpty
                                  ? const Text('（未入力）')
                                  : results.isEmpty
                                  ? const Text('該当する駅が見つかりませんでした')
                                  : SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: flatItems.length,
                                        itemBuilder: (_, int i) {
                                          final ({bool isHeader, String stationName, TokyoTrainModel? train}) item =
                                              flatItems[i];
                                          if (item.isHeader) {
                                            return Container(
                                              padding: const EdgeInsets.all(3),
                                              child: Text(
                                                item.stationName,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            );
                                          }
                                          final TokyoTrainModel train = item.train!;
                                          return ListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.only(left: 16),
                                            leading: const Icon(Icons.train),
                                            title: Text(train.trainName),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              FocusManager.instance.primaryFocus?.unfocus();
                                              final int? targetIndex = firstIndexByTrainName[train.trainName];
                                              if (targetIndex != null) {
                                                _jumpToIndex(targetIndex);
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                            );
                          },
                        );
                      },

                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                      child: const Text('検索'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                Text('選択中: ${effectiveStationName ?? (_multiGoalMap.length > 1 ? "複数" : "(未選択)")}'),

                                if (effectiveStationName != null) ...<Widget>[
                                  Text(
                                    distanceText(
                                      stationName: effectiveStationName,
                                      currentPosition: _currentPosition,
                                      trainList: widget.tokyoTrainList,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(width: 20),
                            if (effectiveStationName != null) ...<Widget>[
                              IconButton(
                                onPressed: () {
                                  final List<int> indices = _getTrainIndicesForStation(effectiveStationName);
                                  if (indices.isEmpty) {
                                    return;
                                  }
                                  final int next = (_destinationOccurrenceIndex + 1) % indices.length;
                                  setState(() => _destinationOccurrenceIndex = next);
                                  _jumpToIndex(indices[next]);
                                },
                                icon: const Icon(Icons.swap_vert, color: Colors.greenAccent),
                                tooltip: '次の同名駅へ',
                              ),
                            ] else ...<Widget>[
                              const IconButton(
                                onPressed: null,
                                icon: Icon(Icons.check_box_outline_blank, color: Colors.transparent),
                              ),
                              const IconButton(onPressed: null, icon: Icon(Icons.swap_vert, color: Colors.transparent)),
                            ],
                          ],
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      OritimerDialog(context: context, widget: const MultiGoalDisplayAlert()).then((_) {
                        _loadMultiGoals();
                      });
                    },

                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                    child: const Text('複数'),
                  ),
                ],
              ),

              Divider(color: Colors.white.withValues(alpha: 0.5), thickness: 5),

              Expanded(child: displayStationList(firstIndexByTrainName)),
            ],
          ),
        ),
      ),
    );
  }

  ///
  Widget displayStationList(Map<String, int> firstIndexByTrainName) {
    final List<Widget> list = <Widget>[];

    for (final TokyoTrainModel element in widget.tokyoTrainList) {
      final List<Widget> list2 = <Widget>[];
      for (final TokyoStationModel element2 in element.station) {
        list2.add(
          DefaultTextStyle(
            style: const TextStyle(fontSize: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              ),
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.only(left: 20, right: 60),

              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = element2;
                        _destinationOccurrenceIndex = 0;
                      });
                      _saveSelectedStation(element2);
                    },

                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: (_selected != null && _selected!.stationName == element2.stationName)
                          ? Colors.yellowAccent.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(flex: 2, child: Text(element2.stationName, maxLines: 1, overflow: TextOverflow.ellipsis)),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[Text(element2.lat.toString()), Text(element2.lng.toString())],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      list.add(
        ExpansionTile(
          title: DefaultTextStyle(
            style: const TextStyle(fontSize: 12),
            child: Container(
              decoration: BoxDecoration(color: Colors.yellowAccent.withValues(alpha: 0.1)),
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[Text(element.trainName), const SizedBox.shrink()],
              ),
            ),
          ),
          children: list2,
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) => list[index],
    );
  }
}
