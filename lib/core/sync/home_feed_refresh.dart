import 'package:flutter/foundation.dart';

/// Notifica a las secciones del inicio que deben recargar datos (novedades, ads, favoritos, bonos).
class HomeFeedRefresh extends ChangeNotifier {
  HomeFeedRefresh._();

  static final HomeFeedRefresh instance = HomeFeedRefresh._();

  void refreshAll() => notifyListeners();

  void favoritesChanged() => notifyListeners();
}
