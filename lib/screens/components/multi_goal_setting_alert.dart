import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_oritimer/controllers/controllers_mixin.dart';
import 'package:flutter_oritimer/model/tokyo_train_model.dart';
import 'package:flutter_oritimer/screens/parts/error_dialog.dart';
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

  Set<int> _registeredSlots = <int>{};

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
      setState(() => _registeredSlots = map.keys.toSet());
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

                        ///MMM
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
                      children: List.generate(10, (index) => index).map((e) {
                        final bool isRegistered = _registeredSlots.contains(e);
                        final bool isSelected = appParamState.selectedMultiNumber == e;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
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
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4)),

                ///HHH
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
