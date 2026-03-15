import 'package:flutter/material.dart';
import 'package:flutter_oritimer/controllers/controllers_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_oritimer/screens/components/multi_goal_setting_alert.dart';
import 'package:flutter_oritimer/screens/parts/error_dialog.dart';
import 'package:flutter_oritimer/screens/parts/oritimer_dialog.dart';
import 'package:native_geofence/native_geofence.dart';

class MultiGoalDisplayAlert extends ConsumerStatefulWidget {
  const MultiGoalDisplayAlert({super.key});

  @override
  ConsumerState<MultiGoalDisplayAlert> createState() => _MultiGoalDisplayAlertState();
}

class _MultiGoalDisplayAlertState extends ConsumerState<MultiGoalDisplayAlert>
    with ControllersMixin<MultiGoalDisplayAlert> {
  Map<int, String> _multiGoalMap = <int, String>{};

  ///
  @override
  void initState() {
    super.initState();
    _loadMultiGoals();
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
                    Text('multi goal list'),

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

                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        OritimerDialog(context: context, widget: const MultiGoalSettingAlert()).then((_) {
                          _loadMultiGoals();
                        });
                      },

                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                      child: Text('設定'),
                    ),
                  ],
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4), thickness: 5),

                Expanded(child: _buildMultiGoalList()),
              ],
            ),
          ),
        ),
      ),
    );
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

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
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
                  onTap: () async {
                    // ジオフェンス削除
                    try {
                      await NativeGeofenceManager.instance.removeGeofenceById('multiGoal_$number');
                    } catch (_) {}

                    await appParamNotifier.deleteMultiGoalEntry(number: number);
                    _loadMultiGoals();
                  },
                  child: const Icon(Icons.delete),
                ),
            ],
          ),
        );
      },
    );
  }
}
