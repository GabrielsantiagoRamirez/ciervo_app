import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/payment_quote.dart';
import '../../domain/entities/universal_nfc_payment.dart';
import '../../domain/repositories/universal_nfc_repository.dart';
import '../datasources/universal_nfc_remote_datasource.dart';

class UniversalNfcRepositoryImpl implements UniversalNfcRepository {
  const UniversalNfcRepositoryImpl(this._remote);

  final UniversalNfcRemoteDataSource _remote;

  @override
  Future<Result<PaymentQuote>> nfcQuote({
    required double amount,
    required String currency,
    String? paymentMethodId,
    int? childProfileId,
  }) =>
      _guard(
        () async => (await _remote.nfcQuote(
          amount: amount,
          currency: currency,
          paymentMethodId: paymentMethodId,
          childProfileId: childProfileId,
        ))
            .toDomain(),
      );

  @override
  Future<Result<PaymentQuote>> transferQuote({
    required double amount,
    required String currency,
    required String destination,
    String? paymentMethodId,
  }) =>
      _guard(
        () async => (await _remote.transferQuote(
          amount: amount,
          currency: currency,
          destination: destination,
          paymentMethodId: paymentMethodId,
        ))
            .toDomain(),
      );

  @override
  Future<Result<List<SavedPaymentMethod>>> paymentMethods() => _guard(
        () async => (await _remote.paymentMethods())
            .map((dto) => dto.toDomain())
            .toList(),
      );

  @override
  Future<Result<UniversalNfcPayment>> createIntent({
    required double amount,
    required String currency,
    String? paymentMethodId,
    String? merchantName,
    int? merchantId,
    int? childProfileId,
    String? idempotencyKey,
  }) =>
      _guard(
        () async => (await _remote.createIntent(
          amount: amount,
          currency: currency,
          paymentMethodId: paymentMethodId,
          merchantName: merchantName,
          merchantId: merchantId,
          childProfileId: childProfileId,
          idempotencyKey: idempotencyKey,
        ))
            .toDomain(),
      );

  @override
  Future<Result<UniversalNfcPayment>> payment(String paymentIntentId) =>
      _guard(
        () async =>
            (await _remote.payment(paymentIntentId)).toDomain(),
      );

  @override
  Future<Result<UniversalNfcPayment>> confirm(String paymentIntentId) =>
      _guard(
        () async =>
            (await _remote.confirm(paymentIntentId)).toDomain(),
      );

  @override
  Future<Result<void>> cancel(String paymentIntentId) => _guard(
        () async => _remote.cancel(paymentIntentId),
      );

  @override
  Future<Result<List<KidsNfcParentApproval>>> kidsApprovals() => _guard(
        () async => (await _remote.kidsApprovals())
            .map((dto) => dto.toDomain())
            .toList(),
      );

  @override
  Future<Result<UniversalNfcPayment>> approveKidsPayment(
    String paymentIntentId,
  ) =>
      _guard(
        () async =>
            (await _remote.approveKidsPayment(paymentIntentId)).toDomain(),
      );

  @override
  Future<Result<UniversalNfcPayment>> rejectKidsPayment(
    String paymentIntentId, {
    String? reason,
  }) =>
      _guard(
        () async => (await _remote.rejectKidsPayment(
          paymentIntentId,
          reason: reason,
        ))
            .toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on DioException catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
