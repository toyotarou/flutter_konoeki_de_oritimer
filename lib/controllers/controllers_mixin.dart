import 'package:flutter_riverpod/flutter_riverpod.dart';

import '_get_data/tokyo_train/tokyo_train.dart';
import 'app_param/app_param.dart';

mixin ControllersMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  //==========================================//

  AppParamState get appParamState => ref.watch(appParamProvider);

  AppParam get appParamNotifier => ref.read(appParamProvider.notifier);

  //==========================================//

  TokyoTrainState get tokyoTrainState => ref.watch(tokyoTrainProvider);

  TokyoTrain get tokyoTrainNotifier => ref.read(tokyoTrainProvider.notifier);

  //==========================================//
}
