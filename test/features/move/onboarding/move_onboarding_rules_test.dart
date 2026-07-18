import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_enums.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_requests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CO exige reverso de licencia y CL no', () {
    final request = MoveLicenseOnboardingRequest(
      number: 'LIC-DEMO',
      licenseClass: 'B1',
      expiresAt: DateTime.utc(2030),
      frontMediaAssetId: 1,
      experienceYears: 2,
    );
    expect(
      request.validate(countryCode: 'CO', nowUtc: DateTime.utc(2026)),
      contains('backMediaAssetId'),
    );
    expect(
      request.validate(countryCode: 'CL', nowUtc: DateTime.utc(2026)),
      isEmpty,
    );
  });

  test('documentos dinámicos aplican antigüedad y Taxi', () {
    expect(
      requiredDocumentTypes(
        countryCode: 'CO',
        vehicleYear: 2020,
        services: const [MoveServiceType.taxi],
        nowUtc: DateTime.utc(2026),
      ),
      containsAll({
        MoveVehicleDocumentType.registration,
        MoveVehicleDocumentType.insurance,
        MoveVehicleDocumentType.technicalInspection,
        MoveVehicleDocumentType.taxiAuthorization,
      }),
    );
    expect(
      requiredDocumentTypes(
        countryCode: 'CL',
        vehicleYear: 2026,
        nowUtc: DateTime.utc(2026),
      ),
      isNot(contains(MoveVehicleDocumentType.technicalInspection)),
    );
  });

  test('vehículo exige cinco fotos de tipos y assets diferentes', () {
    final request = MoveVehicleOnboardingRequest(
      physicalType: MovePhysicalVehicleType.car,
      serviceCategory: MoveVehicleCategory.economy,
      brand: 'Marca',
      model: 'Modelo',
      year: 2026,
      color: 'Blanco',
      plate: 'ABC123',
      passengerCapacity: 4,
      vin: '1HGCM82633A000001',
      documents: [
        const MoveVehicleDocumentInputV2(
          type: MoveVehicleDocumentType.registration,
          mediaAssetId: 1,
        ),
        MoveVehicleDocumentInputV2(
          type: MoveVehicleDocumentType.insurance,
          mediaAssetId: 2,
          expiresAt: DateTime.utc(2030),
        ),
      ],
      photos: const [
        MoveVehiclePhotoInput(
          type: MoveVehiclePhotoType.front,
          mediaAssetId: 10,
        ),
        MoveVehiclePhotoInput(
          type: MoveVehiclePhotoType.rear,
          mediaAssetId: 11,
        ),
        MoveVehiclePhotoInput(
          type: MoveVehiclePhotoType.left,
          mediaAssetId: 12,
        ),
        MoveVehiclePhotoInput(
          type: MoveVehiclePhotoType.right,
          mediaAssetId: 13,
        ),
        MoveVehiclePhotoInput(
          type: MoveVehiclePhotoType.interior,
          mediaAssetId: 13,
        ),
      ],
    );

    expect(
      request.validate(countryCode: 'CO', nowUtc: DateTime.utc(2026)),
      contains('photos'),
    );
  });

  test('operations valida emergencia, agenda, límites y servicios', () {
    const request = MoveOperationsOnboardingRequest(
      emergencyName: 'A',
      emergencyPhone: '123',
      emergencyRelationship: 'F',
      languages: ['es,co'],
      accessible: false,
      pets: false,
      airConditioning: true,
      luggage: true,
      isAvailableNow: false,
      scheduleJson: '[]',
      radiusKm: 30,
      maxDistanceKm: 20,
      services: [MoveServiceType.taxi, MoveServiceType.taxi],
    );

    final errors = request.validate();
    expect(
      errors.keys,
      containsAll([
        'emergencyName',
        'emergencyPhone',
        'emergencyRelationship',
        'languages',
        'scheduleJson',
        'radiusKm',
        'services',
      ]),
    );
  });
}
