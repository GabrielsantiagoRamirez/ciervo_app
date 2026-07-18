import '../../../core/errors/error_mapper.dart';
import '../../../core/result/result.dart';
import '../domain/business_nfc_models.dart';
import 'business_nfc_remote_datasource.dart';

abstract interface class BusinessNfcRepository {
  Future<Result<BusinessNfcValidation>> validate(
    BusinessNfcValidateCommand command,
  );
  Future<Result<BusinessNfcCharge>> charge(BusinessNfcChargeCommand command);
}

class BusinessNfcRepositoryImpl implements BusinessNfcRepository {
  const BusinessNfcRepositoryImpl(this._remote);
  final BusinessNfcRemoteDataSource _remote;

  @override
  Future<Result<BusinessNfcValidation>> validate(
    BusinessNfcValidateCommand command,
  ) => _guard(() => _remote.validate(command));

  @override
  Future<Result<BusinessNfcCharge>> charge(BusinessNfcChargeCommand command) =>
      _guard(() => _remote.charge(command));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
