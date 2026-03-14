import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_oritimer/controllers/controllers_mixin.dart';
import 'package:flutter_oritimer/model/tokyo_train_model.dart';

class MultiGoalSettingAlert extends ConsumerStatefulWidget {
  const MultiGoalSettingAlert({super.key});

  @override
  ConsumerState<MultiGoalSettingAlert> createState() => _MultiGoalSettingAlertState();
}

class _MultiGoalSettingAlertState extends ConsumerState<MultiGoalSettingAlert>
    with ControllersMixin<MultiGoalSettingAlert> {
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
                    Text('multi goal setting'),

                    ElevatedButton(
                      onPressed: () {},

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
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: GestureDetector(
                            onTap: () {
                              appParamNotifier.setSelectedMultiNumber(number: e);
                            },
                            child: CircleAvatar(
                              backgroundColor: (appParamState.selectedMultiNumber == e)
                                  ? Colors.yellowAccent.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),

                              child: Text((e + 1).toString(), style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4)),

                Expanded(child: _buildTrainList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///
  Widget _buildTrainList() {
    final List<TokyoTrainModel> trainList = tokyoTrainState.tokyoTrainList;

    if (trainList.isEmpty) {
      return const Center(child: Text('データなし'));
    }

    return ListView.builder(
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
