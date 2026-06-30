import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../payments/domain/entities/payment_intent.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../domain/entities/ciervo_wallet_identity.dart';
import '../../domain/entities/nfc_models.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/recharge_intent.dart';
import '../../domain/entities/resolved_wallet_user.dart';
import '../../domain/entities/transfer_result.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../dtos/payment_request_dto.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remoteDataSource, this._payments);

  final WalletRemoteDataSource _remoteDataSource;
  final PaymentsRepository _payments;

  @override
  Future<Result<List<WalletCard>>> cards() async {
    try {
      final cards = await _remoteDataSource.cards();
      return Success(cards.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<WalletCard>> cardDetail(String cardId) async {
    try {
      return Success((await _remoteDataSource.cardDetail(cardId)).toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<WalletTransaction>>> transactions(String cardId) async {
    try {
      final items = await _remoteDataSource.transactions(cardId);
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> setPrimary(String cardId) =>
      _void(() => _remoteDataSource.setPrimary(cardId));

  @override
  Future<Result<void>> block(String cardId) =>
      _void(() => _remoteDataSource.block(cardId));

  @override
  Future<Result<void>> unblock(String cardId) =>
      _void(() => _remoteDataSource.unblock(cardId));

  @override
  Future<Result<void>> delete(String cardId) =>
      _void(() => _remoteDataSource.delete(cardId));

  @override
  Future<Result<RechargeIntent>> createRechargeIntent({
    required String cardId,
    required double amount,
  }) async {
    final configResult = await _payments.config();
    final currency = configResult.when(
      success: (config) => config.currency,
      failure: (_) => 'COP',
    );
    final key = 'wallet-recharge-$cardId-${DateTime.now().microsecondsSinceEpoch}';
    final result = await _payments.createWalletRecharge(
      walletCardId: cardId,
      amount: amount,
      currency: currency,
      idempotencyKey: key,
    );
    return result.when(
      success: (intent) => Success(_mapIntent(intent)),
      failure: (error) => Failure(error),
    );
  }

  @override
  Future<Result<RechargeIntent>> rechargeIntent(String intentId) async {
    try {
      return Success(
        (await _remoteDataSource.rechargeIntent(intentId)).toDomain(),
      );
    } catch (walletError) {
      final result = await _payments.intent(intentId);
      return result.when(
        success: (intent) => Success(_mapIntent(intent)),
        failure: (_) => Failure(ErrorMapper.fromObject(walletError)),
      );
    }
  }

  @override
  Future<Result<CiervoWalletIdentity>> myCiervoId() async {
    try {
      final json = await _remoteDataSource.myCiervoId();
      final userId = '${json['userId'] ?? json['id'] ?? ''}'.trim();
      final code = _extractCiervoCode(json);
      if (code.isEmpty) {
        return Failure(ErrorMapper.fromObject('Ciervo ID no disponible.'));
      }
      return Success(
        CiervoWalletIdentity(
          userId: userId.isEmpty ? code : userId,
          ciervoUserCode: code,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  static String _extractCiervoCode(Map<String, dynamic> json) {
    for (final key in const [
      'ciervoUserCode',
      'CiervoUserCode',
      'userCode',
      'userPublicCode',
      'userCiervoCode',
    ]) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  @override
  Future<Result<Map<String, dynamic>>> mercadoPagoConfig() async {
    final result = await _payments.config();
    if (result case Success(value: final config)) {
      return Success({
        'provider': config.provider,
        'enabled': config.enabled,
        'isSandbox': config.isSandbox,
        'publicKey': config.publicKey,
        'currency': config.currency,
        'successUrl': config.successUrl,
        'failureUrl': config.failureUrl,
        'pendingUrl': config.pendingUrl,
      });
    }
    try {
      return Success(await _remoteDataSource.mercadoPagoConfig());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  RechargeIntent _mapIntent(PaymentIntent intent) => RechargeIntent(
        id: intent.id,
        checkoutUrl: intent.checkoutUrl,
        status: intent.status,
      );

  @override
  Future<Result<ResolvedWalletUser>> resolveUser(String ciervoUserCode) async {
    try {
      return Success(
        (await _remoteDataSource.resolveUser(ciervoUserCode)).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<TransferResult>> transfer({
    required String targetCiervoUserCode,
    required double amount,
    required String description,
    String? walletCardId,
  }) async {
    try {
      return Success(
        (await _remoteDataSource.transfer(
          targetCiervoUserCode: targetCiervoUserCode,
          amount: amount,
          description: description,
          walletCardId: walletCardId,
        )).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<PaymentRequest>> requestMoney({
    String? payerUserId,
    String? payerCiervoUserCode,
    required double amount,
    required String description,
  }) async {
    try {
      return Success(
        (await _remoteDataSource.requestMoney(
          payerUserId: payerUserId,
          payerCiervoUserCode: payerCiervoUserCode,
          amount: amount,
          description: description,
        )).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<RechargeIntent>> rechargeByCiervoId({
    required String targetCiervoUserCode,
    required double amount,
    String? description,
  }) async {
    try {
      final dto = await _remoteDataSource.rechargeByCiervoId(
        targetCiervoUserCode: targetCiervoUserCode,
        amount: amount,
        description: description,
      );
      return Success(dto.toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<PaymentRequest>>> paymentRequestsInbox() async {
    try {
      final items = await _remoteDataSource.paymentRequestsInbox();
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<PaymentRequest>>> paymentRequestsSent() async {
    try {
      final items = await _remoteDataSource.paymentRequestsSent();
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<PaymentRequest>> approvePaymentRequest(String id) =>
      _paymentRequest(() => _remoteDataSource.approvePaymentRequest(id));

  @override
  Future<Result<PaymentRequest>> rejectPaymentRequest(
    String id,
    String reason,
  ) =>
      _paymentRequest(() => _remoteDataSource.rejectPaymentRequest(id, reason));

  @override
  Future<Result<PaymentRequest>> cancelPaymentRequest(String id) =>
      _paymentRequest(() => _remoteDataSource.cancelPaymentRequest(id));

  @override
  Future<Result<NfcSession>> createNfcSession({
    required String walletCardId,
    required int businessId,
    required double amount,
    String currency = 'COP',
    String? description,
    int expirationSeconds = 60,
  }) async {
    try {
      final key =
          'nfc-$walletCardId-$businessId-${DateTime.now().microsecondsSinceEpoch}';
      final dto = await _remoteDataSource.createNfcSession(
        walletCardId: walletCardId,
        businessId: businessId,
        amount: amount,
        currency: currency,
        idempotencyKey: key,
        description: description,
        expirationSeconds: expirationSeconds,
      );
      return Success(dto.toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<NfcSession>> nfcSession(int sessionId) async {
    try {
      return Success((await _remoteDataSource.nfcSession(sessionId)).toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> cancelNfcSession(int sessionId) =>
      _void(() => _remoteDataSource.cancelNfcSession(sessionId));

  @override
  Future<Result<List<PhysicalNfcCard>>> physicalNfcCards() async {
    try {
      final items = await _remoteDataSource.physicalNfcCards();
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<PhysicalNfcCard>> registerPhysicalNfcCard({
    required String cardId,
    required String cardUid,
    required String label,
  }) async {
    try {
      final dto = await _remoteDataSource.registerPhysicalNfcCard(
        cardId: cardId,
        cardUid: cardUid,
        label: label,
      );
      return Success(dto.toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> blockPhysicalNfcCard(int id) =>
      _void(() => _remoteDataSource.blockPhysicalNfcCard(id));

  Future<Result<void>> _void(Future<void> Function() action) async {
    try {
      await action();
      return const Success<void>(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<PaymentRequest>> _paymentRequest(
    Future<PaymentRequestDto> Function() action,
  ) async {
    try {
      final dto = await action();
      return Success(dto.toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
