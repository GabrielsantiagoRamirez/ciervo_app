import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/transfer_directory_entry.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'ciervo_digital_card.dart';

Future<TransferDirectoryEntry?> showTransferDirectoryListSheet(
  BuildContext context, {
  required String title,
  required Future<List<TransferDirectoryEntry>> Function() loader,
  bool showFavoriteToggle = false,
}) {
  return showModalBottomSheet<TransferDirectoryEntry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TransferDirectoryListSheet(
      title: title,
      loader: loader,
      showFavoriteToggle: showFavoriteToggle,
    ),
  );
}

class _TransferDirectoryListSheet extends StatefulWidget {
  const _TransferDirectoryListSheet({
    required this.title,
    required this.loader,
    required this.showFavoriteToggle,
  });

  final String title;
  final Future<List<TransferDirectoryEntry>> Function() loader;
  final bool showFavoriteToggle;

  @override
  State<_TransferDirectoryListSheet> createState() =>
      _TransferDirectoryListSheetState();
}

class _TransferDirectoryListSheetState
    extends State<_TransferDirectoryListSheet> {
  late Future<List<TransferDirectoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  Future<void> _reload() async {
    setState(() => _future = widget.loader());
  }

  Future<void> _toggleFavorite(TransferDirectoryEntry entry) async {
    final repo = getIt<WalletRepository>();
    final result = entry.isFavorite
        ? await repo.removeTransferFavorite(entry.userId)
        : await repo.addTransferFavorite(
            targetUserId: entry.userId.isNotEmpty ? entry.userId : null,
            targetCiervoUserCode: entry.ciervoUserCode,
            targetUsername: entry.username,
          );
    if (!mounted) return;
    result.when(
      success: (_) => _reload(),
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<TransferDirectoryEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const CiervoLoadingState(itemCount: 4);
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: CiervoEmptyState(
                        title: 'No pudimos cargar la lista',
                        description: UserErrorMessage.from(snapshot.error!),
                        icon: Icons.error_outline,
                      ),
                    );
                  }
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CiervoEmptyState(
                        title: 'Sin resultados',
                        description:
                            'Cuando tengas transferencias o contactos CIERVO, aparecerán aquí.',
                        icon: Icons.people_outline,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final entry = items[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: CiervoBrandColors.gold.withValues(
                              alpha: 0.15,
                            ),
                            backgroundImage:
                                entry.photoUrl != null &&
                                    entry.photoUrl!.isNotEmpty
                                ? NetworkImage(entry.photoUrl!)
                                : null,
                            child:
                                entry.photoUrl == null ||
                                    entry.photoUrl!.isEmpty
                                ? Text(
                                    entry.displayName.isNotEmpty
                                        ? entry.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: CiervoBrandColors.gold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            entry.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              entry.subtitle,
                              if (entry.lastTransferLabel != null)
                                entry.lastTransferLabel!,
                            ].where((s) => s.trim().isNotEmpty).join('\n'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: widget.showFavoriteToggle
                              ? IconButton(
                                  tooltip: entry.isFavorite
                                      ? 'Quitar de favoritos'
                                      : 'Agregar a favoritos',
                                  onPressed: () => _toggleFavorite(entry),
                                  icon: Icon(
                                    entry.isFavorite
                                        ? Icons.star
                                        : Icons.star_outline,
                                    color: CiervoBrandColors.gold,
                                  ),
                                )
                              : entry.isFavorite
                              ? const Icon(
                                  Icons.star,
                                  color: CiervoBrandColors.gold,
                                  size: 20,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pop(entry),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
