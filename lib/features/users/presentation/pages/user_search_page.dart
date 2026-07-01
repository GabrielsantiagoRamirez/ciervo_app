import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/pages/chat_conversation_page.dart';
import '../../../chat_payments/presentation/pages/chat_gift_page.dart';
import '../../../chat_payments/presentation/pages/chat_pay_page.dart';
import '../../../wallet/presentation/pages/recharge_by_ciervo_id_page.dart';
import '../../../wallet/presentation/pages/request_money_page.dart';
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
  List<UserSearchResult> _results = const [];
  String? _openingUserId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2) {
      setState(() {
        _error = 'Escribe al menos 2 caracteres para buscar.';
        _results = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
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
        _results = items;
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
                [
                  if (user.ciervoUserCode != null) user.ciervoUserCode,
                  if (user.distanceLabel != null) user.distanceLabel,
                  if (user.city != null) user.city,
                  if (user.country != null) user.country,
                ].whereType<String>().join(' · '),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Nombre o usuario',
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
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          CiervoErrorState(
            title: 'Búsqueda no disponible',
            description: _error!,
            onRetry: _search,
          ),
        ],
        if (!_loading && _error == null && _results.isEmpty && _controller.text.trim().length >= 2)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: CiervoEmptyState(
              title: 'Sin resultados',
              description: 'No encontramos personas con ese nombre.',
              icon: Icons.person_search_outlined,
            ),
          ),
        ..._results.map((user) {
          final opening = _openingUserId == user.userId;
          final subtitle = [
            if (user.ciervoUserCode != null) user.ciervoUserCode,
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
