import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../analytics/analytics_service.dart';
import '../config/app_config.dart';
import '../crash/crash_reporting_service.dart';
import '../device/device_installation_service.dart';
import '../logging/app_logger.dart';
import '../network/auth_token_refresher.dart';
import '../network/network_client.dart';
import '../permissions/app_permission_service.dart';
import '../session/session_manager.dart';
import '../storage/secure_storage.dart';
import '../version/app_version_service.dart';
import '../auth/auth_bootstrap_service.dart';
import '../auth/auth_pending_registration_store.dart';
import '../firebase/firebase_auth_service.dart';
import '../location/location_service.dart';
import '../kids/selected_kid_context.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/chat/data/chat_empty_dismiss_store.dart';
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
import '../../features/marketplace/data/marketplace_remote_datasource.dart';
import '../../features/marketplace/data/marketplace_repository_impl.dart';
import '../../features/marketplace/domain/repositories/marketplace_repository.dart';
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
import '../../features/universal_nfc/data/datasources/universal_nfc_remote_datasource.dart';
import '../../features/universal_nfc/data/repositories/universal_nfc_repository_impl.dart';
import '../../features/universal_nfc/domain/repositories/universal_nfc_repository.dart';
import '../../features/kid_auth/data/datasources/kid_auth_remote_datasource.dart';
import '../../features/kid_auth/data/repositories/kid_auth_repository_impl.dart';
import '../../features/kid_me/data/kid_me_repository.dart';
import '../../features/kids_v2/data/datasources/kids_v2_remote_datasource.dart'
    as kids_v2_ds;
import '../../features/kids_v2/data/repositories/kids_v2_repositories.dart'
    as kids_v2_repo;
import '../../features/master_kids/data/datasources/master_kids_remote_datasource.dart'
    as master_ds;
import '../../features/master_kids/data/repositories/master_kids_repository.dart'
    as master_repo;
import '../../features/business_nfc/data/business_nfc_remote_datasource.dart';
import '../../features/business_nfc/data/business_nfc_repository.dart';
import '../../features/catalogs/data/catalog_repository.dart';
import '../../features/exchange/data/exchange_rate_repository.dart';
import '../../features/kyc/data/kyc_repository.dart';
import '../../features/search/data/datasources/global_search_remote_datasource.dart';
import '../../features/search/data/repositories/global_search_repository_impl.dart';
import '../../features/search/domain/repositories/global_search_repository.dart';
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
import '../../features/promotions/data/promotions_repository.dart';
import '../../features/product_categories/data/product_categories_repository.dart';
import '../../features/qr_hub/data/qr_scan_repository.dart';
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
import '../../features/move/data/datasources/move_remote_datasource.dart';
import '../../features/move/data/media/move_media_repository.dart';
import '../../features/move/data/onboarding/move_onboarding_remote_datasource.dart';
import '../../features/move/data/onboarding/move_onboarding_repository_impl.dart';
import '../../features/move/data/onboarding/release_terms_configuration_repository.dart';
import '../../features/move/data/onboarding/secure_move_onboarding_draft_store.dart';
import '../../features/move/data/repositories/move_repository_impl.dart';
import '../../features/move/domain/onboarding/move_onboarding_draft.dart';
import '../../features/move/domain/onboarding/move_onboarding_repository.dart';
import '../../features/move/domain/onboarding/move_terms_configuration.dart';
import '../../features/move/domain/repositories/move_repository.dart';
import '../../features/movie/data/datasources/movie_remote_datasource.dart';
import '../../features/movie/data/realtime/movie_realtime_service.dart';
import '../../features/movie/data/realtime/movie_realtime_cursor_store.dart';
import '../../features/movie/data/repositories/movie_repository_impl.dart';
import '../../features/movie/domain/repositories/movie_repository.dart';
import '../../features/movie/presentation/cubit/movie_cubit.dart';
import '../../features/movie/presentation/cubit/movie_realtime_cubit.dart';
import '../../features/tickets/data/datasources/tickets_remote_datasource.dart';
import '../../features/tickets/data/repositories/tickets_repository_impl.dart';
import '../../features/tickets/domain/repositories/tickets_repository.dart';
import '../../features/pins/data/datasources/pins_remote_datasource.dart';
import '../../features/pins/data/durable_pin_service.dart';
import '../../features/pins/data/pin_p2p_service.dart';
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
import '../../features/wallet/data/stores/wallet_recharge_session_store.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/safety/data/datasources/safety_remote_datasource.dart';
import '../../features/safety/data/repositories/safety_repository_impl.dart';
import '../../features/safety/data/services/safety_filter_cache.dart';
import '../../features/safety/domain/repositories/safety_repository.dart';

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
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ),
      ),
    )
    ..registerLazySingleton<SessionManager>(
      () => SessionManager(getIt<SecureStorage>()),
    )
    ..registerLazySingleton<DeviceInstallationService>(
      () => DeviceInstallationService(getIt<SecureStorage>()),
    )
    ..registerLazySingleton<LocationService>(
      () => GeolocatorLocationService(getIt<SecureStorage>()),
    )
    ..registerLazySingleton<FirebaseAuthService>(FirebaseAuthService.new)
    ..registerLazySingleton<AuthPendingRegistrationStore>(
      AuthPendingRegistrationStore.new,
    )
    ..registerLazySingleton<AuthStartupMessageStore>(
      AuthStartupMessageStore.new,
    )
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
    ..registerLazySingleton<ChatEmptyDismissStore>(
      () => ChatEmptyDismissStore(getIt<SecureStorage>()),
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
        firebaseAuthService: getIt<FirebaseAuthService>(),
      ),
    )
    ..registerLazySingleton<AuthBootstrapService>(
      () => AuthBootstrapService(
        sessionManager: getIt<SessionManager>(),
        firebaseAuth: getIt<FirebaseAuthService>(),
        authRepository: getIt<AuthRepository>(),
        tokenRefresher: getIt<AuthTokenRefresher>(),
        pendingRegistration: getIt<AuthPendingRegistrationStore>(),
        startupMessage: getIt<AuthStartupMessageStore>(),
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
    ..registerLazySingleton<MarketplaceRemoteDataSource>(
      () => MarketplaceRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<MarketplaceRepository>(
      () => MarketplaceRepositoryImpl(getIt<MarketplaceRemoteDataSource>()),
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
    ..registerLazySingleton<FirebaseStorageService>(FirebaseStorageService.new)
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
    ..registerLazySingleton<QrScanRepository>(
      () => QrScanRepository(getIt<NetworkClient>()),
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
    ..registerLazySingleton<MoveRemoteDataSource>(
      () => MoveRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<MoveRepository>(
      () => MoveRepositoryImpl(getIt<MoveRemoteDataSource>()),
    )
    ..registerLazySingleton<MoveOnboardingRemoteDataSource>(
      () => DioMoveOnboardingRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<MoveOnboardingRepository>(
      () =>
          MoveOnboardingRepositoryImpl(getIt<MoveOnboardingRemoteDataSource>()),
    )
    ..registerLazySingleton<MoveOnboardingDraftStore>(
      () => SecureMoveOnboardingDraftStore(getIt<SecureStorage>()),
    )
    ..registerLazySingleton<TermsConfigurationRepository>(
      () => ReleaseTermsConfigurationRepository(getIt<AppConfig>()),
    )
    ..registerLazySingleton<MoveMediaRepository>(
      () => MoveMediaRepository(
        client: getIt<NetworkClient>(),
        sessionManager: getIt<SessionManager>(),
      ),
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
      () =>
          FamilyPaymentsRepositoryImpl(getIt<FamilyPaymentsRemoteDataSource>()),
    )
    ..registerLazySingleton<UniversalNfcRemoteDataSource>(
      () => DioUniversalNfcRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<UniversalNfcRepository>(
      () => UniversalNfcRepositoryImpl(getIt<UniversalNfcRemoteDataSource>()),
    )
    ..registerLazySingleton<MercadoPagoCardTokenizer>(
      MercadoPagoCardTokenizer.new,
    )
    ..registerLazySingleton<WalletRemoteDataSource>(
      () => DioWalletRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<WalletRechargeSessionStore>(
      () => WalletRechargeSessionStore(getIt<SecureStorage>()),
    )
    ..registerLazySingleton<PaymentApprovalsRemoteDataSource>(
      () => PaymentApprovalsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(
        getIt<WalletRemoteDataSource>(),
        getIt<ProfileRepository>(),
        getIt<WalletRechargeSessionStore>(),
        logger: getIt<AppLogger>(),
      ),
    )
    ..registerLazySingleton<PinsRemoteDataSource>(
      () => DioPinsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<PinsRepository>(
      () => PinsRepositoryImpl(getIt<PinsRemoteDataSource>()),
    )
    ..registerLazySingleton<DurablePinService>(
      () => DurablePinService(
        client: getIt<NetworkClient>(),
        storage: getIt<SecureStorage>(),
      ),
    )
    ..registerLazySingleton<PinP2PService>(
      () => PinP2PService(getIt<NetworkClient>()),
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
      () => DioKidAuthRemoteDataSource(
        getIt<NetworkClient>(),
        getIt<DeviceInstallationService>(),
        getIt<AppVersionService>(),
      ),
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
    ..registerLazySingleton<GlobalSearchRemoteDataSource>(
      () => GlobalSearchRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<GlobalSearchRepository>(
      () => GlobalSearchRepositoryImpl(getIt<GlobalSearchRemoteDataSource>()),
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
        getIt<SecureStorage>(),
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
      () => DioNotificationsRemoteDataSource(
        getIt<NetworkClient>(),
        getIt<DeviceInstallationService>(),
        getIt<AppVersionService>(),
      ),
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
    )
    ..registerLazySingleton<SafetyFilterCache>(SafetyFilterCache.new)
    ..registerLazySingleton<SafetyRemoteDataSource>(
      () => DioSafetyRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<SafetyRepository>(
      () => SafetyRepositoryImpl(
        getIt<SafetyRemoteDataSource>(),
        getIt<SafetyFilterCache>(),
      ),
    )
    ..registerLazySingleton<PromotionsRepository>(
      () =>
          PromotionsRepository(getIt<NetworkClient>(), getIt<SecureStorage>()),
    )
    ..registerLazySingleton<MovieRemoteDataSource>(
      () => DioMovieRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<MovieRepository>(
      () => MovieRepositoryImpl(getIt<MovieRemoteDataSource>()),
    )
    ..registerLazySingleton<TicketsRemoteDataSource>(
      () => DioTicketsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<TicketsRepository>(
      () => TicketsRepositoryImpl(getIt<TicketsRemoteDataSource>()),
    )
    ..registerFactory<MovieRealtimeService>(
      () => MovieRealtimeService(getIt<MovieRepository>()),
    )
    ..registerLazySingleton<MovieRealtimeCursorStore>(
      () => MovieRealtimeCursorStore(
        getIt<SecureStorage>(),
        getIt<SessionManager>(),
      ),
    )
    ..registerFactory<MovieCubit>(() => MovieCubit(getIt<MovieRepository>()))
    ..registerFactory<MovieRealtimeCubit>(
      () => MovieRealtimeCubit(
        getIt<MovieRealtimeService>(),
        cursorStore: getIt<MovieRealtimeCursorStore>(),
      ),
    )
    ..registerLazySingleton<kids_v2_ds.KidsV2RemoteDataSource>(
      () => kids_v2_ds.DioKidsV2RemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<kids_v2_repo.KidSessionStore>(
      () => kids_v2_repo.SessionManagerKidSessionStore(getIt<SessionManager>()),
    )
    ..registerLazySingleton<kids_v2_repo.KidsAuthRepository>(
      () => kids_v2_repo.KidsAuthRepositoryImpl(
        getIt<kids_v2_ds.KidsV2RemoteDataSource>(),
        getIt<kids_v2_repo.KidSessionStore>(),
      ),
    )
    ..registerLazySingleton<kids_v2_repo.KidsRepository>(
      () => kids_v2_repo.KidsRepositoryImpl(
        getIt<kids_v2_ds.KidsV2RemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<kids_v2_repo.KidsRealtimeRepository>(
      () => kids_v2_repo.KidsRealtimeRepositoryImpl(
        getIt<kids_v2_ds.KidsV2RemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<master_ds.MasterKidsRemoteDataSource>(
      () => master_ds.DioMasterKidsRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<master_repo.MasterKidsRepository>(
      () => master_repo.MasterKidsRepositoryImpl(
        getIt<master_ds.MasterKidsRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<BusinessNfcRemoteDataSource>(
      () => DioBusinessNfcRemoteDataSource(getIt<NetworkClient>()),
    )
    ..registerLazySingleton<BusinessNfcRepository>(
      () => BusinessNfcRepositoryImpl(getIt<BusinessNfcRemoteDataSource>()),
    );
}
