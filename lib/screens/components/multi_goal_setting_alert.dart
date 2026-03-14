import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_oritimer/controllers/controllers_mixin.dart';
import 'package:flutter_oritimer/model/tokyo_train_model.dart';
import 'package:flutter_oritimer/screens/parts/error_dialog.dart';
import 'package:flutter_oritimer/utility/functions.dart';
import 'package:flutter_oritimer/utility/shared_preferences_service.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MultiGoalSettingAlert extends ConsumerStatefulWidget {
  const MultiGoalSettingAlert({super.key});

  @override
  ConsumerState<MultiGoalSettingAlert> createState() => _MultiGoalSettingAlertState();
}

class _MultiGoalSettingAlertState extends ConsumerState<MultiGoalSettingAlert>
    with ControllersMixin<MultiGoalSettingAlert> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final TextEditingController _searchController = TextEditingController();

  Map<int, String> _registeredEntries = <int, String>{};
  final Map<int, int> _occurrenceIndices = <int, int>{};

  ///
  @override
  void initState() {
    super.initState();
    _loadRegisteredSlots();
  }

  ///
  Future<void> _loadRegisteredSlots() async {
    final Map<int, String> map = await appParamNotifier.loadAllMultiGoalEntries();
    if (mounted) {
      setState(() => _registeredEntries = map);
    }
  }

  ///
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ///
  void _jumpToIndex(int index) {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(index: index, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  ///
  @override
  Widget build(BuildContext context) {
    final List<TokyoTrainModel> trainList = tokyoTrainState.tokyoTrainList;

    final Map<String, int> firstIndexByTrainName = <String, int>{};
    for (int i = 0; i < trainList.length; i++) {
      firstIndexByTrainName[trainList[i].trainName] = i;
    }

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
                    Text('multi goal setting'),

                    ElevatedButton(
                      onPressed: () async {
                        final bool saved = await appParamNotifier.saveMultiGoalEntry();

                        if (!saved) {
                          // ignore: always_specify_types
                          Future.delayed(
                            Duration.zero,
                            () => error_dialog(
                              // ignore: use_build_context_synchronously
                              context: context,
                              title: '登録できません。',
                              content: '番号と駅を選択してください。',
                            ),
                          );
                          return;
                        }

                        // ジオフェンス登録
                        final String stationName = appParamState.selectedStationName;
                        final int number = appParamState.selectedMultiNumber;

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

                        if (stationModel != null) {
                          // 座標を保存（再起動後のジオフェンス復元用）
                          await SharedPreferencesService.saveMultiGoalLocation(
                            number: number,
                            lat: stationModel.lat,
                            lng: stationModel.lng,
                          );

                          final Geofence zone = Geofence(
                            id: 'multiGoal_$number',
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

                        // ignore: use_build_context_synchronously
                        if (mounted) Navigator.pop(context);
                      },

                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                      child: Text('設定'),
                    ),
                  ],
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4), thickness: 5),

                SizedBox(
                  height: 60,

                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(10, (index) => index).map((e) {
                        final bool isRegistered = _registeredEntries.containsKey(e);
                        final bool isSelected = appParamState.selectedMultiNumber == e;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: (isRegistered)
                                    ? () {
                                        final String stationName = _registeredEntries[e] ?? '';
                                        final List<int> indices = getTrainIndicesForStation(
                                          stationName: stationName,
                                          trainList: tokyoTrainState.tokyoTrainList,
                                        );
                                        if (indices.isEmpty) return;
                                        final int current = _occurrenceIndices[e] ?? 0;
                                        final int next = (current + 1) % indices.length;
                                        setState(() => _occurrenceIndices[e] = next);
                                        _jumpToIndex(indices[next]);
                                      }
                                    : null,
                                child: CircleAvatar(
                                  backgroundColor: isRegistered
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : isSelected
                                      ? Colors.yellowAccent.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.3),

                                  child: Text(
                                    (e + 1).toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRegistered ? Colors.white.withValues(alpha: 0.5) : Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              if (isRegistered) ...[
                                SizedBox(height: 5),

                                Text(
                                  _registeredEntries[e] ?? '',
                                  style: const TextStyle(fontSize: 8, color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4)),

                _buildSearchRow(context, firstIndexByTrainName),

                Divider(color: Colors.white.withValues(alpha: 0.4)),

                Expanded(child: _buildTrainList(trainList)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///
  Widget _buildSearchRow(BuildContext context, Map<String, int> firstIndexByTrainName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '駅名を検索',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, TextEditingValue value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.white),
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
              _showSearchDialog(context, query, firstIndexByTrainName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),
            child: const Text('検索'),
          ),
        ],
      ),
    );
  }

  ///
  void _showSearchDialog(BuildContext context, String query, Map<String, int> firstIndexByTrainName) {
    final Map<String, List<TokyoTrainModel>> stationMap = tokyoTrainState.tokyoStationTokyoTrainModelListMap;

    final List<MapEntry<String, List<TokyoTrainModel>>> results = stationMap.entries
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

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
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
                      final ({bool isHeader, String stationName, TokyoTrainModel? train}) item = flatItems[i];
                      if (item.isHeader) {
                        return Container(
                          padding: const EdgeInsets.all(3),
                          child: Text(item.stationName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
  }

  ///
  Widget _buildTrainList(List<TokyoTrainModel> trainList) {
    if (trainList.isEmpty) {
      return const Center(child: Text('データなし'));
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemCount: trainList.length,
      itemBuilder: (BuildContext context, int index) {
        final TokyoTrainModel train = trainList[index];

        final List<Widget> stationWidgets = train.station.map((TokyoStationModel station) {
          return Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
            ),
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    appParamNotifier.setSelectedStationName(name: station.stationName);
                  },
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: (appParamState.selectedStationName == station.stationName)
                        ? Colors.yellowAccent.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    station.stationName,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList();

        return ExpansionTile(
          title: DefaultTextStyle(
            style: const TextStyle(fontSize: 12),
            child: Container(
              decoration: BoxDecoration(color: Colors.yellowAccent.withValues(alpha: 0.1)),
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(train.trainName, style: const TextStyle(color: Colors.white)),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          children: stationWidgets,
        );
      },
    );
  }
}
