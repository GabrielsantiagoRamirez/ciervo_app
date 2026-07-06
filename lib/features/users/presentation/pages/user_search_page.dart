import 'package:flutter/material.dart';

import '../../../../core/contacts/contacts_matcher.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/permissions/permission_kind.dart';
import '../../../../core/permissions/permission_manager.dart';
import '../../../../core/permissions/widgets/permission_denied_state.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/pages/chat_conversation_page.dart';
import '../../../chat_payments/presentation/pages/chat_gift_page.dart';
import '../../../chat_payments/presentation/pages/chat_pay_page.dart';
import '../../../wallet/presentation/pages/recharge_by_ciervo_id_page.dart';
import '../../../wallet/presentation/pages/request_money_page.dart';
import '../../../safety/data/models/safety_models.dart';
import '../../../safety/data/services/safety_filter_cache.dart';
import '../../../safety/domain/repositories/safety_repository.dart';
import '../../../safety/presentation/widgets/safety_sheets.dart';
import '../../data/user_search_repository.dart';
import '../../domain/entities/user_search_result.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({
    this.selectMode = false,
    this.pickRecipient = false,
    super.key,
  });

  /// Si es true, devuelve el userId seleccionado con Navigator.pop.
  final bool selectMode;

  /// Si es true, devuelve el [UserSearchResult] al tocar una persona.
  final bool pickRecipient;

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _controller = TextEditingController();
  bool _includeOtherCountries = false;
  bool _loading = false;
  String? _error;
  bool _isValidationHint = false;
  bool _contactsPermissionDenied = false;
  List<UserSearchResult> _results = const [];
  String? _openingUserId;

  @override
  void initState() {
    super.initState();
    getIt<SafetyRepository>().refreshLocalFilters();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _matchContacts() async {
    setState(() {
      _loading = true;
      _error = null;
      _isValidationHint = false;
      _contactsPermissionDenied = false;
    });

    final granted = await PermissionManager.instance.ensure(
      context,
      AppPermissionKind.contacts,
    );
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _loading = false;
        _contactsPermissionDenied = true;
        _results = const [];
      });
      return;
    }

    final result = await getIt<ContactsMatcher>().matchDeviceContacts();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        final cache = getIt<SafetyFilterCache>();
        _results = items
            .where((user) => !cache.isUserBlocked(user.userId))
            .toList();
        _loading = false;
        _error = _results.isEmpty
            ? 'No encontramos contactos registrados en Ciervo.'
            : null;
        _isValidationHint = _results.isEmpty;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
        _results = const [];
        _isValidationHint = false;
      }),
    );
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _error = null;
        _isValidationHint = true;
        _results = const [];
        _contactsPermissionDenied = false;
      });
      return;
    }
    if (query.length < 2) {
      setState(() {
        _error = 'Escribe al menos 2 caracteres para buscar.';
        _isValidationHint = true;
        _results = const [];
        _contactsPermissionDenied = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _isValidationHint = false;
      _contactsPermissionDenied = false;
    });

    double? latitude;
    double? longitude;
    try {
      final location = await getIt<LocationService>().currentLocation();
      latitude = location.latitude;
      longitude = location.longitude;
    } catch (_) {}

    final result = await getIt<UserSearchRepository>().search(
      query: query,
      includeOtherCountries: _includeOtherCountries,
      latitude: latitude,
      longitude: longitude,
      sortBy: 'distance',
    );
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        final cache = getIt<SafetyFilterCache>();
        _results = items
            .where((user) => !cache.isUserBlocked(user.userId))
            .toList();
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
        _results = const [];
      }),
    );
  }

  Future<void> _openDirectChat(UserSearchResult user) async {
    if (_openingUserId != null) return;
    setState(() => _openingUserId = user.userId);
    final result = await getIt<ChatRepository>().createDirectConversation(
      targetUserId: user.userId,
    );
    if (!mounted) return;
    setState(() => _openingUserId = null);
    result.when(
      success: (conversation) async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatConversationPage(
              conversationId: conversation.id,
              title: user.fullName,
            ),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _showUserActions(UserSearchResult user) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child:
                    user.photoUrl == null ? const Icon(Icons.person_outline) : null,
              ),
              title: Text(user.fullName),
              subtitle: Text(
                DisplayFormatters.identityLine(
                  username: user.username,
                  displayName: user.fullName,
                  ciervoId: user.ciervoUserCode,
                ).isEmpty
                    ? [
                        if (user.distanceLabel != null) user.distanceLabel,
                        if (user.city != null) user.city,
                        if (user.country != null) user.country,
                      ].whereType<String>().join(' · ')
                    : DisplayFormatters.identityLine(
                        username: user.username,
                        displayName: user.fullName,
                        ciervoId: user.ciervoUserCode,
                      ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Abrir chat'),
              onTap: () {
                Navigator.pop(context);
                _openDirectChat(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Pagar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(this.context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatPayPage(
                      initialTargetCiervoCode: user.ciervoUserCode,
                      initialTargetUserId: user.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_outlined),
              title: const Text('Enviar regalo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(this.context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatGiftPage(
                      initialTargetCiervoCode: user.ciervoUserCode,
                      initialTargetUserId: user.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.request_page_outlined),
              title: const Text('Paga por mi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(this.context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RequestMoneyPage(
                      initialPayerCiervoCode: user.ciervoUserCode,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: const Text('Recargar por CIERVO ID'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(this.context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RechargeByCiervoIdPage(
                      initialCiervoCode: user.ciervoUserCode,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Reportar usuario'),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(
                  this.context,
                  targetType: ReportTargetType.user,
                  reportedUserId: int.tryParse(user.userId),
                  subjectLabel: user.fullName,
                  allowBlockUser: true,
                  onCompleted: () => setState(
                    () => _results = _results
                        .where((item) => item.userId != user.userId)
                        .toList(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear usuario'),
              onTap: () {
                Navigator.pop(context);
                showBlockUserFlow(
                  this.context,
                  userId: int.tryParse(user.userId) ?? 0,
                  displayName: user.fullName,
                  onBlocked: () => setState(
                    () => _results = _results
                        .where((item) => item.userId != user.userId)
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.pickRecipient
            ? 'Elegir destinatario'
            : widget.selectMode
                ? 'Invitar amigo'
                : 'Buscar personas',
      ),
    ),
    body: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Nombre, @usuario o CIERVO ID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _loading ? null : _search,
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Incluir otros países'),
          value: _includeOtherCountries,
          onChanged: _loading
              ? null
              : (value) => setState(() => _includeOtherCountries = value),
        ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _matchContacts,
          icon: const Icon(Icons.contacts_outlined),
          label: const Text('Buscar en mis contactos'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_loading) const LinearProgressIndicator(),
        if (_contactsPermissionDenied) ...[
          const SizedBox(height: AppSpacing.md),
          PermissionDeniedState(
            kind: AppPermissionKind.contacts,
            onRetry: _matchContacts,
          ),
        ] else if (_error != null && !_isValidationHint) ...[
          const SizedBox(height: AppSpacing.md),
          CiervoErrorState(
            title: 'No pudimos buscar ahora',
            description: _error!,
            onRetry: _search,
          ),
        ] else if (_isValidationHint && _error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ] else if (!_loading &&
            _error == null &&
            _results.isEmpty &&
            _controller.text.trim().isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Busca por nombre, teléfono o usuario para invitar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        if (!_loading && _error == null && _results.isEmpty && _controller.text.trim().length >= 2)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: CiervoEmptyState(
              title: 'Sin resultados',
              description: 'No encontramos contactos con esa búsqueda.',
              icon: Icons.person_search_outlined,
            ),
          ),
        ..._results.map((user) {
          final opening = _openingUserId == user.userId;
          final identity = DisplayFormatters.identityLine(
            username: user.username,
            displayName: user.fullName,
            ciervoId: user.ciervoUserCode,
          );
          final subtitle = [
            if (identity.isNotEmpty) identity,
            if (user.phoneMasked != null) user.phoneMasked,
            if (user.matchedByPhone) 'Contacto del teléfono',
            if (user.distanceLabel != null) user.distanceLabel,
            if (user.distanceKm == null && user.city != null) user.city,
            if (user.country != null) user.country,
          ].join(' · ');
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(user.fullName),
            subtitle: subtitle.isEmpty
                ? const Text('Sin ubicación')
                : Text(subtitle),
            trailing: opening
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : user.canStartConversation
                    ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'chat') {
                            _openDirectChat(user);
                          } else if (value == 'more') {
                            _showUserActions(user);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'chat',
                            child: Text('Abrir chat'),
                          ),
                          PopupMenuItem(
                            value: 'more',
                            child: Text('Mas acciones'),
                          ),
                        ],
                      )
                    : const Icon(Icons.block, size: 20),
            onTap: user.canStartConversation && !opening
                ? () {
                    if (widget.pickRecipient) {
                      if (user.ciervoUserCode == null ||
                          user.ciervoUserCode!.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Esta persona aún no tiene CIERVO ID público.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(user);
                      return;
                    }
                    if (widget.selectMode) {
                      Navigator.of(context).pop(user.userId);
                      return;
                    }
                    _openDirectChat(user);
                  }
                : null,
            onLongPress: user.canStartConversation && !widget.selectMode
                ? () => _showUserActions(user)
                : null,
          );
        }),
      ],
    ),
  );
}
