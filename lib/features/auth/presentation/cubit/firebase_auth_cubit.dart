import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/firebase/firebase_auth_errors.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/phone_country.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/input_validators.dart';
import '../../data/dtos/account_lookup_dto.dart';
import '../../domain/entities/auth_flow.dart';
import '../../domain/repositories/auth_repository.dart';
import 'firebase_login_attempts.dart';
import 'firebase_auth_state.dart';

class FirebaseAuthCubit extends Cubit<FirebaseAuthState> {
  FirebaseAuthCubit(
    this._authRepository,
    this._firebaseAuth,
    this._locationService,
  ) : super(
        FirebaseAuthState(
          countryCode: CountryRegistration.defaultCountryCode(),
        ),
      );

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
          state.copyWith(status: FirebaseAuthStatus.initial, clearError: true),
        );
        return;
      }
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.initial,
          latitude: location.latitude,
          longitude: location.longitude,
          countryCode: state.countryCode.isEmpty
              ? CountryRegistration.defaultCountryCode()
              : state.countryCode,
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

  void clearTransientErrors() {
    emit(state.copyWith(clearError: true));
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
        channel: AuthSignupChannel.phone,
        countryCode: countryCode,
        phoneE164: e164,
        phoneNational: national,
        clearError: true,
        clearAuthMeta: true,
        clearCheckUser: true,
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
      final userCredential = await _firebaseAuth.signInWithCredentialRecovering(
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
    final countryCode = state.countryCode.trim().isNotEmpty
        ? state.countryCode.trim().toUpperCase()
        : 'CO';
    final phoneForBackend = _preferredPhoneForBackend();
    final check = await _authRepository.firebaseCheckUser(
      firebaseIdToken: token,
      phone: phoneForBackend.isNotEmpty ? phoneForBackend : state.phoneNational,
      countryCode: phoneForBackend.startsWith('+') ? null : countryCode,
    );
    check.when(
      success: (result) {
        if (kDebugMode) {
          debugPrint(
            '[AUTH] check-user exists=${result.exists} '
            'uid=${result.firebaseUid?.substring(0, 8)}… '
            'flow=${result.suggestedFlow}',
          );
        }
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.phoneVerified,
            userExists: result.exists,
            requiresFirebaseLink:
                result.requiresFirebaseLink || state.lookupRequiresLink,
            checkUserFirebaseUid: result.firebaseUid,
            checkUserPhone: result.phone ?? state.phoneE164,
            checkUserEmail: result.email,
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

  /// Teléfono en E.164 para endpoints Firebase del backend.
  String _preferredPhoneForBackend() {
    final e164 = state.phoneE164?.trim();
    if (e164 != null && e164.isNotEmpty) return e164;
    final national = state.phoneNational?.trim();
    if (national == null || national.isEmpty) return '';
    return PhoneCountry.toE164(
      countryCode: state.countryCode,
      nationalNumber: national,
    );
  }

  Future<bool> firebaseLoginExisting({String? email}) async {
    emit(state.copyWith(status: FirebaseAuthStatus.loading, clearError: true));
    try {
      final token = await _firebaseAuth.freshIdToken();
      final currentUid = _firebaseAuth.currentUser?.uid;
      final uidAlreadyLinked =
          state.checkUserFirebaseUid != null &&
          currentUid != null &&
          state.checkUserFirebaseUid == currentUid;

      final attempts = _firebaseLoginAttempts(
        userKnownToExist: state.userExists || state.requiresFirebaseLink,
        explicitEmail: email,
      );
      Object? lastError;

      for (final attempt in attempts) {
        if (kDebugMode) {
          final hint = attempt.email != null
              ? 'email=${attempt.email!.contains('@') ? attempt.email!.split('@').first.substring(0, attempt.email!.split('@').first.length.clamp(0, 6)) : attempt.email}…'
              : attempt.phone == null
              ? 'sin contacto'
              : 'phone=${attempt.phone!.length > 6 ? '${attempt.phone!.substring(0, 6)}…' : attempt.phone}';
          debugPrint('[AUTH] firebase/login intento ($hint)');
        }

        final result = await _authRepository.firebaseLogin(
          firebaseIdToken: token,
          phone: attempt.phone,
          email: attempt.email,
          countryCode: attempt.countryCode,
        );

        final ok = result.when(
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
            lastError = error;
            return false;
          },
        );
        if (ok) return true;
      }

      if (lastError == null) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            errorMessage: 'No pudimos verificar tu sesión. Intenta nuevamente.',
          ),
        );
        return false;
      }

      final message = _mapError(lastError!).toLowerCase();
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

      final friendly = _mapBackendAuthError(
        lastError!,
        uidAlreadyLinked: uidAlreadyLinked,
      );
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

  List<({String? phone, String? email, String? countryCode})>
  _firebaseLoginAttempts({
    required bool userKnownToExist,
    String? explicitEmail,
  }) {
    return FirebaseLoginAttempts.build(
      userKnownToExist: userKnownToExist,
      phoneE164: _preferredPhoneForBackend(),
      phoneNational: state.phoneNational,
      countryCode: state.countryCode,
      checkUserPhone: state.checkUserPhone,
      checkUserEmail: state.checkUserEmail,
      explicitEmail: explicitEmail,
    );
  }

  Future<bool> firebaseRegisterProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String identityDocument,
    required String documentType,
    String? city,
    String? department,
    String? region,
    String? province,
    String? cityCode,
    String? password,
    String? contactPhoneNational,
    String? contactCountryCode,
    bool skipEmailLink = false,
  }) async {
    emit(
      state.copyWith(
        status: FirebaseAuthStatus.loading,
        clearError: true,
        channel: skipEmailLink
            ? AuthSignupChannel.email
            : AuthSignupChannel.phone,
      ),
    );
    try {
      final trimmedEmail = email.trim();
      if (!skipEmailLink && trimmedEmail.isNotEmpty) {
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
      final countryCode = (contactCountryCode ?? state.countryCode).isNotEmpty
          ? (contactCountryCode ?? state.countryCode)
          : CountryRegistration.inferFromPhone(state.phoneE164 ?? '');
      final phoneForProfile = skipEmailLink
          ? _digitsOnly(contactPhoneNational ?? '')
          : (state.phoneNational ?? state.phoneE164);
      final profile = <String, dynamic>{
        if (phoneForProfile != null && phoneForProfile.trim().isNotEmpty)
          'phone': phoneForProfile,
        'countryCode': countryCode,
        'name': firstName.trim(),
        'lastname': lastName.trim(),
        'documentType': documentType,
        'identityDocument': identityDocument.trim(),
        if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
        if (state.latitude != null) 'latitude': state.latitude,
        if (state.longitude != null) 'longitude': state.longitude,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (department != null && department.trim().isNotEmpty)
          'department': department.trim(),
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
        if (province != null && province.trim().isNotEmpty)
          'province': province.trim(),
        if (cityCode != null && cityCode.trim().isNotEmpty)
          'cityCode': cityCode.trim(),
      };
      final result = await _authRepository.firebaseRegister(
        firebaseIdToken: token,
        profile: profile,
      );
      return await result.when(
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
        failure: (error) async {
          final message = _mapError(error).toLowerCase();
          if (message.contains('firebase/login') ||
              message.contains('usa firebase/login')) {
            return firebaseLoginExisting(
              email: trimmedEmail.isEmpty ? null : trimmedEmail,
            );
          }
          if (skipEmailLink) {
            await _firebaseAuth.rollbackRecentRegistration();
          }
          emit(
            state.copyWith(
              status: FirebaseAuthStatus.failure,
              channel: skipEmailLink
                  ? AuthSignupChannel.email
                  : AuthSignupChannel.phone,
              errorMessage: FirebaseAuthErrors.userMessage(error),
            ),
          );
          return false;
        },
      );
    } catch (error) {
      if (skipEmailLink) {
        await _firebaseAuth.rollbackRecentRegistration();
      }
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          channel: skipEmailLink ? AuthSignupChannel.email : state.channel,
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
    required String identityDocument,
    required String documentType,
    String? city,
    String? department,
    String? region,
    String? province,
    String? cityCode,
  }) async {
    emit(
      state.copyWith(
        status: FirebaseAuthStatus.loading,
        channel: AuthSignupChannel.email,
        clearError: true,
        clearAuthMeta: true,
      ),
    );
    try {
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
        department: department,
        region: region,
        province: province,
        cityCode: cityCode,
        contactCountryCode: countryCode,
        skipEmailLink: true,
      );
    } catch (error) {
      await _firebaseAuth.rollbackRecentRegistration();
      emit(
        state.copyWith(
          status: FirebaseAuthStatus.failure,
          channel: AuthSignupChannel.email,
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
        channel: AuthSignupChannel.email,
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
        await _firebaseAuth.createUserWithEmail(
          email: email,
          password: password,
        );
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
    emit(
      state.copyWith(
        status: FirebaseAuthStatus.loading,
        channel: AuthSignupChannel.email,
        clearError: true,
      ),
    );
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
                channel: AuthSignupChannel.email,
                errorMessage: FirebaseAuthErrors.userMessage(error),
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: FirebaseAuthStatus.initial,
                clearError: true,
              ),
            );
          }
          return false;
        },
      );
    } catch (error) {
      if (emitFailure) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            channel: AuthSignupChannel.email,
            errorMessage: _mapError(error),
          ),
        );
      } else {
        emit(
          state.copyWith(status: FirebaseAuthStatus.initial, clearError: true),
        );
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
    _emailVerificationResendAvailableAt = DateTime.now().add(
      const Duration(seconds: 60),
    );
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

  Future<({bool success, String message})> requestPasswordRecovery(
    String email,
  ) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || InputValidators.email(trimmed) != null) {
      return (
        success: false,
        message: 'Ingresa un correo electrónico válido.',
      );
    }
    emit(
      state.copyWith(
        status: FirebaseAuthStatus.loading,
        channel: AuthSignupChannel.email,
        clearError: true,
      ),
    );
    final result = await _authRepository.requestPasswordRecovery(trimmed);
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.initial,
            channel: AuthSignupChannel.email,
            clearError: true,
          ),
        );
        return (
          success: true,
          message:
              'Si el correo está registrado, te enviamos un código de 6 dígitos. '
              'Revisa tu bandeja y spam.',
        );
      },
      failure: (error) {
        final message = UserErrorMessage.from(error);
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            channel: AuthSignupChannel.email,
            errorMessage: message,
          ),
        );
        return (success: false, message: message);
      },
    );
  }

  Future<({bool success, String message})> recoverPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final trimmed = email.trim();
    final otp = code.replaceAll(RegExp(r'\D'), '');
    if (trimmed.isEmpty || InputValidators.email(trimmed) != null) {
      return (
        success: false,
        message: 'Ingresa un correo electrónico válido.',
      );
    }
    if (otp.length != 6) {
      return (success: false, message: 'Ingresa el código de 6 dígitos.');
    }
    final passwordError = InputValidators.password(newPassword);
    if (passwordError != null) {
      return (success: false, message: passwordError);
    }

    emit(
      state.copyWith(
        status: FirebaseAuthStatus.loading,
        channel: AuthSignupChannel.email,
        clearError: true,
      ),
    );
    final result = await _authRepository.recoverPassword(
      email: trimmed,
      code: otp,
      newPassword: newPassword,
    );
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.initial,
            channel: AuthSignupChannel.email,
            clearError: true,
          ),
        );
        return (
          success: true,
          message: 'Contraseña actualizada correctamente.',
        );
      },
      failure: (error) {
        final message = UserErrorMessage.from(error);
        emit(
          state.copyWith(
            status: FirebaseAuthStatus.failure,
            channel: AuthSignupChannel.email,
            errorMessage: message,
          ),
        );
        return (success: false, message: message);
      },
    );
  }

  DateTime? _emailVerificationResendAvailableAt;

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _mapError(Object error) {
    if (error is FirebaseAuthException) {
      return FirebaseAuthErrors.userMessage(error);
    }
    return UserErrorMessage.from(ErrorMapper.fromObject(error));
  }

  String _mapBackendAuthError(Object error, {bool uidAlreadyLinked = false}) {
    final message = UserErrorMessage.from(ErrorMapper.fromObject(error));
    final lower = message.toLowerCase();
    if (lower.contains('inactiv') || lower.contains('bloquead')) {
      return 'Tu cuenta no está activa. Contacta soporte.';
    }
    if (lower.contains('vinculad')) {
      if (uidAlreadyLinked) {
        return 'No pudimos completar tu inicio de sesión. '
            'Tu número ya está verificado; contacta soporte si persiste.';
      }
      return 'Este número ya está asociado a otra cuenta. '
          'Contacta soporte si crees que es un error.';
    }
    return message;
  }
}
