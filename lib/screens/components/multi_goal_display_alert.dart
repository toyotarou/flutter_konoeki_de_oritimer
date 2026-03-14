import 'package:flutter/material.dart';
import 'package:flutter_oritimer/controllers/controllers_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_oritimer/screens/components/multi_goal_setting_alert.dart';
import 'package:flutter_oritimer/screens/parts/oritimer_dialog.dart';

class MultiGoalDisplayAlert extends ConsumerStatefulWidget {
  const MultiGoalDisplayAlert({super.key});

  @override
  ConsumerState<MultiGoalDisplayAlert> createState() => _MultiGoalDisplayAlertState();
}

class _MultiGoalDisplayAlertState extends ConsumerState<MultiGoalDisplayAlert>
    with ControllersMixin<MultiGoalDisplayAlert> {
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
                      onPressed: () {
                        appParamNotifier.setSelectedMultiNumber(number: -1);
                        appParamNotifier.setSelectedStationName(name: '');

                        OritimerDialog(context: context, widget: const MultiGoalSettingAlert());
                      },

                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2)),

                      child: Text('設定'),
                    ),
                  ],
                ),

                Divider(color: Colors.white.withValues(alpha: 0.4), thickness: 5),

                // Expanded(child: displaySalaryList()),
                //
                //
                //
                //
              ],
            ),
          ),
        ),
      ),
    );
  }
}
