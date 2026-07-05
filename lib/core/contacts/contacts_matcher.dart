import 'package:flutter_contacts/flutter_contacts.dart';

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
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

    const batchSize = 100;
    final phoneList = phones.toList();
    final merged = <UserSearchResult>[];
    final seenIds = <String>{};

    for (var offset = 0; offset < phoneList.length; offset += batchSize) {
      final end = (offset + batchSize > phoneList.length)
          ? phoneList.length
          : offset + batchSize;
      final batch = phoneList.sublist(offset, end);
      final result = await _userSearchRepository.searchByPhones(
        phones: batch,
        country: countryCode,
      );
      List<UserSearchResult>? batchItems;
      Object? batchError;
      result.when(
        success: (items) => batchItems = items,
        failure: (error) => batchError = error,
      );
      if (batchError != null) {
        if (batchError is AppException) {
          return Failure(batchError as AppException);
        }
        return Failure(ErrorMapper.fromObject(batchError!));
      }
      for (final user in batchItems!) {
        if (seenIds.add(user.userId)) {
          merged.add(user);
        }
      }
    }

    return Success(merged);
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
