import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/recharge_intent.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repository) : super(const WalletState());

  final WalletRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: WalletStatus.loading, clearMessages: true));
    final result = await _repository.cards();
    await result.when(
      success: (cards) async {
        final selected = cards.isEmpty
            ? null
            : cards.firstWhere(
                (card) => card.isPrimary,
                orElse: () => cards.first,
              );
        emit(
          state.copyWith(
            status: cards.isEmpty ? WalletStatus.empty : WalletStatus.loaded,
            cards: cards,
            selectedCard: selected,
          ),
        );
        await loadPaymentRequests();
        if (selected != null) await selectCard(selected);
      },
      failure: (error) async => emit(
        state.copyWith(
          status: WalletStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> selectCard(WalletCard card) async {
    emit(state.copyWith(selectedCard: card, status: WalletStatus.loading));
    final result = await _repository.transactions(card.id);
    result.when(
      success: (transactions) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          selectedCard: card,
          transactions: transactions,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> setPrimary(String cardId) => _cardAction(
    () => _repository.setPrimary(cardId),
    'Tarjeta principal actualizada.',
  );

  Future<void> block(String cardId) =>
      _cardAction(() => _repository.block(cardId), 'Tarjeta bloqueada.');

  Future<void> unblock(String cardId) =>
      _cardAction(() => _repository.unblock(cardId), 'Tarjeta desbloqueada.');

  Future<void> delete(String cardId) =>
      _cardAction(() => _repository.delete(cardId), 'Tarjeta eliminada.');

  Future<void> pollRechargeIntent(String intentId) async {
    emit(state.copyWith(status: WalletStatus.actionLoading, clearMessages: true));
    final result = await getIt<PaymentsRepository>().pollIntent(intentId);
    result.when(
      success: (intent) {
        final mapped = RechargeIntent(
          id: intent.id,
          checkoutUrl: intent.checkoutUrl,
          status: intent.status,
        );
        emit(
          state.copyWith(
            status: WalletStatus.loaded,
            rechargeIntent: mapped,
            successMessage: mapped.isSucceeded
                ? 'Recarga acreditada correctamente.'
                : mapped.isRejected
                ? 'Pago rechazado. Intenta nuevamente.'
                : 'Estado de recarga: ${mapped.statusLabel}',
          ),
        );
        if (mapped.isSucceeded) load();
      },
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> createRechargeIntent(String cardId, double amount) async {
    emit(
      state.copyWith(
        status: WalletStatus.actionLoading,
        clearMessages: true,
        clearRechargeIntent: true,
      ),
    );
    final configResult = await _repository.mercadoPagoConfig();
    final configOk = configResult.when(
      success: (config) => config['enabled'] != false,
      failure: (_) => true,
    );
    if (!configOk) {
      emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: 'Mercado Pago no esta habilitado en este momento.',
        ),
      );
      return;
    }
    final result = await _repository.createRechargeIntent(
      cardId: cardId,
      amount: amount,
    );
    result.when(
      success: (intent) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          rechargeIntent: intent,
          successMessage: 'Recarga creada. Completa el pago en Mercado Pago.',
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> resolveUser(String code) async {
    emit(
      state.copyWith(
        status: WalletStatus.actionLoading,
        clearMessages: true,
        clearResolvedUser: true,
      ),
    );
    final result = await _repository.resolveUser(code);
    result.when(
      success: (user) =>
          emit(state.copyWith(status: WalletStatus.loaded, resolvedUser: user)),
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> transfer({
    required String targetCiervoUserCode,
    required double amount,
    required String description,
    String? walletCardId,
  }) async {
    emit(
      state.copyWith(
        status: WalletStatus.actionLoading,
        clearMessages: true,
        clearTransferResult: true,
      ),
    );
    final result = await _repository.transfer(
      targetCiervoUserCode: targetCiervoUserCode,
      amount: amount,
      description: description,
      walletCardId: walletCardId,
    );
    result.when(
      success: (transfer) {
        emit(
          state.copyWith(
            status: WalletStatus.loaded,
            transferResult: transfer,
            successMessage: 'Transferencia realizada.',
          ),
        );
        load();
      },
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> requestMoney({
    String? payerUserId,
    String? payerCiervoUserCode,
    required double amount,
    required String description,
  }) async {
    emit(
      state.copyWith(status: WalletStatus.actionLoading, clearMessages: true),
    );
    final result = await _repository.requestMoney(
      payerUserId: payerUserId,
      payerCiervoUserCode: payerCiervoUserCode,
      amount: amount,
      description: description,
    );
    result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: WalletStatus.loaded,
            successMessage: 'Solicitud enviada.',
          ),
        );
        loadPaymentRequests();
      },
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> loadPaymentRequests() async {
    final inbox = await _repository.paymentRequestsInbox();
    final sent = await _repository.paymentRequestsSent();
    inbox.when(
      success: (items) => emit(state.copyWith(inboxRequests: items)),
      failure: (error) =>
          emit(state.copyWith(errorMessage: UserErrorMessage.from(error))),
    );
    sent.when(
      success: (items) => emit(state.copyWith(sentRequests: items)),
      failure: (error) =>
          emit(state.copyWith(errorMessage: UserErrorMessage.from(error))),
    );
  }

  Future<void> approvePaymentRequest(String id) => _paymentRequestAction(
    () => _repository.approvePaymentRequest(id),
    'Solicitud aprobada.',
  );

  Future<void> rejectPaymentRequest(String id, String reason) =>
      _paymentRequestAction(
        () => _repository.rejectPaymentRequest(id, reason),
        'Solicitud rechazada.',
      );

  Future<void> cancelPaymentRequest(String id) => _paymentRequestAction(
    () => _repository.cancelPaymentRequest(id),
    'Solicitud cancelada.',
  );

  Future<void> rechargeByCiervoId({
    required String targetCiervoUserCode,
    required double amount,
    String? description,
  }) async {
    emit(
      state.copyWith(
        status: WalletStatus.actionLoading,
        clearMessages: true,
        clearRechargeIntent: true,
      ),
    );
    final result = await _repository.rechargeByCiervoId(
      targetCiervoUserCode: targetCiervoUserCode,
      amount: amount,
      description: description,
    );
    result.when(
      success: (intent) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          rechargeIntent: intent,
          successMessage: 'Recarga creada. Completa el pago en Mercado Pago.',
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> _cardAction(
    Future<Result<void>> Function() action,
    String successMessage,
  ) async {
    emit(
      state.copyWith(status: WalletStatus.actionLoading, clearMessages: true),
    );
    final result = await action();
    result.when(
      success: (_) {
        emit(state.copyWith(successMessage: successMessage));
        load();
      },
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> _paymentRequestAction(
    Future<Result<dynamic>> Function() action,
    String successMessage,
  ) async {
    emit(
      state.copyWith(status: WalletStatus.actionLoading, clearMessages: true),
    );
    final result = await action();
    result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: WalletStatus.loaded,
            successMessage: successMessage,
          ),
        );
        loadPaymentRequests();
      },
      failure: (error) => emit(
        state.copyWith(
          status: WalletStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }
}
