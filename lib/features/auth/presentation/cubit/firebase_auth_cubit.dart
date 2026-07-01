import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/phone_country.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'firebase_auth_state.dart';

class FirebaseAuthCubit extends Cubit<FirebaseAuthState> {
  FirebaseAuthCubit(
    this._authRepository,
    this._firebaseAuth,
    this._locationService,
  ) : super(const FirebaseAuthState());

  final AuthRepository _authRepository;
  final FirebaseAuthService _firebaseAuth;
  final LocationService _locationService;

  Future<void> captureLocation() async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      AppLocation? location;
      try {
        location = await _locationService.currentLocation();
      } catch (_) {
        location = await _locationService.lastKnownLocation();
      }
      if (location == null) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.initial,
            errorMessage:
                'No pudimos obtener tu ubicación. Puedes continuar, pero el país puede inferirse del teléfono.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.initial,
          latitude: location.latitude,
          longitude: location.longitude,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.initial,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
    }
  }

  Future<void> sendPhoneCode({
    required String countryCode,
    required String nationalNumber,
    bool resend = false,
  }) async {
    final e164 = PhoneCountry.toE164(
      countryCode: countryCode,
      nationalNumber: nationalNumber,
    );
    emit(
      state.copyWith(
        status: FirebaseAuthStatus.loading,
        countryCode: countryCode,
        phoneE164: e164,
        clearError: true,
      ),
    );
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: e164,
        forceResendingToken: resend ? state.resendToken : null,
        onCodeSent: (verificationId, resendToken) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.codeSent,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        },
        onCompleted: (credential) async {
          await _completePhoneCredential(credential, e164);
        },
        onFailed: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: error.message ?? 'No se pudo enviar el SMS.',
            ),
          );
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
    }
  }

  Future<void> confirmPhoneCode(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: 'Primero solicita el código SMS.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      final credential = await _firebaseAuth.signInWithPhoneCredential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _afterPhoneSignIn(credential, state.phoneE164 ?? '');
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
    }
  }

  Future<void> _completePhoneCredential(
    PhoneAuthCredential credential,
    String phone,
  ) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _afterPhoneSignIn(userCredential, phone);
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
    }
  }

  Future<void> _afterPhoneSignIn(UserCredential credential, String phone) async {
    final token = await _firebaseAuth.freshIdToken();
    final check = await _authRepository.firebaseCheckUser(
      firebaseIdToken: token,
      phone: phone,
    );
    check.when(
      success: (result) {
        if (result.exists) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.phoneVerified,
              userExists: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.phoneVerified,
              userExists: false,
            ),
          );
        }
      },
      failure: (error) => emit(
        state.copyWith(
          status: FirebaseAuthStatus.phoneVerified,
          userExists: false,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      ),
    );
  }

  Future<bool> firebaseLoginExisting() async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    final token = await _firebaseAuth.freshIdToken();
    final result = await _authRepository.firebaseLogin(
      firebaseIdToken: token,
      phone: state.phoneE164,
    );
    return result.when(
      success: (_) {
        emit(state.copyWith(status: FirebaseAuthStatus.success));
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
          ),
        );
        return false;
      },
    );
  }

  Future<bool> firebaseRegisterProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String identityDocument,
    required String documentType,
    String? city,
    String? password,
  }) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      if (email.trim().isNotEmpty) {
        if (password != null && password.isNotEmpty) {
          // Email path during register is optional; phone user may link email.
          await _firebaseAuth.linkEmailToCurrentUser(email);
        } else {
          await _firebaseAuth.linkEmailToCurrentUser(email);
        }
        await _firebaseAuth.sendEmailVerification();
      }
      final token = await _firebaseAuth.freshIdToken();
      final countryCode = state.countryCode.isNotEmpty
          ? state.countryCode
          : CountryRegistration.inferFromPhone(state.phoneE164 ?? '');
      final profile = <String, dynamic>{
        'phone': state.phoneE164,
        'name': firstName.trim(),
        'lastname': lastName.trim(),
        'email': email.trim(),
        'countryCode': countryCode,
        'documentType': documentType,
        'identityDocument': identityDocument.trim(),
        if (state.latitude != null) 'latitude': state.latitude,
        if (state.longitude != null) 'longitude': state.longitude,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      };
      final result = await _authRepository.firebaseRegister(
        firebaseIdToken: token,
        profile: profile,
      );
      return result.when(
        success: (_) {
          emit(state.copyWith(status: FirebaseAuthStatus.success));
          return true;
        },
        failure: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      await _firebaseAuth.signInWithEmail(email: email, password: password);
      final token = await _firebaseAuth.freshIdToken();
      final result = await _authRepository.firebaseLogin(
        firebaseIdToken: token,
        phone: _firebaseAuth.phoneNumber,
      );
      return result.when(
        success: (_) {
          emit(state.copyWith(status: FirebaseAuthStatus.success));
          return true;
        },
        failure: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
      return false;
    }
  }

  Future<bool> syncVerification() async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      await _firebaseAuth.reloadUser();
      final token = await _firebaseAuth.freshIdToken();
      final result = await _authRepository.firebaseSyncVerification(
        firebaseIdToken: token,
      );
      return result.when(
        success: (_) {
          emit(state.copyWith(status: FirebaseAuthStatus.success));
          return true;
        },
        failure: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
      return false;
    }
  }

  Future<bool> resendEmailVerification() async {
    try {
      await _firebaseAuth.sendEmailVerification();
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: UserErrorMessage.from(ErrorMapper.fromObject(error)),
        ),
      );
      return false;
    }
  }
}
