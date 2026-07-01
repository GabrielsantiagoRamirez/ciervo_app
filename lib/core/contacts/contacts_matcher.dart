import 'package:flutter_contacts/flutter_contacts.dart';

import '../errors/app_exception.dart';
import '../firebase/phone_country.dart';
import '../../features/users/domain/entities/user_search_result.dart';
import '../permissions/app_permission_service.dart';
import '../result/result.dart';
import '../../features/users/data/user_search_repository.dart';

/// Matchea contactos del dispositivo contra usuarios CIERVO vía batch API.
class ContactsMatcher {
  ContactsMatcher(
    this._userSearchRepository,
    this._permissionService,
  );

  final UserSearchRepository _userSearchRepository;
  final AppPermissionService _permissionService;

  Future<Result<List<UserSearchResult>>> matchDeviceContacts({
    String countryCode = 'CO',
    int maxContacts = 500,
  }) async {
    final granted = await _permissionService.requestContactsIfNeeded();
    if (!granted) {
      return Failure(
        AppException(message: const AppContactsPermissionException().toString()),
      );
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final phones = <String>{};
    for (final contact in contacts.take(maxContacts)) {
      for (final phone in contact.phones) {
        final normalized = _normalizePhone(phone.number, countryCode);
        if (normalized != null) phones.add(normalized);
      }
    }

    if (phones.isEmpty) {
      return const Success([]);
    }

    return _userSearchRepository.searchByPhones(
      phones: phones.toList(),
      country: countryCode,
    );
  }

  String? _normalizePhone(String raw, String countryCode) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (raw.trim().startsWith('+')) {
      return '+$digits';
    }
    return PhoneCountry.toE164(
      countryCode: countryCode,
      nationalNumber: digits,
    );
  }
}

class AppContactsPermissionException implements Exception {
  const AppContactsPermissionException();

  @override
  String toString() => 'Necesitamos permiso de contactos para encontrar amigos en Ciervo.';
}
