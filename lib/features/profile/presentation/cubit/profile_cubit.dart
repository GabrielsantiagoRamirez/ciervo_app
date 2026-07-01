import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
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
        final photoRef = upload.imageUrl ??
            upload.photoUrl ??
            upload.mediaId;
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          profile: current.copyWith(
            photoUrl: photoRef,
            imageUrl: upload.imageUrl ?? upload.photoUrl,
            storagePath: upload.storagePath,
            photoUpdatedAt: upload.photoUpdatedAt ?? DateTime.now(),
          ),
        ));
      },
      failure: (error) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: current,
        errorMessage: UserErrorMessage.from(error),
      )),
    );
  }

  Future<void> verifyEmailWithCode(String code) async {
    final email = state.profile?.email.trim();
    if (email == null || email.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'No encontramos un correo en tu perfil.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    final auth = getIt<AuthRepository>();
    final result = await auth.verifyEmailCode(email: email, code: code);
    await result.when(
      success: (_) async {
        await _syncFirebaseVerificationIfAvailable();
        await loadProfile();
      },
      failure: (error) async {
        emit(
          state.copyWith(
            status: ProfileStatus.loaded,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
      },
    );
  }

  Future<void> openEmailVerification() async {
    final email = state.profile?.email.trim();
    if (email == null || email.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Agrega un correo en tu perfil antes de verificar.',
        ),
      );
      return;
    }
    emit(state.copyWith(clearError: true));
  }

  Future<void> syncFirebaseVerification() async {
    await _syncFirebaseVerificationIfAvailable();
  }

  Future<void> _syncFirebaseVerificationIfAvailable() async {
    final firebase = getIt<FirebaseAuthService>();
    final auth = getIt<AuthRepository>();
    if (!firebase.isSignedIn) return;
    try {
      if (!firebase.isEmailVerified) {
        await firebase.sendEmailVerification();
      }
      await firebase.reloadUser();
      final token = await firebase.freshIdToken();
      final result = await auth.firebaseSyncVerification(firebaseIdToken: token);
      await result.when(
        success: (sync) async {
          final current = state.profile;
          if (current != null) {
            emit(
              state.copyWith(
                status: ProfileStatus.loaded,
                profile: current.copyWith(
                  emailVerified: sync.emailVerified || current.emailVerified,
                  phoneVerified: sync.phoneVerified || current.phoneVerified,
                  countryCode: sync.countryCode ?? current.countryCode,
                ),
                clearError: true,
              ),
            );
          }
        },
        failure: (_) {},
      );
    } catch (_) {}
  }
}