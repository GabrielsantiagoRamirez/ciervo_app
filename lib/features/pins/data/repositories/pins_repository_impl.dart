import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/ciervo_pin.dart';
import '../../domain/repositories/pins_repository.dart';
import '../datasources/pins_remote_datasource.dart';

class PinsRepositoryImpl implements PinsRepository {
  const PinsRepositoryImpl(this._remoteDataSource);

  final PinsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<CiervoPin>> createPin({
    required String walletCardId,
    required String businessId,
    required double amount,
    bool kidsMode = false,
    bool requireParentApproval = false,
    String? childProfileId,
    String? childWalletCardId,
  }) async {
    try {
      final dto = await _remoteDataSource.createPin(
        walletCardId: walletCardId,
        businessId: businessId,
        amount: amount,
        kidsMode: kidsMode,
        requireParentApproval: requireParentApproval,
        childProfileId: childProfileId,
        childWalletCardId: childWalletCardId,
      );
      final revealedPin = dto.pin;
      return Success(dto.toDomain(revealedPin: revealedPin));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<CiervoPin>>> myPins({bool activeOnly = true}) async {
    try {
      final items = await _remoteDataSource.myPins(activeOnly: activeOnly);
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<CiervoPin>> pin(String id) async {
    try {
      return Success((await _remoteDataSource.pin(id)).toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<CiervoPin>> cancelPin(String id) async {
    try {
      return Success((await _remoteDataSource.cancelPin(id)).toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
