import 'package:ciervo_clud/features/favorites/data/dtos/favorite_business_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listFromResponse lee value.items del contrato paginado', () {
    final items = FavoriteBusinessDto.listFromResponse({
      'status': true,
      'value': {
        'items': [
          {
            'businessId': 10,
            'name': 'QA Cafe Bogota Free',
            'category': 'Cafe',
            'country': 'CO',
            'city': 'Bogota',
          },
          {
            'businessId': 20,
            'name': 'Hotel Dorado Funza',
            'category': 'Hotel',
          },
          {
            'id': 30,
            'businessName': 'QA Beach Club Cartagena',
            'categoryName': 'Club',
          },
        ],
        'total': 3,
      },
    });

    expect(items, hasLength(3));
    expect(items.map((item) => item.businessId), ['10', '20', '30']);
    expect(items.first.name, 'QA Cafe Bogota Free');
    expect(items.every((item) => item.isFavorite), isTrue);
  });

  test('listFromResponse también acepta value como lista plana', () {
    final items = FavoriteBusinessDto.listFromResponse({
      'status': true,
      'value': [
        {'businessId': 1, 'name': 'Uno'},
      ],
    });

    expect(items, hasLength(1));
    expect(items.single.businessId, '1');
  });
}
