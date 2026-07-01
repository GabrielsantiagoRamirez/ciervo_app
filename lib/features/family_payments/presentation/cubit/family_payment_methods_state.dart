import '../../domain/entities/family_payment_card.dart';

enum FamilyPaymentMethodsStatus { initial, loading, success, failure }

class FamilyPaymentMethodsState {
  const FamilyPaymentMethodsState({
    this.status = FamilyPaymentMethodsStatus.initial,
    this.cards = const [],
    this.errorMessage,
    this.successMessage,
    this.actionCardId,
  });

  final FamilyPaymentMethodsStatus status;
  final List<FamilyPaymentCard> cards;
  final String? errorMessage;
  final String? successMessage;
  final String? actionCardId;

  FamilyPaymentMethodsState copyWith({
    FamilyPaymentMethodsStatus? status,
    List<FamilyPaymentCard>? cards,
    String? errorMessage,
    String? successMessage,
    String? actionCardId,
    bool clearMessages = false,
  }) {
    return FamilyPaymentMethodsState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearMessages ? null : successMessage ?? this.successMessage,
      actionCardId: actionCardId ?? this.actionCardId,
    );
  }
}
