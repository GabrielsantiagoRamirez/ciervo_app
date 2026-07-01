import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository) : super(const AuthState());

  final AuthRepository _authRepository;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        clearError: true,
      ),
    );

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    result.when(
      success: (_) => emit(
        state.copyWith(
          status: AuthSubmissionStatus.success,
          clearError: true,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String identityDocument,
    required String documentType,
    required String countryCode,
  }) async {
    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        clearError: true,
      ),
    );

    final result = await _authRepository.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
      identityDocument: identityDocument,
      documentType: documentType,
      countryCode: countryCode,
    );

    result.when(
      success: (_) => emit(
        state.copyWith(
          status: AuthSubmissionStatus.success,
          clearError: true,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }
}
