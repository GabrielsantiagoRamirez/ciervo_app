import '../../../../core/result/result.dart';
import '../entities/ciervo_pin.dart';

abstract interface class PinsRepository {
  Future<Result<CiervoPin>> createPin({
    required String walletCardId,
    required String businessId,
    required double amount,
    bool kidsMode = false,
    bool requireParentApproval = false,
  });

  Future<Result<List<CiervoPin>>> myPins({bool activeOnly = true});

  Future<Result<CiervoPin>> pin(String id);

  Future<Result<CiervoPin>> cancelPin(String id);
}
