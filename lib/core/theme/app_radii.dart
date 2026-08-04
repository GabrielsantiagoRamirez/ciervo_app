import 'package:flutter/widgets.dart';

/// Radios del sistema visual CIERVO.
///
/// Estándar de cards / paneles: **20px** ([card]).
abstract final class AppRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double cardPx = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double pill = 999;

  /// Radio único para cards, tiles y paneles de contenido.
  static const BorderRadius card = BorderRadius.all(Radius.circular(cardPx));

  /// Inputs y campos (alineado a 20px con las cards).
  static const BorderRadius input = BorderRadius.all(Radius.circular(cardPx));

  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius nav = BorderRadius.all(Radius.circular(xl));

  /// Esquinas superiores (sheets / bottom panels).
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(cardPx),
  );

  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: card,
  );
}
