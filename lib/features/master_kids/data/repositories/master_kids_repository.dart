import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../kids_v2/domain/models/kids_v2_models.dart';
import '../../domain/models/master_kids_models.dart';
import '../datasources/master_kids_remote_datasource.dart';

abstract interface class MasterKidsRepository {
  Future<Result<List<PaymentRequest>>> pendingPaymentRequests();
  Future<Result<PaymentTokenIssued>> approvePaymentRequest(int id);
  Future<Result<void>> rejectPaymentRequest(int id, {String? reason});
  Future<Result<void>> acceptReservationPolicy(
    AcceptReservationPolicyCommand command,
  );
  Future<Result<PaymentTokenIssued>> createPaymentToken(
    PaymentTokenCreateCommand command,
  );
  Future<Result<PaymentTokenValidation>> validatePaymentToken(
    PaymentTokenValidateCommand command,
  );
  Future<Result<KidsBusinessPayment>> executePayment(
    PaymentExecuteCommand command,
  );
  Future<Result<List<KidDeviceRegistration>>> devices(int kidId);
  Future<Result<KidDeviceRegistration>> registerDevice(
    int kidId,
    RegisterKidDeviceCommand command,
  );
  Future<Result<void>> approveDevice(int kidId, int registrationId);
  Future<Result<void>> revokeDevice(int kidId, int registrationId);
  Future<Result<KidProfile>> createKid(CreateKidCommand command);
  Future<Result<Json>> createKidAccount(
    int kidId,
    CreateKidAccountCommand command,
  );
  Future<Result<Json>> updateLimits(
    int kidId,
    ChildSpendingLimitCommand command,
  );
  Future<Result<Json>> updateSchedule(
    int kidId,
    KidSpendingScheduleCommand command,
  );
  Future<Result<Json>> updateCategories(
    int kidId,
    KidCategoriesCommand command,
  );
  Future<Result<Json>> addGeofence(int kidId, KidGeofenceCommand command);
  Future<Result<KidRulesSnapshot>> rules(int kidId);
  Future<Result<Json>> addMerchant(int kidId, KidRuleMerchantCommand command);
  Future<Result<void>> removeMerchant(int kidId, int merchantId);
  Future<Result<Json>> updateGeofence(
    int kidId,
    int geofenceId,
    KidGeofenceCommand command,
  );
  Future<Result<void>> removeGeofence(int kidId, int geofenceId);
  Future<Result<Json>> addCountry(int kidId, KidRuleCountryCommand command);
  Future<Result<void>> removeCountry(int kidId, String countryCode);
  Future<Result<Json>> blockMerchant(int kidId, KidRuleMerchantCommand command);
  Future<Result<void>> unblockMerchant(int kidId, int merchantId);
  Future<Result<KidLocation>> postLocation(
    int kidId,
    KidLocationCommand command,
  );
  Future<Result<KidLocation>> location(int kidId);
  Future<Result<List<KidLocation>>> locationHistory(int kidId, {int take});
  Future<Result<Json>> addSecondaryAdmin(
    int kidId,
    SecondaryAdminCommand command,
  );
  Future<Result<void>> removeSecondaryAdmin(int kidId, int secondaryUserId);
  Future<Result<void>> blockAll(KidsSecurityActionCommand command);
  Future<Result<void>> unblockAll(KidsSecurityActionCommand command);
  Future<Result<void>> resetAttempts(int kidId);
  Future<Result<List<SecurityAttempt>>> attempts(int kidId);
  Future<Result<void>> enableNfc(int kidId, String physicalCardId);
  Future<Result<void>> disableNfc(int kidId, String physicalCardId);
  Future<Result<MasterDashboard>> dashboard();
  Future<Result<KidAuditPage>> audit({int? kidId, int page, int pageSize});
  Future<Result<AuditExport>> exportAudit({int? kidId});
}

class MasterKidsRepositoryImpl implements MasterKidsRepository {
  const MasterKidsRepositoryImpl(this._remote);
  final MasterKidsRemoteDataSource _remote;

  @override
  Future<Result<List<PaymentRequest>>> pendingPaymentRequests() =>
      _guard(_remote.pendingPaymentRequests);
  @override
  Future<Result<PaymentTokenIssued>> approvePaymentRequest(int id) =>
      _guard(() => _remote.approvePaymentRequest(id));
  @override
  Future<Result<void>> rejectPaymentRequest(int id, {String? reason}) =>
      _guard(() => _remote.rejectPaymentRequest(id, reason: reason));
  @override
  Future<Result<void>> acceptReservationPolicy(
    AcceptReservationPolicyCommand command,
  ) => _guard(() => _remote.acceptReservationPolicy(command));
  @override
  Future<Result<PaymentTokenIssued>> createPaymentToken(
    PaymentTokenCreateCommand command,
  ) => _guard(() => _remote.createPaymentToken(command));
  @override
  Future<Result<PaymentTokenValidation>> validatePaymentToken(
    PaymentTokenValidateCommand command,
  ) => _guard(() => _remote.validatePaymentToken(command));
  @override
  Future<Result<KidsBusinessPayment>> executePayment(
    PaymentExecuteCommand command,
  ) => _guard(() => _remote.executePayment(command));
  @override
  Future<Result<List<KidDeviceRegistration>>> devices(int kidId) =>
      _guard(() => _remote.devices(kidId));
  @override
  Future<Result<KidDeviceRegistration>> registerDevice(
    int kidId,
    RegisterKidDeviceCommand command,
  ) => _guard(() => _remote.registerDevice(kidId, command));
  @override
  Future<Result<void>> approveDevice(int kidId, int registrationId) =>
      _guard(() => _remote.approveDevice(kidId, registrationId));
  @override
  Future<Result<void>> revokeDevice(int kidId, int registrationId) =>
      _guard(() => _remote.revokeDevice(kidId, registrationId));
  @override
  Future<Result<KidProfile>> createKid(CreateKidCommand command) =>
      _guard(() => _remote.createKid(command));
  @override
  Future<Result<Json>> createKidAccount(
    int kidId,
    CreateKidAccountCommand command,
  ) => _guard(() => _remote.createKidAccount(kidId, command));
  @override
  Future<Result<Json>> updateLimits(
    int kidId,
    ChildSpendingLimitCommand command,
  ) => _guard(() => _remote.updateLimits(kidId, command));
  @override
  Future<Result<Json>> updateSchedule(
    int kidId,
    KidSpendingScheduleCommand command,
  ) => _guard(() => _remote.updateSchedule(kidId, command));
  @override
  Future<Result<Json>> updateCategories(
    int kidId,
    KidCategoriesCommand command,
  ) => _guard(() => _remote.updateCategories(kidId, command));
  @override
  Future<Result<Json>> addGeofence(int kidId, KidGeofenceCommand command) =>
      _guard(() => _remote.addGeofence(kidId, command));
  @override
  Future<Result<KidRulesSnapshot>> rules(int kidId) =>
      _guard(() => _remote.rules(kidId));
  @override
  Future<Result<Json>> addMerchant(int kidId, KidRuleMerchantCommand command) =>
      _guard(() => _remote.addMerchant(kidId, command));
  @override
  Future<Result<void>> removeMerchant(int kidId, int merchantId) =>
      _guard(() => _remote.removeMerchant(kidId, merchantId));
  @override
  Future<Result<Json>> updateGeofence(
    int kidId,
    int geofenceId,
    KidGeofenceCommand command,
  ) => _guard(() => _remote.updateGeofence(kidId, geofenceId, command));
  @override
  Future<Result<void>> removeGeofence(int kidId, int geofenceId) =>
      _guard(() => _remote.removeGeofence(kidId, geofenceId));
  @override
  Future<Result<Json>> addCountry(int kidId, KidRuleCountryCommand command) =>
      _guard(() => _remote.addCountry(kidId, command));
  @override
  Future<Result<void>> removeCountry(int kidId, String countryCode) =>
      _guard(() => _remote.removeCountry(kidId, countryCode));
  @override
  Future<Result<Json>> blockMerchant(
    int kidId,
    KidRuleMerchantCommand command,
  ) => _guard(() => _remote.blockMerchant(kidId, command));
  @override
  Future<Result<void>> unblockMerchant(int kidId, int merchantId) =>
      _guard(() => _remote.unblockMerchant(kidId, merchantId));
  @override
  Future<Result<KidLocation>> postLocation(
    int kidId,
    KidLocationCommand command,
  ) => _guard(() => _remote.postLocation(kidId, command));
  @override
  Future<Result<KidLocation>> location(int kidId) =>
      _guard(() => _remote.location(kidId));
  @override
  Future<Result<List<KidLocation>>> locationHistory(
    int kidId, {
    int take = 50,
  }) => _guard(() => _remote.locationHistory(kidId, take: take));
  @override
  Future<Result<Json>> addSecondaryAdmin(
    int kidId,
    SecondaryAdminCommand command,
  ) => _guard(() => _remote.addSecondaryAdmin(kidId, command));
  @override
  Future<Result<void>> removeSecondaryAdmin(int kidId, int secondaryUserId) =>
      _guard(() => _remote.removeSecondaryAdmin(kidId, secondaryUserId));
  @override
  Future<Result<void>> blockAll(KidsSecurityActionCommand command) =>
      _guard(() => _remote.blockAll(command));
  @override
  Future<Result<void>> unblockAll(KidsSecurityActionCommand command) =>
      _guard(() => _remote.unblockAll(command));
  @override
  Future<Result<void>> resetAttempts(int kidId) =>
      _guard(() => _remote.resetAttempts(kidId));
  @override
  Future<Result<List<SecurityAttempt>>> attempts(int kidId) =>
      _guard(() => _remote.attempts(kidId));
  @override
  Future<Result<void>> enableNfc(int kidId, String physicalCardId) =>
      _guard(() => _remote.enableNfc(kidId, physicalCardId));
  @override
  Future<Result<void>> disableNfc(int kidId, String physicalCardId) =>
      _guard(() => _remote.disableNfc(kidId, physicalCardId));
  @override
  Future<Result<MasterDashboard>> dashboard() => _guard(_remote.dashboard);
  @override
  Future<Result<KidAuditPage>> audit({
    int? kidId,
    int page = 1,
    int pageSize = 50,
  }) =>
      _guard(() => _remote.audit(kidId: kidId, page: page, pageSize: pageSize));
  @override
  Future<Result<AuditExport>> exportAudit({int? kidId}) =>
      _guard(() => _remote.exportAudit(kidId: kidId));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
