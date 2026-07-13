import 'package:flutter/material.dart';

Future<bool?> showBlockUserConfirmationDialog(
  BuildContext context, {
  required String displayName,
}) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Bloquear usuario'),
    content: Text(
      '¿Bloquear a $displayName? Dejara de aparecer en busquedas, chats y contenido para ti.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Bloquear'),
      ),
    ],
  ),
);
