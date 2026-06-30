import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../../wallet/domain/entities/ciervo_wallet_identity.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._profileRepository, this._walletRepository)
      : super(const ProfileState());

  final ProfileRepository _profileRepository;
  final WalletRepository _walletRepository;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    final results = await Future.wait([
      _profileRepository.getMe(),
      _walletRepository.myCiervoId(),
    ]);
    final profileResult = results[0] as Result<UserProfile>;
    final ciervoIdResult = results[1] as Result<CiervoWalletIdentity>;

    profileResult.when(
      success: (profile) {
        final code = _resolveCiervoCode(
          profile.ciervoUserCode,
          ciervoIdResult,
        );
        final previousPhoto = state.profile?.photoUrl?.trim();
        final incomingPhoto = profile.photoUrl?.trim();
        final mergedProfile = (incomingPhoto != null && incomingPhoto.isNotEmpty)
            ? profile
            : (previousPhoto != null && previousPhoto.isNotEmpty)
                ? profile.copyWith(photoUrl: previousPhoto)
                : profile;
        emit(
          ProfileState(
            status: ProfileStatus.loaded,
            profile: mergedProfile,
            ciervoUserCode: code,
          ),
        );
      },
      failure: (error) {
        final code = _codeFromWalletOnly(ciervoIdResult);
        emit(
          state.copyWith(
            status: code == null ? ProfileStatus.failure : ProfileStatus.loaded,
            ciervoUserCode: code,
            errorMessage:
                code == null ? UserErrorMessage.from(error) : null,
          ),
        );
      },
    );
  }

  Future<void> refreshCiervoId() async {
    final result = await _walletRepository.myCiervoId();
    result.when(
      success: (identity) => emit(
        state.copyWith(ciervoUserCode: identity.ciervoUserCode),
      ),
      failure: (error) => emit(
        state.copyWith(errorMessage: UserErrorMessage.from(error)),
      ),
    );
  }

  String? _resolveCiervoCode(
    String? profileCode,
    Result<CiervoWalletIdentity> walletResult,
  ) {
    final fromProfile = profileCode?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return _codeFromWalletOnly(walletResult);
  }

  String? _codeFromWalletOnly(Result<CiervoWalletIdentity> walletResult) {
    return walletResult.when(
      success: (identity) {
        final code = identity.ciervoUserCode.trim();
        return code.isEmpty ? null : code;
      },
      failure: (_) => null,
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    final result = await _profileRepository.updateMe(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
    );

    result.when(
      success: (profile) => emit(
        ProfileState(
          status: ProfileStatus.saved,
          profile: profile,
          ciervoUserCode: state.ciervoUserCode ?? profile.ciervoUserCode,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> uploadPhoto({
    required String path,
    required String fileName,
  }) async {
    final current = state.profile;
    if (current == null) return;
    emit(state.copyWith(status: ProfileStatus.uploadingPhoto, clearError: true));
    final result = await _profileRepository.uploadPhoto(
      path: path,
      fileName: fileName,
    );
    result.when(
      success: (upload) {
        final photoRef = (upload.photoUrl != null && upload.photoUrl!.isNotEmpty)
            ? upload.photoUrl
            : upload.mediaId;
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          profile: current.copyWith(photoUrl: photoRef),
        ));
      },
      failure: (error) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: current,
        errorMessage: UserErrorMessage.from(error),
      )),
    );
  }
}