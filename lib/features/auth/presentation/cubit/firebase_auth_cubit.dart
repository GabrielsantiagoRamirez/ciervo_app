import 'dart:async';

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
import '../../data/dtos/account_lookup_dto.dart';
import '../../domain/entities/auth_flow.dart';
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
    AccountLookupResult? lookup,
  }) async {
    final national = PhoneCountry.nationalDigits(
      countryCode: countryCode,
      rawInput: nationalNumber,
    );
    final e164 = PhoneCountry.toE164(
      countryCode: countryCode,
      nationalNumber: national,
    );
    final isLegacyMigration = lookup?.resolvedFlow == AuthFlow.legacyMigration;
    emit(
      state.copyWith(
        status: isLegacyMigration && !resend
            ? FirebaseAuthStatus.migrating
            : FirebaseAuthStatus.loading,
        countryCode: countryCode,
        phoneE164: e164,
        phoneNational: national,
        clearError: true,
        clearAuthMeta: true,
        lookupExists: lookup?.exists ?? false,
        lookupRequiresLink: lookup?.requiresFirebaseLink ?? false,
      ),
    );
    try {
      await _firebaseAuth.prepareForPhoneAuth();
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
      final userCredential =
          await _firebaseAuth.signInWithCredentialRecovering(credential);
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
    final countryCode = state.countryCode.trim().isNotEmpty
        ? state.countryCode.trim().toUpperCase()
        : 'CO';
    final check = await _authRepository.firebaseCheckUser(
      firebaseIdToken: token,
      phone: state.phoneNational,
      countryCode: countryCode,
    );
    check.when(
      success: (result) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.phoneVerified,
            userExists: result.exists,
            requiresFirebaseLink:
                result.requiresFirebaseLink || state.lookupRequiresLink,
          ),
        );
      },
      failure: (error) => emit(
        state.copyWith(
          status: FirebaseAuthStatus.phoneVerified,
          userExists: false,
          requiresFirebaseLink: state.lookupRequiresLink,
          errorMessage: _mapError(error),
        ),
      ),
    );
  }

  Future<bool> firebaseLoginExisting({String? email}) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      final token = await _firebaseAuth.freshIdToken();
      final countryCode = state.countryCode.trim().isNotEmpty
          ? state.countryCode.trim().toUpperCase()
          : 'CO';
      final result = await _authRepository.firebaseLogin(
        firebaseIdToken: token,
        phone: state.phoneNational,
        email: email,
        countryCode: countryCode,
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
          final message = _mapError(error).toLowerCase();
          if (message.contains('registr') ||
              message.contains('firebase/register') ||
              message.contains('completa tu perfil')) {
            emit(
              state.copyWith(
                status: FirebaseAuthStatus.phoneVerified,
                userExists: false,
                clearError: true,
              ),
            );
            return false;
          }
          final friendly = _mapBackendAuthError(error);
          if (friendly.contains('no está activa')) {
            unawaited(_firebaseAuth.signOut());
            unawaited(_authRepository.clearLocalSession());
          }
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              errorMessage: friendly,
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
        markEmailVerificationSent();
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
      markEmailVerificationSent();
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

  /// Flujo B.1: valida contraseña legacy, crea usuario Firebase y envía verificación.
  Future<bool> migrateLegacyEmailWithPassword({
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: FirebaseAuthStatus.migrating,
        clearError: true,
      ),
    );

    // Evita JWT legacy viejo sin disparar FCM/logout remoto.
    await _authRepository.clearLocalSession();

    final validation = await _authRepository.validateLegacyCredentials(
      email: email,
      password: password,
    );

    final validated = validation.when(
      success: (_) => true,
      failure: (error) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
    if (!validated) return false;

    try {
      await _firebaseAuth.signOut();
      try {
        await _firebaseAuth.createUserWithEmail(email: email, password: password);
      } on FirebaseAuthException catch (error) {
        if (error.code == 'email-already-in-use') {
          await _firebaseAuth.signInWithEmail(email: email, password: password);
        } else {
          rethrow;
        }
      }
      await _firebaseAuth.sendEmailVerification();
      markEmailVerificationSent();
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.emailVerificationPending,
          clearError: true,
        ),
      );
      return true;
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

  /// Tras confirmar el correo en Firebase: login y vinculación legacy.
  Future<bool> completeLegacyEmailMigration({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    final trimmedEmail = email.trim();
    try {
      if (!_firebaseAuth.isSignedIn) {
        await _firebaseAuth.signInWithEmail(
          email: trimmedEmail,
          password: password,
        );
      }
      await _firebaseAuth.reloadUser();
      if (!_firebaseAuth.isEmailVerified) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.emailVerificationPending,
            errorMessage:
                'Aún no confirmamos tu correo. Revisa tu bandeja e intenta de nuevo.',
          ),
        );
        return false;
      }

      // ID token con claims actualizados (email_verified).
      final token = await _firebaseAuth.freshIdToken(forceRefresh: true);

      final check = await _authRepository.firebaseCheckUser(
        firebaseIdToken: token,
        email: trimmedEmail,
      );
      final checkOk = check.when(
        success: (_) => true,
        failure: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.emailVerificationPending,
              errorMessage: UserErrorMessage.from(error),
            ),
          );
          return false;
        },
      );
      if (!checkOk) return false;

      final result = await _authRepository.firebaseLogin(
        firebaseIdToken: token,
        email: trimmedEmail,
      );
      return result.when(
        success: (session) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.success,
              authAction: session.authAction,
              linkedLegacy: session.isLegacyLink,
              clearError: true,
            ),
          );
          return true;
        },
        failure: (error) {
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.emailVerificationPending,
              errorMessage: UserErrorMessage.from(error),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.emailVerificationPending,
          errorMessage: _mapError(error),
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
    bool emitFailure = true,
  }) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      await _firebaseAuth.signInWithEmail(email: email, password: password);
      final token = await _firebaseAuth.freshIdToken(forceRefresh: true);
      final result = await _authRepository.firebaseLogin(
        firebaseIdToken: token,
        email: email.trim(),
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
          if (emitFailure) {
            emit(
              state.copyWith(
                status: FirebaseAuthStatus.failure,
                errorMessage: FirebaseAuthErrors.userMessage(error),
              ),
            );
          } else {
            emit(state.copyWith(status: FirebaseAuthStatus.initial, clearError: true));
          }
          return false;
        },
      );
    } catch (error) {
      if (emitFailure) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            errorMessage: _mapError(error),
          ),
        );
      } else {
        emit(state.copyWith(status: FirebaseAuthStatus.initial, clearError: true));
      }
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

  void restorePendingPhoneRegistration({
    required String phoneNational,
    required String phoneE164,
    required String countryCode,
  }) {
    emit(
      FirebaseAuthState(
        status: FirebaseAuthStatus.phoneVerified,
        phoneNational: phoneNational,
        phoneE164: phoneE164,
        countryCode: countryCode,
        userExists: false,
      ),
    );
  }

  Future<void> resendPhoneCode() async {
    final national = state.phoneNational;
    final country = state.countryCode;
    if (national == null || national.isEmpty) return;
    await sendPhoneCode(
      countryCode: country,
      nationalNumber: national,
      resend: true,
      lookup: state.lookupRequiresLink
          ? AccountLookupResult(
              exists: state.lookupExists,
              suggestedFlow: 'firebase_phone',
              requiresFirebaseLink: state.lookupRequiresLink,
              hasFirebaseUid: false,
            )
          : null,
    );
  }

  Future<bool> resendEmailVerification() async {
    final result = await resendEmailVerificationWithFeedback();
    return result.success;
  }

  int get emailVerificationResendCooldownSeconds {
    final availableAt = _emailVerificationResendAvailableAt;
    if (availableAt == null) return 0;
    final remaining = availableAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool get canResendEmailVerification =>
      emailVerificationResendCooldownSeconds == 0;

  void markEmailVerificationSent() {
    _emailVerificationResendAvailableAt =
        DateTime.now().add(const Duration(seconds: 60));
  }

  Future<({bool success, String? errorMessage})>
      resendEmailVerificationWithFeedback() async {
    if (_firebaseAuth.isEmailVerified) {
      return (success: true, errorMessage: null);
    }

    final cooldown = emailVerificationResendCooldownSeconds;
    if (cooldown > 0) {
      return (
        success: false,
        errorMessage: 'Espera ${cooldown}s antes de reenviar el correo.',
      );
    }

    try {
      await _firebaseAuth.sendEmailVerification();
      markEmailVerificationSent();
      return (success: true, errorMessage: null);
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'too-many-requests'
          ? 'Has solicitado varios correos en poco tiempo. '
              'Intenta nuevamente más tarde.'
          : FirebaseAuthErrors.userMessage(error);
      emit(state.copyWith(errorMessage: message));
      return (success: false, errorMessage: message);
    } catch (error) {
      final message = _mapError(error);
      emit(state.copyWith(errorMessage: message));
      return (success: false, errorMessage: message);
    }
  }

  DateTime? _emailVerificationResendAvailableAt;

  String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  String _mapError(Object error) {
    if (error is FirebaseAuthException) {
      return FirebaseAuthErrors.userMessage(error);
    }
    return UserErrorMessage.from(ErrorMapper.fromObject(error));
  }

  String _mapBackendAuthError(Object error) {
    final message = UserErrorMessage.from(ErrorMapper.fromObject(error));
    final lower = message.toLowerCase();
    if (lower.contains('inactiv') || lower.contains('bloquead')) {
      return 'Tu cuenta no está activa. Contacta soporte.';
    }
    if (lower.contains('vinculad')) {
      return 'Este número ya está registrado. Iniciaremos sesión con tu código de verificación.';
    }
    return message;
  }
}
