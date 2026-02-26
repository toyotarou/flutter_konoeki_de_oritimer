import 'package:flutter_riverpod/flutter_riverpod.dart';

import '_get_data/tokyo_train/tokyo_train.dart';

mixin ControllersMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  //==========================================//

  TokyoTrainState get tokyoTrainState => ref.watch(tokyoTrainProvider);

  TokyoTrain get tokyoTrainNotifier => ref.read(tokyoTrainProvider.notifier);

  //==========================================//
}
