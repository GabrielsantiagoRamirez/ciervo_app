import '../../domain/entities/financial_history_item.dart';
import '../../../receipts/domain/entities/receipt.dart';

abstract final class ReceiptShareText {
  static String fromReceipt(Receipt receipt) {
    final buffer = StringBuffer()
      ..writeln('Comprobante CIERVO')
      ..writeln(receipt.title)
      ..writeln('Valor: ${receipt.currency} ${receipt.amount.toStringAsFixed(0)}')
      ..writeln('Estado: ${receipt.status}');
    if (receipt.description != null && receipt.description!.isNotEmpty) {
      buffer.writeln('Concepto: ${receipt.description}');
    }
    if (receipt.date != null) {
      buffer.writeln('Fecha: ${receipt.date!.toLocal()}');
    }
    buffer.writeln('Referencia: ${receipt.id}');
    if (receipt.publicReceiptUrl != null && receipt.publicReceiptUrl!.isNotEmpty) {
      buffer.writeln(receipt.publicReceiptUrl);
    } else {
      buffer.writeln('¡Gracias por confiar en CIERVO!');
    }
    return buffer.toString().trim();
  }

  static String fromMovement(FinancialHistoryItem item) {
    final buffer = StringBuffer()
      ..writeln('Movimiento CIERVO')
      ..writeln(item.displayTitle)
      ..writeln(
        '${item.isCredit ? 'Ingreso' : 'Egreso'}: ${item.currency} ${item.amount.toStringAsFixed(0)}',
      )
      ..writeln('Estado: ${item.status}');
    if (item.date != null) {
      buffer.writeln('Fecha: ${item.date!.toLocal()}');
    }
    if (item.balanceAfter != null) {
      buffer.writeln(
        'Saldo: ${item.currency} ${item.balanceAfter!.toStringAsFixed(0)}',
      );
    }
    buffer.writeln('Referencia: ${item.sourceId}');
    buffer.writeln('¡Gracias por confiar en CIERVO!');
    return buffer.toString().trim();
  }
}
