import 'package:flutter/material.dart';
import 'package:flutter_oritimer/controllers/controllers_mixin.dart';
import 'package:flutter_oritimer/model/tokyo_train_model.dart';
import 'package:flutter_oritimer/utility/functions.dart';
import 'package:flutter_oritimer/utility/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_geofence/native_geofence.dart';

class PatternRouteDisplayAlert extends ConsumerStatefulWidget {
  const PatternRouteDisplayAlert({super.key, this.onPatternApplied});

  final VoidCallback? onPatternApplied;

  @override
  ConsumerState<PatternRouteDisplayAlert> createState() => _PatternRouteDisplayAlertState();
}

class _PatternRouteDisplayAlertState extends ConsumerState<PatternRouteDisplayAlert>
    with ControllersMixin<PatternRouteDisplayAlert> {
  Map<int, ({String name, List<String> stations})> _patternMap = <int, ({String name, List<String> stations})>{};
  List<String>? _selectedStations;

  ///
  @override
  void initState() {
    super.initState();
    _loadPatterns();
  }

  ///
  Future<void> _loadPatterns() async {
    final Map<int, ({String name, List<String> stations})> map = await SharedPreferencesService.loadAllRoutePatterns();
    if (mounted) {
      setState(() => _patternMap = map);
    }
  }

  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),

          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('pattern route list'),

                    ElevatedButton(
                      onPressed: () async {
                        final List<String>? stations = _selectedStations;
                        if (stations == null) return;

                        // 既存ジオフェンス・エントリをクリア
                        await NativeGeofenceManager.instance.removeAllGeofences();
                        await SharedPreferencesService.clearAllMultiGoalEntries();

                        // 駅名から座標を検索してジオフェンス登録
                        for (int i = 0; i < stations.length; i++) {
                          final String stationName = stations[i];

                          await SharedPreferencesService.saveMultiGoalEntry(number: i, stationName: stationName);

                          // tokyoTrainList から座標を検索
                          TokyoStationModel? stationModel;
                          outer:
                          for (final TokyoTrainModel train in tokyoTrainState.tokyoTrainList) {
                            for (final TokyoStationModel s in train.station) {
                              if (s.stationName == stationName) {
                                stationModel = s;
                                break outer;
                              }
                            }
                          }

                          if (stationModel == null) continue;

                          // 座標を保存（再起動後の復元用）
                          await SharedPreferencesService.saveMultiGoalLocation(
                            number: i,
                            lat: stationModel.lat,
                            lng: stationModel.lng,
                          );

                          // ジオフェンス登録
                          final Geofence zone = Geofence(
                            id: 'multiGoal_$i',
                            location: Location(latitude: stationModel.lat, longitude: stationModel.lng),
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

                        if (!mounted) return;
                        widget.onPatternApplied?.call();
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      },

                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                      child: Text('設定'),
                    ),
                  ],
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4), thickness: 5),

                Expanded(child: _buildPatternList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///
  Widget _buildPatternList() {
    if (_patternMap.isEmpty) {
      return const Center(child: Text('登録なし'));
    }

    final List<int> sortedKeys = _patternMap.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (BuildContext context, int index) {
        final int slot = sortedKeys[index];
        final List<String> stations = _patternMap[slot]!.stations;
        String dispString = stations.join(' → ');

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  setState(() => _selectedStations = stations);
                  appParamNotifier.setSelectedPatternDispString(str: dispString);
                },
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: (appParamState.selectedPatternDispString == dispString)
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.yellowAccent.withValues(alpha: 0.2),
                  child: Text((index + 1).toString(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(dispString, style: const TextStyle(fontSize: 14, color: Colors.white)),
              ),

              const SizedBox(width: 16),

              IconButton(
                onPressed: () {
                  showDeleteDialog(
                    context: context,
                    onConfirm: () async {
                      await SharedPreferencesService.deleteRoutePattern(slot: slot);

                      // 削除したパターンが選択中だった場合はハイライトをクリア
                      if (appParamState.selectedPatternDispString == dispString) {
                        appParamNotifier.setSelectedPatternDispString(str: '');
                        setState(() => _selectedStations = null);
                      }

                      _loadPatterns();
                    },
                  );
                },
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        );
      },
    );
  }
}
