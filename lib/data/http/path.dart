enum APIPath { getTokyoTrainStation }

extension APIPathExtension on APIPath {
  String? get value {
    switch (this) {
      case APIPath.getTokyoTrainStation:
        return 'getTokyoTrainStation';
    }
  }
}
