import 'package:ciervo_clud/features/search/domain/entities/global_search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea respuesta value.items multi-tipo', () {
    final result = GlobalSearchResult.fromJson({
      'query': 'pizza',
      'originLatitude': 4.65,
      'originLongitude': -74.06,
      'total': 3,
      'counts': {
        'people': 1,
        'businesses': 1,
        'products': 1,
        'promotions': 0,
        'services': 0,
        'events': 0,
      },
      'items': [
        {
          'type': 'business',
          'id': 10,
          'title': 'Pizza Cerca',
          'subtitle': 'Calle 1',
          'distanceKm': 0.12,
          'businessId': 10,
          'ciervoId': 'CV000010',
          'imageUrl': 'https://example.com/a.jpg',
        },
        {
          'type': 'product',
          'id': 100,
          'title': 'Pizza Margarita',
          'subtitle': 'Pizza Cerca',
          'price': 25000,
          'currency': 'COP',
          'distanceKm': 0.12,
          'businessId': 10,
        },
        {
          'type': 'person',
          'id': 2,
          'title': 'Pedro Pizza',
          'username': 'pedropizza',
          'accountType': 'person',
          'distanceKm': 0.15,
        },
      ],
    });

    expect(result.total, 3);
    expect(result.counts.people, 1);
    expect(result.counts.businesses, 1);
    expect(result.counts.products, 1);
    expect(result.items[0].type, GlobalSearchItemType.business);
    expect(result.items[0].ciervoId, 'CV000010');
    expect(result.items[1].type, GlobalSearchItemType.product);
    expect(result.items[1].priceLabel, 'COP 25000');
    expect(result.items[2].type, GlobalSearchItemType.person);
    expect(result.items[2].username, 'pedropizza');
  });

  test('types API acepta alias en español', () {
    expect(
      GlobalSearchItemType.fromApi('personas'),
      GlobalSearchItemType.person,
    );
    expect(
      GlobalSearchItemType.fromApi('lugares'),
      GlobalSearchItemType.business,
    );
    expect(
      GlobalSearchItemType.fromApi('comida'),
      GlobalSearchItemType.product,
    );
    expect(
      GlobalSearchItemType.fromApi('promos'),
      GlobalSearchItemType.promotion,
    );
  });
}
