import 'package:share_plus/share_plus.dart';

abstract final class CiervoShare {
  static Future<void> shareText(
    String text, {
    String? subject,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await Share.share(trimmed, subject: subject);
  }
}
