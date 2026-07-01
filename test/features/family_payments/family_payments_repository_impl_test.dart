import 'package:flutter_test/flutter_test.dart';

import 'package:ciervo_clud/core/result/result.dart';
import 'package:ciervo_clud/features/family_payments/data/datasources/family_payments_remote_datasource.dart';
import 'package:ciervo_clud/features/family_payments/data/dtos/family_payment_dtos.dart';
import 'package:ciervo_clud/features/family_payments/data/repositories/family_payments_repository_impl.dart';

class _FakeFamilyPaymentsRemoteDataSource
    implements FamilyPaymentsRemoteDataSource {
  _FakeFamilyPaymentsRemoteDataSource({this.throwOnList = false});

  final bool throwOnList;

  @override
  Future<List<FamilyPaymentCardDto>> listCards() async {
    if (throwOnList) {
      throw Exception('offline');
    }
    return [
      FamilyPaymentCardDto.fromJson({
        'id': '7',
        'brand': 'master',
        'lastFour': '9999',
        'status': 'active',
        'isPrimary': true,
      }),
    ];
  }

  @override
  Future<AddFamilyCardResponseDto> addCard({
    required String cardToken,
    String? alias,
    required String idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> approvePayment(String paymentId) => throw UnimplementedError();

  @override
  Future<void> deleteCard(String cardId) async {}

  @override
  Future<FamilyPaymentCardDto> freezeCard(String cardId) =>
      throw UnimplementedError();

  @override
  Future<KidApprovalRulesDto> kidApprovalRules(String kidId) =>
      throw UnimplementedError();

  @override
  Future<KidAutoPaymentRulesDto> kidAutoPayment(String kidId) =>
      throw UnimplementedError();

  @override
  Future<KidGeofenceRulesDto> kidGeofence(String kidId) =>
      throw UnimplementedError();

  @override
  Future<KidSpendingLimitsDto> kidLimits(String kidId) =>
      throw UnimplementedError();

  @override
  Future<KidMerchantRulesDto> kidMerchantRules(String kidId) =>
      throw UnimplementedError();

  @override
  Future<KidPaymentSourceDto> kidPaymentSource(String kidId) =>
      throw UnimplementedError();

  @override
  Future<List<FamilyPaymentRecordDto>> kidPayments(
    String kidId, {
    int page = 1,
    int pageSize = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<KidScheduleRulesDto> kidSchedule(String kidId) =>
      throw UnimplementedError();

  @override
  Future<FamilyPaymentRecordDto> paymentDetail(String paymentId) =>
      throw UnimplementedError();

  @override
  Future<PendingParentPaymentDto> pendingParentPayment(String paymentId) =>
      throw UnimplementedError();

  @override
  Future<List<FamilyPaymentRecordDto>> parentPayments({
    DateTime? from,
    DateTime? to,
    String? kidId,
    String? status,
    String? merchantQuery,
    String? cardId,
    int page = 1,
    int pageSize = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> rejectPayment(String paymentId, {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<KidApprovalRulesDto> saveKidApprovalRules(
    String kidId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<KidAutoPaymentRulesDto> saveKidAutoPayment(
    String kidId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<KidGeofenceRulesDto> saveKidGeofence(
    String kidId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<KidSpendingLimitsDto> saveKidLimits(
    String kidId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<KidMerchantRulesDto> saveKidMerchantRules(
    String kidId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<KidPaymentSourceDto> saveKidPaymentSource(
    String kidId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<KidScheduleRulesDto> saveKidSchedule(
    String kidId,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<FamilyPaymentCardDto> unfreezeCard(String cardId) =>
      throw UnimplementedError();

  @override
  Future<FamilyPaymentCardDto> updateCard({
    required String cardId,
    String? alias,
    bool? isPrimary,
    bool? isBackup,
  }) =>
      throw UnimplementedError();

  @override
  Future<FamilyPaymentCardDto> verifyCard(String cardId) =>
      throw UnimplementedError();
}

void main() {
  group('FamilyPaymentsRepositoryImpl', () {
    test('listCards retorna tarjetas del datasource', () async {
      final repository = FamilyPaymentsRepositoryImpl(
        _FakeFamilyPaymentsRemoteDataSource(),
      );

      final result = await repository.listCards();
      expect(result, isA<Success<List<dynamic>>>());
      result.when(
        success: (cards) {
          expect(cards, hasLength(1));
          expect(cards.first.id, '7');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('listCards retorna failure offline', () async {
      final repository = FamilyPaymentsRepositoryImpl(
        _FakeFamilyPaymentsRemoteDataSource(throwOnList: true),
      );

      final result = await repository.listCards();
      expect(result, isA<Failure>());
    });
  });
}
