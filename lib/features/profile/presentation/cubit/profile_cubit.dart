import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._profileRepository) : super(const ProfileState());

  final ProfileRepository _profileRepository;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    final result = await _profileRepository.getMe();

    result.when(
      success: (profile) =>
          emit(ProfileState(status: ProfileStatus.loaded, profile: profile)),
      failure: (error) => emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
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
      success: (profile) =>
          emit(ProfileState(status: ProfileStatus.saved, profile: profile)),
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
      success: (url) => emit(ProfileState(
        status: ProfileStatus.saved,
        profile: current.copyWith(photoUrl: url),
      )),
      failure: (error) => emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: UserErrorMessage.from(error),
      )),
    );
  }
}
