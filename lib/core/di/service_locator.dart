import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../analytics/analytics_service.dart';
import '../config/app_config.dart';
import '../crash/crash_reporting_service.dart';
import '../logging/app_logger.dart';
import '../network/auth_token_refresher.dart';
import '../network/network_client.dart';
import '../permissions/app_permission_service.dart';
import '../session/session_manager.dart';
import '../storage/secure_storage.dart';
import '../version/app_version_service.dart';
import '../firebase/firebase_auth_service.dart';
import '../location/location_service.dart';
import '../kids/selected_kid_context.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/chat/data/chat_inbox_repository.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat_payments/data/chat_payments_remote_datasource.dart';
import '../../features/discovery/data/repositories/activity_feed_repository.dart';
import '../../features/discovery/data/repositories/business_categories_repository.dart';
import '../../features/discovery/data/datasources/discovery_remote_datasource.dart';
import '../../features/discovery/data/repositories/discovery_repository_impl.dart';
import '../../features/discovery/domain/repositories/discovery_repository.dart';
import '../../features/delivery/data/repositories/delivery_repository_impl.dart';
import '../../features/delivery/domain/repositories/delivery_repository.dart';
import '../../features/cashback/data/cashback_repository.dart';
import '../../features/favorites/data/datasources/favorites_remote_datasource.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/bonuses/data/datasources/bonuses_remote_datasource.dart';
import '../../features/bonuses/data/repositories/bonuses_repository_impl.dart';
import '../../features/bonuses/domain/repositories/bonuses_repository.dart';
import '../../features/campaigns/data/datasources/campaigns_remote_datasource.dart';
import '../../features/campaigns/data/repositories/campaigns_repository_impl.dart';
import '../../features/campaigns/domain/repositories/campaigns_repository.dart';
import '../../features/financial_history/data/datasources/financial_history_remote_datasource.dart';
import '../../features/financial_history/data/repositories/financial_history_repository_impl.dart';
import '../../features/financial_history/domain/repositories/financial_history_repository.dart';
import '../../features/family_chat/data/family_chat_repository.dart';
import '../../features/kids/data/datasources/kids_remote_datasource.dart';
import '../../features/kids/data/repositories/kids_repository_impl.dart';
import '../../features/kids/domain/repositories/kids_repository.dart';
import '../../features/kid_auth/data/datasources/kid_auth_remote_datasource.dart';
import '../../features/kid_auth/data/repositories/kid_auth_repository_impl.dart';
import '../../features/kid_me/data/kid_me_repository.dart';
import '../../features/catalogs/data/catalog_repository.dart';
import '../../features/exchange/data/exchange_rate_repository.dart';
import '../../features/kyc/data/kyc_repository.dart';
import '../../features/users/data/user_search_repository.dart';
import '../../features/location/data/client_location_repository.dart';
import '../../features/media/data/media_repository.dart';
import '../../features/memberships/data/memberships_repository.dart';
import '../../features/memberships/presentation/cubit/membership_cubit.dart';
import '../../features/loyalty/data/loyalty_repository.dart';
import '../firebase/firebase_storage_service.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/cubit/notification_badges_cubit.dart';
import '../notifications/notifications_sync.dart';
import '../notifications/ciervo_push_service.dart';
import '../geo/geo_repository.dart';
import '../contacts/contacts_matcher.dart';
import '../notifications/notification_events_listener.dart';
import '../../features/place_detail/data/business_detail_repository.dart';
import '../../features/place_detail/data/review_repository.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/product_categories/data/product_categories_repository.dart';
import '../../features/qr_wallet/data/qr_wallet_repository.dart';
import '../../features/vakupli/data/vakupli_repository.dart';
import '../../features/secure_shipment/data/secure_shipment_repository.dart';
import '../../features/receipts/data/datasources/receipts_remote_datasource.dart';
import '../../features/receipts/data/repositories/receipts_repository_impl.dart';
import '../../features/receipts/domain/repositories/receipts_repository.dart';
import '../../features/reservations/data/booking_repository.dart';
import '../../features/staff_orders/data/staff_orders_repository.dart';
import '../../features/staff_scanner/data/staff_scanner_repository.dart';
import '../../features/transport/data/transport_repository.dart';
import '../../features/pins/data/datasources/pins_remote_datasource.dart';
import '../../features/pins/data/repositories/pins_repository_impl.dart';
import '../../features/pins/domain/repositories/pins_repository.dart';
import '../../features/payments/data/datasources/payments_remote_datasource.dart';
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/wallet/data/datasources/payment_approvals_remote_datasource.dart';
import '../../features/family_payments/data/datasources/family_payments_remote_datasource.dart';
import '../../features/family_payments/data/repositories/family_payments_repository_impl.dart';
import '../../features/family_payments/data/services/mercado_pago_card_tokenizer.dart';
import '../../features/family_payments/domain/repositories/family_payments_repository.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppConfig>()) {
    return;
  }

  final config = AppConfig.fromEnvironment();

  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerLazySingleton<AppLogger>(() => AppLogger(getIt<AppConfig>()))
    ..registerLazySingleton<SecureStorage>(
      () => FlutterSecureStorageAdapter(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        ),
      ),
    )
    ..registerLazySingleton<SessionManager>(
      () => SessionManager(getIt<SecureStorage>()),
    )
    ..registerLazySingleton<LocationService>(
      () => GeolocatorLocationService(getIt<SecureStorage>()),
    )
    ..registerLazySingleton<FirebaseAuthService>(FirebaseAuthService.new)
    ..registerLazySingleton<AppVersionService>(AppVersionService.new)
    ..registerLazySingleton<AppPermissionService>(
      () => DeviceAppPermissionService(getIt<LocationService>()),
    )
    ..registerLazySingleton<SelectedKidContext>(SelectedKidContext.new)
    ..registerLazySingleton<AuthTokenRefresher>(
      () => AuthTokenRefresher(
        config: getIt<AppConfig>(),
        sessionManager: getIt<SessionManager>(),
      ),
    )
    ..registerLazySingleton<NetworkClient>(
      () => NetworkClient(
        config: getIt<AppConfig>(),
        sessionManager: getIt<SessionManager>(),
        tokenRefresher: getIt<AuthTokenRefresher>(),
        logger: getIt<AppLogger>(),
      ),
    )
    ..registerLazySingleton<AnalyticsService>(
      () => const NoopAnalyticsService(),
    )
    ..registerLazySingleton<CrashReportingService>(
      () => const NoopCrashReportingService(),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => DioAuthRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ChatPaymentsRemoteDataSource>(
      () => ChatPaymentsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(getIt<ChatRemoteDataSource>()),
    )
    ..registerLazySingleton<ChatInboxRepository>(
      () => ChatInboxRepository(
        getIt<ChatRepository>(),
        getIt<FamilyChatRepository>(),
        getIt<VakupliRepository>(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: getIt<AuthRemoteDataSource>(),
        sessionManager: getIt<SessionManager>(),
      ),
    )
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => DioProfileRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt<ProfileRemoteDataSource>()),
    )
    ..registerLazySingleton<DiscoveryRemoteDataSource>(
      () => DioDiscoveryRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ActivityFeedRepository>(
      () => ActivityFeedRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<BusinessCategoriesRepository>(
      () => BusinessCategoriesRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<DeliveryRepository>(
      () => DeliveryRepositoryImpl(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<CashbackRepository>(
      () => CashbackRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<DiscoveryRepository>(
      () => DiscoveryRepositoryImpl(getIt<DiscoveryRemoteDataSource>()),
    )
    ..registerLazySingleton<FamilyChatRepository>(
      () => FamilyChatRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<FavoritesRemoteDataSource>(
      () => DioFavoritesRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<FavoritesRepository>(
      () => FavoritesRepositoryImpl(getIt<FavoritesRemoteDataSource>()),
    )
    ..registerLazySingleton<BonusesRemoteDataSource>(
      () => DioBonusesRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<BonusesRepository>(
      () => BonusesRepositoryImpl(getIt<BonusesRemoteDataSource>()),
    )
    ..registerLazySingleton<CampaignsRemoteDataSource>(
      () => DioCampaignsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<CampaignsRepository>(
      () => CampaignsRepositoryImpl(getIt<CampaignsRemoteDataSource>()),
    )
    ..registerLazySingleton<MediaRepository>(
      () => MediaRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<MembershipsRepository>(
      () => MembershipsRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<MembershipCubit>(
      () => MembershipCubit(getIt<MembershipsRepository>()),
    )
    ..registerLazySingleton<FirebaseStorageService>(
      FirebaseStorageService.new,
    )
    ..registerLazySingleton<LoyaltyRepository>(
      () => LoyaltyRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ProductCategoriesRepository>(
      () => ProductCategoriesRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<BookingRepository>(
      () => BookingRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<QrWalletRepository>(
      () => QrWalletRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<VakupliRepository>(
      () => VakupliRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<SecureShipmentRepository>(
      () => SecureShipmentRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<StaffScannerRepository>(
      () => StaffScannerRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<StaffOrdersRepository>(
      () => StaffOrdersRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<TransportRepository>(
      () => TransportRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<PaymentsRemoteDataSource>(
      () => DioPaymentsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<PaymentsRepository>(
      () => PaymentsRepositoryImpl(getIt<PaymentsRemoteDataSource>()),
    )
    ..registerLazySingleton<FamilyPaymentsRemoteDataSource>(
      () => DioFamilyPaymentsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<FamilyPaymentsRepository>(
      () => FamilyPaymentsRepositoryImpl(getIt<FamilyPaymentsRemoteDataSource>()),
    )
    ..registerLazySingleton<MercadoPagoCardTokenizer>(
      MercadoPagoCardTokenizer.new,
    )
    ..registerLazySingleton<WalletRemoteDataSource>(
      () => DioWalletRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<PaymentApprovalsRemoteDataSource>(
      () => PaymentApprovalsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(
        getIt<WalletRemoteDataSource>(),
        getIt<PaymentsRepository>(),
      ),
    )
    ..registerLazySingleton<PinsRemoteDataSource>(
      () => DioPinsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<PinsRepository>(
      () => PinsRepositoryImpl(getIt<PinsRemoteDataSource>()),
    )
    ..registerLazySingleton<ReceiptsRemoteDataSource>(
      () => DioReceiptsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ReceiptsRepository>(
      () => ReceiptsRepositoryImpl(getIt<ReceiptsRemoteDataSource>()),
    )
    ..registerLazySingleton<FinancialHistoryRemoteDataSource>(
      () => DioFinancialHistoryRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<FinancialHistoryRepository>(
      () => FinancialHistoryRepositoryImpl(
        getIt<FinancialHistoryRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<KidsRemoteDataSource>(
      () => DioKidsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<KidsRepository>(
      () => KidsRepositoryImpl(getIt<KidsRemoteDataSource>()),
    )
    ..registerLazySingleton<KidAuthRemoteDataSource>(
      () => DioKidAuthRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<KidAuthRepository>(
      () => KidAuthRepositoryImpl(getIt<KidAuthRemoteDataSource>()),
    )
    ..registerLazySingleton<KidMeRepository>(
      () => KidMeRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<UserSearchRepository>(
      () => UserSearchRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<GeoRepository>(
      () => GeoRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ExchangeRateRepository>(
      () => ExchangeRateRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ContactsMatcher>(
      () => ContactsMatcher(
        getIt<UserSearchRepository>(),
        getIt<AppPermissionService>(),
      ),
    )
    ..registerLazySingleton<NotificationEventsListener>(
      () => NotificationEventsListener(
        getIt<AppConfig>(),
        getIt<SessionManager>(),
        getIt<NotificationsSync>(),
      ),
    )
    ..registerLazySingleton<KycRepository>(
      () => KycRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ClientLocationRepository>(
      () => ClientLocationRepository(
        client: getIt<NetworkClient>(),
        locationService: getIt<LocationService>(),
        storage: getIt<SecureStorage>(),
      ),
    )
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => DioNotificationsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(getIt<NotificationsRemoteDataSource>()),
    )
    ..registerLazySingleton<NotificationsSync>(NotificationsSync.new)
    ..registerLazySingleton<CiervoPushService>(
      () => CiervoPushService(
        getIt<NotificationsRemoteDataSource>(),
        getIt<SessionManager>(),
      ),
    )
    ..registerFactory<NotificationBadgesCubit>(
      () => NotificationBadgesCubit(getIt<NotificationsRepository>()),
    )
    ..registerLazySingleton<BusinessDetailRepository>(
      () => BusinessDetailRepository(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<ReviewRepository>(
      () => ReviewRepository(getIt<NetworkClient>()),
    );
}
