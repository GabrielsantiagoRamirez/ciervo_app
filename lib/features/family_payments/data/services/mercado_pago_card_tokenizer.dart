import 'package:dio/dio.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/errors/error_mapper.dart';

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
    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.mercadopago.com/v1/card_tokens',
      queryParameters: {'public_key': publicKey},
      data: {
        'card_number': sanitizedNumber,
        'security_code': securityCode,
        'expiration_month': expirationMonth,
        'expiration_year': expirationYear,
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
