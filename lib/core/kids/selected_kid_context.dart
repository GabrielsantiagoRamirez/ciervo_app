import 'package:flutter/foundation.dart';

class SelectedKidContext extends ChangeNotifier {
  String? _kidId;

  String? get kidId => _kidId;

  void select(String? kidId) {
    if (_kidId == kidId) return;
    _kidId = kidId;
    notifyListeners();
  }
}
