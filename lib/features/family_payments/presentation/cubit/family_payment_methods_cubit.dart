import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../domain/repositories/family_payments_repository.dart';
import 'family_payment_methods_state.dart';

class FamilyPaymentMethodsCubit extends Cubit<FamilyPaymentMethodsState> {
  FamilyPaymentMethodsCubit(this._repository)
      : super(const FamilyPaymentMethodsState());

  final FamilyPaymentsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(
      status: FamilyPaymentMethodsStatus.loading,
      clearMessages: true,
    ));
    final result = await _repository.listCards();
    result.when(
      success: (cards) => emit(state.copyWith(
        status: FamilyPaymentMethodsStatus.success,
        cards: cards,
      )),
      failure: (error) => emit(state.copyWith(
        status: FamilyPaymentMethodsStatus.failure,
        errorMessage: UserErrorMessage.from(error),
      )),
    );
  }

  Future<void> deleteCard(String cardId) async {
    emit(state.copyWith(actionCardId: cardId, clearMessages: true));
    final result = await _repository.deleteCard(cardId);
    result.when(
      success: (_) async {
        emit(state.copyWith(
          successMessage: 'Tarjeta eliminada.',
          actionCardId: null,
        ));
        await load();
      },
      failure: (error) => emit(state.copyWith(
        errorMessage: UserErrorMessage.from(error),
        actionCardId: null,
      )),
    );
  }

  Future<void> setPrimary(String cardId) async {
    emit(state.copyWith(actionCardId: cardId, clearMessages: true));
    final result = await _repository.setPrimaryCard(cardId);
    result.when(
      success: (_) async {
        emit(state.copyWith(
          successMessage: 'Tarjeta principal actualizada.',
          actionCardId: null,
        ));
        await load();
      },
      failure: (error) => emit(state.copyWith(
        errorMessage: UserErrorMessage.from(error),
        actionCardId: null,
      )),
    );
  }

  Future<void> setBackup(String cardId) async {
    emit(state.copyWith(actionCardId: cardId, clearMessages: true));
    final result = await _repository.setBackupCard(cardId);
    result.when(
      success: (_) async {
        emit(state.copyWith(
          successMessage: 'Tarjeta de respaldo actualizada.',
          actionCardId: null,
        ));
        await load();
      },
      failure: (error) => emit(state.copyWith(
        errorMessage: UserErrorMessage.from(error),
        actionCardId: null,
      )),
    );
  }

  Future<void> freeze(String cardId) async {
    emit(state.copyWith(actionCardId: cardId, clearMessages: true));
    final result = await _repository.freezeCard(cardId);
    result.when(
      success: (_) async {
        emit(state.copyWith(
          successMessage: 'Tarjeta congelada.',
          actionCardId: null,
        ));
        await load();
      },
      failure: (error) => emit(state.copyWith(
        errorMessage: UserErrorMessage.from(error),
        actionCardId: null,
      )),
    );
  }

  Future<void> unfreeze(String cardId) async {
    emit(state.copyWith(actionCardId: cardId, clearMessages: true));
    final result = await _repository.unfreezeCard(cardId);
    result.when(
      success: (_) async {
        emit(state.copyWith(
          successMessage: 'Tarjeta descongelada.',
          actionCardId: null,
        ));
        await load();
      },
      failure: (error) => emit(state.copyWith(
        errorMessage: UserErrorMessage.from(error),
        actionCardId: null,
      )),
    );
  }

  Future<bool> updateAlias({
    required String cardId,
    required String alias,
  }) async {
    emit(state.copyWith(actionCardId: cardId, clearMessages: true));
    final result = await _repository.updateCardAlias(cardId: cardId, alias: alias);
    return result.when(
      success: (_) async {
        emit(state.copyWith(
          successMessage: 'Alias actualizado.',
          actionCardId: null,
        ));
        await load();
        return true;
      },
      failure: (error) {
        emit(state.copyWith(
          errorMessage: UserErrorMessage.from(error),
          actionCardId: null,
        ));
        return false;
      },
    );
  }

  Future<AddCardFlowResult> addCard({
    required String cardToken,
    String? alias,
  }) async {
    final result = await _repository.addCard(
      cardToken: cardToken,
      alias: alias,
      idempotencyKey: IdempotencyKey.generate('family-card'),
    );
    return result.when(
      success: (payload) => AddCardFlowResult(
        cardId: payload.card.id,
        requires3ds: payload.requires3ds,
        verificationUrl: payload.verificationUrl,
      ),
      failure: (error) => throw UserErrorMessage.from(error),
    );
  }

  Future<bool> verifyCard(String cardId) async {
    final result = await _repository.verifyCard(cardId);
    return result.when(
      success: (_) async {
        await load();
        return true;
      },
      failure: (error) {
        emit(state.copyWith(errorMessage: UserErrorMessage.from(error)));
        return false;
      },
    );
  }
}

class AddCardFlowResult {
  const AddCardFlowResult({
    required this.cardId,
    required this.requires3ds,
    this.verificationUrl,
  });

  final String cardId;
  final bool requires3ds;
  final String? verificationUrl;
}
