import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/payment_config.dart';
import '../../domain/entities/payment_history_item.dart';
import '../../domain/entities/payment_intent.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_datasource.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  const PaymentsRepositoryImpl(this._remote);

  final PaymentsRemoteDataSource _remote;

  @override
  Future<Result<PaymentConfig>> config() => _guard(
        () async => (await _remote.config()).toDomain(),
      );

  @override
  Future<Result<PaymentIntent>> createWalletRecharge({
    required String walletCardId,
    required double amount,
    required String currency,
    required String idempotencyKey,
  }) => _guard(() async {
        final parsedCard = int.tryParse(walletCardId);
        try {
          return (await _remote.createIntent({
            'type': 'wallet_recharge',
            'amount': amount,
            'currency': currency,
            'walletCardId': parsedCard ?? walletCardId,
            'idempotencyKey': idempotencyKey,
          })).toDomain();
        } catch (_) {
          return (await _remote.legacyWalletRecharge(
            walletCardId: walletCardId,
            amount: amount,
            idempotencyKey: idempotencyKey,
          ))
              .toDomain();
        }
      });

  @override
  Future<Result<PaymentIntent>> createDeliveryPayment({
    required String deliveryOrderId,
    required String idempotencyKey,
  }) => _guard(
        () async => (await _remote.createIntent({
          'type': 'delivery_order',
          'deliveryOrderId': int.tryParse(deliveryOrderId) ?? deliveryOrderId,
          'idempotencyKey': idempotencyKey,
        })).toDomain(),
      );

  @override
  Future<Result<PaymentIntent>> createMembershipSubscribeIntent({
    required String membershipPlanId,
    required String idempotencyKey,
  }) => _guard(
        () async => (await _remote.membershipSubscribeIntent(
          membershipPlanId: membershipPlanId,
          idempotencyKey: idempotencyKey,
        )).toDomain(),
      );

  @override
  Future<Result<PaymentIntent>> intent(String id) => _guard(
        () async => (await _remote.intent(id)).toDomain(),
      );

  @override
  Future<Result<PaymentIntent>> pollIntent(
    String id, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 20,
  }) async {
    PaymentIntent? last;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final result = await intent(id);
      result.when(
        success: (intent) => last = intent,
        failure: (_) {},
      );
      if (last?.isTerminal == true) return Success(last!);
      await Future<void>.delayed(interval);
    }
    if (last != null) return Success(last!);
    return Failure(ErrorMapper.fromObject('No se pudo confirmar el pago.'));
  }

  @override
  Future<Result<List<PaymentHistoryItem>>> myPayments({
    String? type,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) => _guard(
        () async => (await _remote.myPayments(
          type: type,
          status: status,
          page: page,
          pageSize: pageSize,
        ))
            .map((item) => item.toDomain())
            .toList(),
      );

  @override
  Future<Result<PaymentHistoryItem>> myPayment(String id) => _guard(
        () async => (await _remote.myPayment(id)).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
