import 'package:dio/dio.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/errors/error_mapper.dart';

/// Normaliza y valida la fecha de expiración antes de tokenizar con Mercado Pago.
class MercadoPagoCardExpiration {
  const MercadoPagoCardExpiration({
    required this.month,
    required this.year,
  });

  final int month;
  final int year;

  static MercadoPagoCardExpiration parse(String monthText, String yearText) {
    final month = int.tryParse(monthText.trim());
    final yearRaw = int.tryParse(yearText.trim());
    if (month == null || yearRaw == null) {
      throw MercadoPagoTokenizationException('Fecha de expiración inválida.');
    }
    if (month < 1 || month > 12) {
      throw MercadoPagoTokenizationException(
        'El mes de expiración debe estar entre 01 y 12.',
      );
    }

    final year = MercadoPagoCardExpiration.normalizeYear(yearRaw);
    final now = DateTime.now();
    final expirationEnd = DateTime(year, month + 1, 0);
    if (expirationEnd.isBefore(DateTime(now.year, now.month, now.day))) {
      throw MercadoPagoTokenizationException('La tarjeta está vencida.');
    }

    return MercadoPagoCardExpiration(month: month, year: year);
  }

  /// Mercado Pago exige un año de 4 dígitos (p. ej. 2029, no 29).
  static int normalizeYear(int year) {
    if (year >= 1000) return year;
    if (year >= 0 && year <= 99) return 2000 + year;
    throw MercadoPagoTokenizationException('Año de expiración inválido.');
  }
}

/// Tokeniza tarjetas usando la API oficial de Mercado Pago.
/// Los datos sensibles se envían únicamente a Mercado Pago, nunca al backend CIERVO.
class MercadoPagoCardTokenizer {
  MercadoPagoCardTokenizer({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<String> createCardToken({
    required String publicKey,
    required String cardNumber,
    required String securityCode,
    required int expirationMonth,
    required int expirationYear,
    required String cardholderName,
    String? identificationType,
    String? identificationNumber,
  }) async {
    final sanitizedNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    final normalizedYear = MercadoPagoCardExpiration.normalizeYear(expirationYear);
    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.mercadopago.com/v1/card_tokens',
      queryParameters: {'public_key': publicKey},
      data: {
        'card_number': sanitizedNumber,
        'security_code': securityCode,
        'expiration_month': expirationMonth,
        'expiration_year': normalizedYear,
        'cardholder': {
          'name': cardholderName.trim(),
          if (identificationType != null && identificationNumber != null)
            'identification': {
              'type': identificationType,
              'number': identificationNumber,
            },
        },
      },
    );

    final token = response.data?['id']?.toString();
    if (token == null || token.isEmpty) {
      throw MercadoPagoTokenizationException(
        'Mercado Pago no devolvió un cardToken válido.',
      );
    }
    return token;
  }
}

class MercadoPagoTokenizationException implements Exception {
  MercadoPagoTokenizationException(this.message);

  final String message;

  @override
  String toString() => message;

  static MercadoPagoTokenizationException fromObject(Object error) {
    if (error is MercadoPagoTokenizationException) return error;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null) {
          return MercadoPagoTokenizationException('$message');
        }
      }
      return MercadoPagoTokenizationException(UserErrorMessage.from(
        ErrorMapper.fromObject(error),
      ));
    }
    return MercadoPagoTokenizationException(error.toString());
  }
}
