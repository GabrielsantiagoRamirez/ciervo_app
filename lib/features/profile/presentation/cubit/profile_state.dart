import '../../domain/entities/user_profile.dart';

enum ProfileStatus { initial, loading, loaded, saving, uploadingPhoto, saved, empty, failure }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.ciervoUserCode,
    this.errorMessage,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final String? ciervoUserCode;
  final String? errorMessage;

  bool get isLoading => status == ProfileStatus.loading;

  bool get isSaving => status == ProfileStatus.saving;
  bool get isUploadingPhoto => status == ProfileStatus.uploadingPhoto;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? ciervoUserCode,
    String? errorMessage,
    bool clearError = false,
    bool clearCiervoUserCode = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      ciervoUserCode:
          clearCiervoUserCode ? null : ciervoUserCode ?? this.ciervoUserCode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
