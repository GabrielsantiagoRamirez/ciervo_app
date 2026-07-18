import 'package:flutter/material.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../domain/models/movie_models.dart';

Future<bool?> showMovieShareSheet({
  required BuildContext context,
  required MovieSummary movie,
  required ChatRepository repository,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MovieShareSheet(movie: movie, repository: repository),
);

class _MovieShareSheet extends StatefulWidget {
  const _MovieShareSheet({required this.movie, required this.repository});

  final MovieSummary movie;
  final ChatRepository repository;

  @override
  State<_MovieShareSheet> createState() => _MovieShareSheetState();
}

class _MovieShareSheetState extends State<_MovieShareSheet> {
  final _message = TextEditingController();
  List<ChatConversation> _conversations = const [];
  bool _loading = true;
  String? _sharingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.conversations();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _conversations = items.where((item) => item.canSend).toList();
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _share(ChatConversation conversation) async {
    setState(() {
      _sharingId = conversation.id;
      _error = null;
    });
    final result = await widget.repository.shareMovie(
      movieId: widget.movie.id,
      conversationId: conversation.id,
      message: _message.text,
    );
    if (!mounted) return;
    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (error) => setState(() {
        _sharingId = null;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Compartir “${widget.movie.title}”',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                hintText: 'Agrega un comentario',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    ),
  );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _conversations.isEmpty) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }
    if (_conversations.isEmpty) {
      return const Center(
        child: Text(
          'No tienes conversaciones abiertas disponibles.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final sharing = _sharingId == conversation.id;
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.chat_outlined)),
          title: Text(conversation.title),
          subtitle: Text(_conversationTypeLabel(conversation.type)),
          trailing: sharing
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          enabled: _sharingId == null,
          onTap: () => _share(conversation),
        );
      },
    );
  }
}

String _conversationTypeLabel(String type) => switch (type.toLowerCase()) {
  'direct' => 'Conversación privada',
  'business' => 'Negocio',
  'family' => 'Familia',
  'support' => 'Soporte',
  _ => 'Conversación',
};
