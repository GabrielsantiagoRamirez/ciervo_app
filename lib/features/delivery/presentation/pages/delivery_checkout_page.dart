import '../../../place_detail/data/business_detail_repository.dart';
import '../../domain/entities/delivery_models.dart';
import 'order_checkout_page.dart';

export 'order_checkout_page.dart';

/// Compatibilidad con llamadas previas al checkout de domicilio.
class DeliveryCheckoutPage extends OrderCheckoutPage {
  DeliveryCheckoutPage({
    required super.businessId,
    required super.businessName,
    required super.products,
    required super.initialLocation,
    DeliveryAvailability? availability,
    super.key,
  }) : super(
          initialFulfillment: availability?.deliveryAvailable == true
              ? OrderFulfillmentType.delivery
              : null,
          deliveryAvailability: availability,
        );
}
