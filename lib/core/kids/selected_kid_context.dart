import 'package:flutter/foundation.dart';

class SelectedKidContext extends ChangeNotifier {
  String? _kidId;
  String? _kidName;

  String? get kidId => _kidId;
  String? get kidName => _kidName;
  bool get isActive => _kidId != null && _kidId!.isNotEmpty;

  void select(String? kidId, {String? name}) {
    if (_kidId == kidId && _kidName == name) return;
    _kidId = kidId;
    _kidName = name;
    notifyListeners();
  }

  void clear() => select(null);
}
