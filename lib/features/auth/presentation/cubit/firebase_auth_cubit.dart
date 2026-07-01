import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/firebase/firebase_auth_errors.dart';
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
      await _locationService.requestPermission();
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
            clearError: true,
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
          errorMessage: _mapError(error),
        ),
      );
    }
  }

  Future<void> sendPhoneCode({
    required String countryCode,
    required String nationalNumber,
    bool resend = false,
  }) async {
    final national = _digitsOnly(nationalNumber);
    final e164 = PhoneCountry.toE164(
      countryCode: countryCode,
      nationalNumber: national,
    );
    emit(
      state.copyWith(
        status: FirebaseAuthStatus.loading,
        countryCode: countryCode,
        phoneE164: e164,
        phoneNational: national,
        clearError: true,
        clearAuthMeta: true,
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
          await _completePhoneCredential(credential);
        },
        onFailed: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: FirebaseAuthErrors.userMessage(error),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: _mapError(error),
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
      await _afterPhoneSignIn(credential);
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: _mapError(error),
        ),
      );
    }
  }

  Future<void> _completePhoneCredential(PhoneAuthCredential credential) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _afterPhoneSignIn(userCredential);
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: _mapError(error),
        ),
      );
    }
  }

  Future<void> _afterPhoneSignIn(UserCredential credential) async {
    final token = await _firebaseAuth.freshIdToken();
    final check = await _authRepository.firebaseCheckUser(
      firebaseIdToken: token,
      phone: state.phoneNational,
      countryCode: state.countryCode,
    );
    check.when(
      success: (result) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.phoneVerified,
            userExists: result.exists,
            requiresFirebaseLink: result.requiresFirebaseLink,
          ),
        );
      },
      failure: (error) => emit(
        state.copyWith(
          status: FirebaseAuthStatus.phoneVerified,
          userExists: false,
          requiresFirebaseLink: false,
          errorMessage: _mapError(error),
        ),
      ),
    );
  }

  Future<bool> firebaseLoginExisting({String? email}) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    final token = await _firebaseAuth.freshIdToken();
    final result = await _authRepository.firebaseLogin(
      firebaseIdToken: token,
      phone: state.phoneNational,
      email: email,
      countryCode: state.countryCode,
    );
    return result.when(
      success: (session) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.success,
            authAction: session.authAction,
            linkedLegacy: session.isLegacyLink,
          ),
        );
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            errorMessage: _mapError(error),
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
      final trimmedEmail = email.trim();
      if (trimmedEmail.isNotEmpty) {
        if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: 'Ingresa un correo válido o déjalo vacío.',
            ),
          );
          return false;
        }
        await _firebaseAuth.linkEmailToCurrentUser(trimmedEmail);
        await _firebaseAuth.sendEmailVerification();
      }
      final token = await _firebaseAuth.freshIdToken();
      final countryCode = state.countryCode.isNotEmpty
          ? state.countryCode
          : CountryRegistration.inferFromPhone(state.phoneE164 ?? '');
      final profile = <String, dynamic>{
        'phone': state.phoneNational ?? state.phoneE164,
        'countryCode': countryCode,
        'name': firstName.trim(),
        'lastname': lastName.trim(),
        'documentType': documentType,
        'identityDocument': identityDocument.trim(),
        if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
        if (state.latitude != null) 'latitude': state.latitude,
        if (state.longitude != null) 'longitude': state.longitude,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      };
      final result = await _authRepository.firebaseRegister(
        firebaseIdToken: token,
        profile: profile,
      );
      return result.when(
        success: (session) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.success,
              authAction: session.authAction ?? 'register',
              linkedLegacy: session.isLegacyLink,
            ),
          );
          return true;
        },
        failure: (error) {
          final message = _mapError(error).toLowerCase();
          if (message.contains('firebase/login') ||
              message.contains('usa firebase/login')) {
            return firebaseLoginExisting(email: trimmedEmail.isEmpty ? null : trimmedEmail);
          }
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: FirebaseAuthErrors.userMessage(error),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: _mapError(error),
        ),
      );
      return false;
    }
  }

  Future<bool> registerWithEmailAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String countryCode,
    required String phoneNational,
    required String identityDocument,
    required String documentType,
    String? city,
  }) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      final national = _digitsOnly(phoneNational);
      final e164 = PhoneCountry.toE164(
        countryCode: countryCode,
        nationalNumber: national,
      );
      emit(
        state.copyWith(
          countryCode: countryCode,
          phoneE164: e164,
          phoneNational: national,
        ),
      );
      await _firebaseAuth.createUserWithEmail(email: email, password: password);
      await _firebaseAuth.sendEmailVerification();
      return firebaseRegisterProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        identityDocument: identityDocument,
        documentType: documentType,
        city: city,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: _mapError(error),
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
        email: email.trim(),
        phone: state.phoneNational,
        countryCode: state.countryCode,
      );
      return result.when(
        success: (session) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.success,
              authAction: session.authAction,
              linkedLegacy: session.isLegacyLink,
            ),
          );
          return true;
        },
        failure: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: FirebaseAuthErrors.userMessage(error),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: _mapError(error),
        ),
      );
      return false;
    }
  }

  Future<bool> syncVerification({String? email}) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      await _firebaseAuth.reloadUser();
      final token = await _firebaseAuth.freshIdToken();
      final result = await _authRepository.firebaseSyncVerification(
        firebaseIdToken: token,
        phone: state.phoneNational,
        email: email,
        countryCode: state.countryCode,
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
              errorMessage: FirebaseAuthErrors.userMessage(error),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          errorMessage: _mapError(error),
        ),
      );
      return false;
    }
  }

  void restartPhoneFlow() {
    emit(const FirebaseAuthState());
  }

  Future<bool> resendEmailVerification() async {
    try {
      await _firebaseAuth.sendEmailVerification();
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: _mapError(error),
        ),
      );
      return false;
    }
  }

  String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  String _mapError(Object error) {
    if (error is FirebaseAuthException) {
      return FirebaseAuthErrors.userMessage(error);
    }
    return UserErrorMessage.from(ErrorMapper.fromObject(error));
  }
}
