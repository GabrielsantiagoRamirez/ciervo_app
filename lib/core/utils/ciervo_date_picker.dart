import 'package:flutter/material.dart';

/// Date picker localizado en español (Colombia) con textos de producción.
Future<DateTime?> showCiervoDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String helpText = 'Selecciona la fecha',
  String? errorFormatText,
  String? errorInvalidText,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return showDatePicker(
    context: context,
    locale: const Locale('es', 'CO'),
    helpText: helpText,
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    initialDate: initialDate ?? DateTime(now.year - 20, now.month, now.day),
    firstDate: firstDate ?? DateTime(1940),
    lastDate: lastDate ?? today,
    errorFormatText: errorFormatText ?? 'Formato inválido',
    errorInvalidText: errorInvalidText ?? 'Fecha fuera de rango',
  );
}
