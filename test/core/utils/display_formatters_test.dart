import 'package:ciervo_clud/core/utils/display_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisplayFormatters.safeText', () {
    test('returns fallback for null and literal null', () {
      expect(DisplayFormatters.safeText(null, fallback: 'Usuario'), 'Usuario');
      expect(DisplayFormatters.safeText('null', fallback: 'Usuario'), 'Usuario');
      expect(DisplayFormatters.safeText('  ', fallback: 'Usuario'), 'Usuario');
    });

    test('trims valid text', () {
      expect(DisplayFormatters.safeText('  Gabriel  '), 'Gabriel');
    });
  });

  group('DisplayFormatters.safeDisplayName', () {
    test('uses nickname first', () {
      expect(
        DisplayFormatters.safeDisplayName(
          nickname: 'Josecito',
          firstName: 'José',
        ),
        'Josecito',
      );
    });

    test('never returns null string', () {
      expect(
        DisplayFormatters.safeDisplayName(
          displayName: 'null',
          ciervoId: 'CIERVO-123',
        ),
        'CIERVO-123',
      );
    });
  });

  group('DisplayFormatters.formatStatus', () {
    test('maps numeric status ids', () {
      expect(DisplayFormatters.formatStatus('1'), 'Pendiente');
      expect(DisplayFormatters.formatStatus('3'), 'Rechazada');
      expect(DisplayFormatters.formatStatus('6'), 'Pagada');
    });
  });
}
