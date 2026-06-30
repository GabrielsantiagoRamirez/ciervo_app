import '../../domain/entities/payment_request.dart';
import '../../domain/entities/recharge_intent.dart';
import '../../domain/entities/resolved_wallet_user.dart';
import '../../domain/entities/transfer_result.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/entities/wallet_transaction.dart';

enum WalletStatus { initial, loading, loaded, empty, failure, actionLoading }

class WalletState {
  const WalletState({
    this.status = WalletStatus.initial,
    this.cards = const [],
    this.selectedCard,
    this.transactions = const [],
    this.inboxRequests = const [],
    this.sentRequests = const [],
    this.resolvedUser,
    this.rechargeIntent,
    this.transferResult,
    this.ciervoUserCode,
    this.errorMessage,
    this.successMessage,
  });

  final WalletStatus status;
  final List<WalletCard> cards;
  final WalletCard? selectedCard;
  final List<WalletTransaction> transactions;
  final List<PaymentRequest> inboxRequests;
  final List<PaymentRequest> sentRequests;
  final ResolvedWalletUser? resolvedUser;
  final RechargeIntent? rechargeIntent;
  final TransferResult? transferResult;
  final String? ciervoUserCode;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading =>
      status == WalletStatus.loading || status == WalletStatus.actionLoading;

  WalletState copyWith({
    WalletStatus? status,
    List<WalletCard>? cards,
    WalletCard? selectedCard,
    List<WalletTransaction>? transactions,
    List<PaymentRequest>? inboxRequests,
    List<PaymentRequest>? sentRequests,
    ResolvedWalletUser? resolvedUser,
    RechargeIntent? rechargeIntent,
    TransferResult? transferResult,
    String? ciervoUserCode,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
    bool clearResolvedUser = false,
    bool clearRechargeIntent = false,
    bool clearTransferResult = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      selectedCard: selectedCard ?? this.selectedCard,
      transactions: transactions ?? this.transactions,
      inboxRequests: inboxRequests ?? this.inboxRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      resolvedUser: clearResolvedUser
          ? null
          : resolvedUser ?? this.resolvedUser,
      rechargeIntent: clearRechargeIntent
          ? null
          : rechargeIntent ?? this.rechargeIntent,
      transferResult: clearTransferResult
          ? null
          : transferResult ?? this.transferResult,
      ciervoUserCode: ciervoUserCode ?? this.ciervoUserCode,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}
