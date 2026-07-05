import 'package:flutter/material.dart';

/// Oculta el teclado sin afectar la navegación ni otros gestos.
void dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

/// Envuelve la app para cerrar el teclado al tocar fuera de un campo de texto.
///
/// Escribir en un [TextField] no dispara el cierre; solo interacciones fuera
/// del campo (toque en fondo, scroll, botones, cambio de pestaña, etc.).
class DismissKeyboardScope extends StatelessWidget {
  const DismissKeyboardScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
