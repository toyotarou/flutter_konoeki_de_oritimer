import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:native_geofence/native_geofence.dart';

import '../../controllers/controllers_mixin.dart';
import '../../model/tokyo_train_model.dart';
import '../../utility/distance_text.dart';
import '../../utility/shared_preferences_service.dart';
import '../parts/delete_dialog.dart';
import '../parts/error_dialog.dart';
import '../parts/oritimer_dialog.dart';
import 'multi_goal_setting_alert.dart';
import 'pattern_route_display_alert.dart';

class MultiGoalDisplayAlert extends ConsumerStatefulWidget {
  const MultiGoalDisplayAlert({super.key});

  @override
  ConsumerState<MultiGoalDisplayAlert> createState() => _MultiGoalDisplayAlertState();
}

class _MultiGoalDisplayAlertState extends ConsumerState<MultiGoalDisplayAlert>
    with ControllersMixin<MultiGoalDisplayAlert> {
  Map<int, String> _multiGoalMap = <int, String>{};
  bool _loadedFromPattern = false;
  Position? _currentPosition;

  ///
  @override
  void initState() {
    super.initState();
    _loadMultiGoals();
    _fetchCurrentPosition();
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
    final Map<int, String> map = await appParamNotifier.loadAllMultiGoalEntries();
    if (mounted) {
      setState(() => _multiGoalMap = map);
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
                    const Text('multi goal list'),

                    Row(
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            OritimerDialog(
                              context: context,
                              widget: PatternRouteDisplayAlert(onPatternApplied: () => _loadedFromPattern = true),
                            ).then((_) {
                              _loadMultiGoals();
                            });
                          },

                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                          child: const Text('パターン'),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed: () async {
                            final Map<int, String> registered = await appParamNotifier.loadAllMultiGoalEntries();

                            if (registered.length >= 10) {
                              // ignore: always_specify_types
                              Future.delayed(
                                Duration.zero,
                                () => error_dialog(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  title: '登録できません。',
                                  content: '目的地は10個までしか登録できません。',
                                ),
                              );
                              return;
                            }

                            int nextSlot = 0;
                            while (nextSlot < 10 && registered.containsKey(nextSlot)) {
                              nextSlot++;
                            }

                            appParamNotifier.setSelectedMultiNumber(number: nextSlot < 10 ? nextSlot : -1);
                            appParamNotifier.setSelectedStationName(name: '');

                            if (!mounted) {
                              return;
                            }
                            // ignore: use_build_context_synchronously
                            OritimerDialog(context: context, widget: const MultiGoalSettingAlert()).then((_) {
                              setState(() => _loadedFromPattern = false);
                              _loadMultiGoals();
                            });
                          },

                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                          child: const Text('設定'),
                        ),
                      ],
                    ),
                  ],
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4), thickness: 5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const SizedBox.shrink(),

                    if (_multiGoalMap.length >= 2 && !_loadedFromPattern) ...<Widget>[
                      TextButton(
                        onPressed: () async {
                          final List<int> sortedKeys = _multiGoalMap.keys.toList()..sort();
                          final List<String> stations = sortedKeys.map((int k) => _multiGoalMap[k]!).toList();

                          await SharedPreferencesService.saveRoutePattern(
                            name: DateTime.now().millisecondsSinceEpoch.toString(),
                            stations: stations,
                          );

                          if (!mounted) {
                            return;
                          }
                          // ignore: use_build_context_synchronously
                          error_dialog(context: context, title: '登録しました', content: stations.join(' → '));
                        },
                        child: const Text('パターン登録'),
                      ),
                    ] else ...<Widget>[const SizedBox.shrink()],
                  ],
                ),

                Expanded(child: _buildMultiGoalList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///
  LatLng? _getStationLatLng(String stationName) {
    for (final TokyoTrainModel train in tokyoTrainState.tokyoTrainList) {
      for (final TokyoStationModel station in train.station) {
        if (station.stationName == stationName) {
          return LatLng(station.lat, station.lng);
        }
      }
    }
    return null;
  }

  ///
  Widget _buildMultiGoalList() {
    if (_multiGoalMap.isEmpty) {
      return const Center(child: Text('登録なし'));
    }

    final List<int> sortedKeys = _multiGoalMap.keys.toList()..sort();
    final int lastKey = sortedKeys.last;

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (BuildContext context, int index) {
        final int number = sortedKeys[index];
        final String stationName = _multiGoalMap[number]!;
        final bool isLast = number == lastKey;

        final LatLng? fromLatLng = index == 0
            ? (_currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : null)
            : _getStationLatLng(_multiGoalMap[sortedKeys[index - 1]]!);

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: 30,
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(color: Colors.yellowAccent.withValues(alpha: 0.2)),
                  child: Text(
                    distanceText(
                      stationName: stationName,
                      fromLatLng: fromLatLng,
                      trainList: tokyoTrainState.tokyoTrainList,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.yellowAccent.withValues(alpha: 0.2),
                    child: Text((number + 1).toString(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(stationName, style: const TextStyle(fontSize: 14, color: Colors.white)),
                  ),

                  if (isLast)
                    GestureDetector(
                      onTap: () {
                        showDeleteDialog(
                          context: context,
                          onConfirm: () async {
                            try {
                              await NativeGeofenceManager.instance.removeGeofenceById('multiGoal_$number');
                            } catch (_) {}

                            await appParamNotifier.deleteMultiGoalEntry(number: number);
                            _loadMultiGoals();
                          },
                        );
                      },
                      child: const Icon(Icons.delete),
                    )
                  else
                    const Icon(Icons.square_outlined, color: Colors.transparent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
