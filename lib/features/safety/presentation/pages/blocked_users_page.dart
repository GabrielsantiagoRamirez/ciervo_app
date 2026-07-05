import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../data/models/safety_models.dart';
import '../../domain/repositories/safety_repository.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  bool _loading = true;
  String? _error;
  List<BlockedUserModel> _users = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await getIt<SafetyRepository>().blockedUsers();
    if (!mounted) return;
    result.when(
      success: (users) => setState(() {
        _users = users;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _unblock(BlockedUserModel user) async {
    final result = await getIt<SafetyRepository>().unblockUser(user.userId);
    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() => _users = _users.where((x) => x.userId != user.userId).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario desbloqueado.')),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Usuarios bloqueados')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? CiervoErrorState(
                    title: 'No pudimos cargar',
                    description: _error!,
                    onRetry: _load,
                  )
                : _users.isEmpty
                    ? const CiervoEmptyState(
                        icon: Icons.people_outline,
                        title: 'Sin bloqueos',
                        description: 'No tienes usuarios bloqueados.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return CiervoCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? const Icon(Icons.person_outline)
                                    : null,
                              ),
                              title: Text(user.displayName ?? 'Usuario CIERVO'),
                              subtitle: user.ciervoUserCode != null
                                  ? Text('CIERVO ID: ${user.ciervoUserCode}')
                                  : null,
                              trailing: TextButton(
                                onPressed: () => _unblock(user),
                                child: const Text('Desbloquear'),
                              ),
                            ),
                          );
                        },
                      ),
      );
}
