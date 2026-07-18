import 'dart:math';

import '../../../../core/country/country_registration.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/result/result.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
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
import '../models/wallet_recharge_session.dart';
import '../stores/wallet_recharge_session_store.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(
    this._remoteDataSource,
    this._profileRepository,
    this._rechargeStore, {
    AppLogger? logger,
    String Function()? uuid,
  }) : _logger = logger,
       _uuid = uuid ?? _uuidV4;

  final WalletRemoteDataSource _remoteDataSource;
  final ProfileRepository _profileRepository;
  final WalletRechargeSessionStore _rechargeStore;
  final AppLogger? _logger;
  final String Function() _uuid;

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
    String? currency,
  }) async {
    await _rechargeStore.clear();
    try {
      final profileResult = await _profileRepository.getMe();
      final profile = switch (profileResult) {
        Success(value: final value) => value,
        Failure(error: final error) => throw error,
      };
      final countryCode = (profile.countryCode ?? '').trim().toUpperCase();
      final resolvedCurrency = switch (countryCode) {
        'CL' => 'CLP',
        'CO' => 'COP',
        _ => throw const AppException(
          message: 'El país del perfil no admite recargas Wallet.',
          code: 'wallet_recharge_country_unsupported',
        ),
      };
      final idempotencyKey = _uuid();
      final dto = await _remoteDataSource.createRechargeIntent(
        cardId,
        amount,
        currency: resolvedCurrency,
        idempotencyKey: idempotencyKey,
        description: 'Recarga CIERVO Wallet',
      );
      final intent = dto.toDomain();
      if (!intent.isCheckoutHostAllowedFor(countryCode)) {
        throw const AppException(
          message: 'El checkout recibido no es válido para tu país.',
          code: 'wallet_recharge_invalid_checkout_host',
        );
      }
      await _rechargeStore.write(
        WalletRechargeSession(
          intentId: intent.id,
          preferenceId: intent.preferenceId,
          checkoutUrl: intent.checkoutUrl,
          currency: resolvedCurrency,
          countryCode: countryCode,
          idempotencyKey: idempotencyKey,
          amount: amount,
          cardId: cardId,
        ),
      );
      final checkoutHost = Uri.parse(intent.checkoutUrl).host.toLowerCase();
      _logger?.info(
        'Wallet recharge checkout created: intentId=${intent.id}, '
        'countryCode=$countryCode, currency=$resolvedCurrency, '
        'checkoutHost=$checkoutHost',
      );
      return Success(intent);
    } catch (error) {
      await _rechargeStore.clear();
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<String> resolveRechargeCurrency(String? preferred) async {
    final profileCountry = await _profileCountryCode();
    if (profileCountry == 'CL') return 'CLP';
    if (profileCountry == 'CO') return 'COP';
    final fromCard = preferred?.trim().toUpperCase();
    return fromCard == 'CLP' || fromCard == 'COP'
        ? fromCard!
        : CountryRegistration.currencyForCountry(
            CountryRegistration.defaultCountryCode(),
          );
  }

  Future<String?> _profileCountryCode() async {
    final result = await _profileRepository.getMe();
    return result.when(
      success: (profile) {
        final code = (profile.countryCode ?? '').trim().toUpperCase();
        return code.isEmpty ? null : code;
      },
      failure: (_) => null,
    );
  }

  @override
  Future<Result<RechargeIntent>> rechargeIntent(String intentId) async {
    try {
      return Success(
        (await _remoteDataSource.rechargeIntent(intentId)).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<RechargeIntent>> syncRechargeIntent(String intentId) async {
    try {
      return Success(
        (await _remoteDataSource.syncRechargeIntent(intentId)).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
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
          qrPayload: _optionalString(json['qrPayload']),
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

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  @override
  Future<Result<Map<String, dynamic>>> mercadoPagoConfig() async {
    try {
      return Success(await _remoteDataSource.mercadoPagoConfig());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

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
    String currency = 'COP',
  }) async {
    try {
      return Success(
        (await _remoteDataSource.transfer(
          targetCiervoUserCode: targetCiervoUserCode,
          amount: amount,
          description: description,
          walletCardId: walletCardId,
          currency: currency,
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
    String? chatConversationId,
    int? businessId,
    int? bookingId,
    String currency = 'COP',
  }) async {
    try {
      return Success(
        (await _remoteDataSource.requestMoney(
          payerUserId: payerUserId,
          payerCiervoUserCode: payerCiervoUserCode,
          amount: amount,
          description: description,
          chatConversationId: chatConversationId,
          businessId: businessId,
          bookingId: bookingId,
          currency: currency,
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
    String currency = 'COP',
  }) async {
    try {
      final dto = await _remoteDataSource.rechargeByCiervoId(
        targetCiervoUserCode: targetCiervoUserCode,
        amount: amount,
        description: description,
        currency: currency,
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
  Future<Result<PaymentRequest>> approvePaymentRequest(
    String id, {
    bool useBackupCard = false,
    String? familyPaymentCardId,
  }) => _paymentRequest(
    () => _remoteDataSource.approvePaymentRequest(
      id,
      useBackupCard: useBackupCard,
      familyPaymentCardId: familyPaymentCardId,
    ),
  );

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
      return Success(
        (await _remoteDataSource.nfcSession(sessionId)).toDomain(),
      );
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
    String? countryCode,
  }) async {
    try {
      final dto = await _remoteDataSource.registerPhysicalNfcCard(
        cardId: cardId,
        cardUid: cardUid,
        label: label,
        countryCode: countryCode,
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
