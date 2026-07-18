import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../data/repositories/kids_v2_repositories.dart';
import '../../domain/models/kids_v2_models.dart';

class KidsShieldState {
  const KidsShieldState({
    required this.paymentSessionId,
    required this.decision,
    this.attemptRegistered = false,
    this.message,
  });

  final String paymentSessionId;
  final ShieldDecision decision;
  final bool attemptRegistered;
  final String? message;

  bool get rejected => !decision.allowed && !decision.requiresApproval;
}

class KidsShieldController {
  const KidsShieldController(this._repository);

  final KidsRepository _repository;

  Future<Result<KidsShieldState>> validate(String paymentSessionId) async {
    final result = await _repository.validateShield(
      KidsRulesValidateRequest(paymentSessionId),
    );
    return result.when(
      success: (decision) async {
        if (decision.allowed || decision.requiresApproval) {
          return Success(
            KidsShieldState(
              paymentSessionId: paymentSessionId,
              decision: decision,
            ),
          );
        }

        final attempt = await _repository.registerSecurityAttempt(
          KidSecurityAttemptRequest(
            resourceId: paymentSessionId,
            reasonCode: decision.ruleMatched ?? decision.reason,
          ),
        );
        return attempt.when(
          success: (_) => Success(
            KidsShieldState(
              paymentSessionId: paymentSessionId,
              decision: decision,
              attemptRegistered: true,
            ),
          ),
          failure: (error) => Success(
            KidsShieldState(
              paymentSessionId: paymentSessionId,
              decision: decision,
              message:
                  'La operación fue rechazada. ${UserErrorMessage.from(error)}',
            ),
          ),
        );
      },
      failure: (error) async => Failure(error),
    );
  }
}
