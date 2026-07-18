import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

/// Lectura de UID NFC con soporte nacional e internacional.
abstract final class NfcTagReader {
  static Future<bool> isAvailable() => NfcManager.instance.isAvailable();

  /// Lee el UID de una tarjeta o dispositivo NFC y lo devuelve en hexadecimal.
  static Future<String?> readUid({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final available = await isAvailable();
    if (!available) return null;

    String? uid;
    var completed = false;

    await NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        uid = _extractUid(tag);
        completed = true;
        await NfcManager.instance.stopSession();
      },
    );

    final started = DateTime.now();
    while (!completed && DateTime.now().difference(started) < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}

    return uid;
  }

  /// Lee el contenido NDEF textual/JSON sin persistirlo.
  static Future<String?> readPayload({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!await isAvailable()) return null;
    String? payload;
    var completed = false;

    await NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        final message = Ndef.from(tag)?.cachedMessage;
        for (final record in message?.records ?? const <NdefRecord>[]) {
          payload = _decodePayload(record.payload);
          if (payload != null) break;
        }
        completed = true;
        await NfcManager.instance.stopSession();
      },
    );

    final started = DateTime.now();
    while (!completed && DateTime.now().difference(started) < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
    return payload;
  }

  static String? _decodePayload(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final direct = utf8.decode(bytes, allowMalformed: true).trim();
    if (direct.startsWith('{') && direct.endsWith('}')) return direct;

    final languageLength = bytes.first & 0x3f;
    final textStart = 1 + languageLength;
    if (textStart >= bytes.length) return null;
    final text = utf8
        .decode(bytes.sublist(textStart), allowMalformed: true)
        .trim();
    return text.isEmpty ? null : text;
  }

  static String? _extractUid(NfcTag tag) {
    final data = tag.data;
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Map) {
        final identifier = value['identifier'];
        if (identifier is Uint8List && identifier.isNotEmpty) {
          return _bytesToHex(identifier);
        }
        final id = value['id'];
        if (id is Uint8List && id.isNotEmpty) {
          return _bytesToHex(id);
        }
      }
    }
    return null;
  }

  static String _bytesToHex(Uint8List bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
}
