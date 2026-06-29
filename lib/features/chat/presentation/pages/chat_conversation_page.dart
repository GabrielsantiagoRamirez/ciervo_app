import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../widgets/chat_button_handler.dart';
import '../widgets/chat_buttons_bar.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ChatConversationPage extends StatelessWidget {
  const ChatConversationPage({
    required this.conversationId,
    this.title,
    super.key,
  });
  final String conversationId;
  final String? title;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ChatCubit(getIt<ChatRepository>())..open(conversationId),
    child: _ConversationView(
      title: title,
      conversationId: conversationId,
    ),
  );
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({
    this.title,
    required this.conversationId,
  });
  final String? title;
  final String conversationId;
  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 160) {
        context.read<ChatCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ChatCubit, ChatState>(
    listener: (context, state) {
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    },
    builder: (context, state) => Scaffold(
      appBar: AppBar(
        title: Text(state.conversation?.title ?? widget.title ?? 'Chat'),
        actions: [
          IconButton(
            tooltip: 'Acciones del chat',
            icon: const Icon(Icons.apps_outlined),
            onPressed: state.conversation?.canSend == false
                ? null
                : () => showChatButtonsSheet(
                      context,
                      buttons: state.chatButtons,
                      conversationId: widget.conversationId,
                    ),
          ),
        ],
      ),
      body: state.status == ChatStatus.loading
          ? const CiervoBrandLoader(message: 'Abriendo chat')
          : state.status == ChatStatus.failure && state.messages.isEmpty
          ? CiervoErrorState(
              title: 'No pudimos abrir el chat',
              description: state.errorMessage ?? 'Intenta nuevamente.',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount:
                        state.messages.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final message = state.messages[index];
                      return Align(
                        alignment: message.isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .78,
                          ),
                          decoration: BoxDecoration(
                            color: message.isMine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: message.bookingReceipt != null
                              ? _BookingReceiptCard(
                                  receipt: message.bookingReceipt!,
                                )
                              : _MessageContent(message: message),
                        ),
                      );
                    },
                  ),
                ),
                if (state.conversation?.canSend == false)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Esta conversacion esta cerrada y no acepta mensajes.',
                    ),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChatButtonsBar(
                        buttons: state.chatButtons,
                        conversationId: widget.conversationId,
                        enabled: !state.isSending,
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  enabled: !state.isSending,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _send(context),
                                  decoration: const InputDecoration(
                                    hintText: 'Escribe un mensaje',
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Compartir ubicacion',
                                onPressed: state.isSending
                                    ? null
                                    : () => _shareLocation(context),
                                icon: const Icon(Icons.location_on_outlined),
                              ),
                              IconButton(
                                tooltip: 'Enviar imagen',
                                onPressed: state.isSending
                                    ? null
                                    : () => _pickAndSendMedia(context),
                                icon: const Icon(Icons.attach_file),
                              ),
                              IconButton(
                                onPressed: state.isSending
                                    ? null
                                    : () => _send(context),
                                icon: state.isSending
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    ),
  );

  Future<void> _send(BuildContext context) async {
    final sent = await context.read<ChatCubit>().send(_controller.text);
    if (sent) _controller.clear();
  }

  Future<void> _pickAndSendMedia(BuildContext context) async {
    final media = await ImagePicker().pickMedia();
    if (media == null || !context.mounted) return;
    context.read<ChatCubit>().sendMedia(media.path, media.name);
  }

  Future<void> _shareLocation(BuildContext context) async {
    try {
      final location = await getIt<LocationService>().currentLocation();
      if (!context.mounted) return;
      await context.read<ChatCubit>().sendLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos obtener tu ubicacion.')),
      );
    }
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.sharePayload != null) {
      return _ShareCard(payload: message.sharePayload!);
    }
    if (message.paymentPayload != null) {
      return _PaymentCard(payload: message.paymentPayload!);
    }
    if (message.giftPayload != null) {
      return _GiftCard(payload: message.giftPayload!);
    }
    if (message.locationPayload != null) {
      return _LocationCard(payload: message.locationPayload!);
    }
    final attachment = message.attachmentUrl;
    if (attachment == null || attachment.isEmpty) return Text(message.body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (attachment.startsWith('http'))
          Text('Adjunto: $attachment')
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AuthenticatedMediaImage(
              mediaId: attachment,
              thumbnail: true,
              width: 220,
              height: 160,
              errorWidget: const SizedBox(
                width: 220,
                height: 120,
                child: Center(child: Icon(Icons.attach_file)),
              ),
            ),
          ),
        if (message.body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(message.body),
        ],
      ],
    );
  }
}

class _BookingReceiptCard extends StatelessWidget {
  const _BookingReceiptCard({required this.receipt});
  final BookingReceipt receipt;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [
        const Icon(Icons.receipt_long_outlined, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            receipt.publicCode,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ]),
      const Divider(),
      _line('Negocio', receipt.business),
      _line('Cliente', receipt.client),
      _line(
        'Fecha',
        receipt.bookingDate?.toLocal().toString().substring(0, 16) ??
            'Sin informacion',
      ),
      _line('Tipo', receipt.bookingType),
      _line('Estado', receipt.status),
      _line(
        'Total',
        receipt.total == null
            ? 'Por definir'
            : '${receipt.total} ${receipt.currency}',
      ),
    ],
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Text('$label: $value'),
  );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.payload});
  final ChatLocationPayload payload;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.location_on_outlined, size: 20),
          SizedBox(width: 8),
          Text('Ubicacion'),
        ],
      ),
      if (payload.label != null) Text(payload.label!),
      Text(
        '${payload.latitude.toStringAsFixed(5)}, ${payload.longitude.toStringAsFixed(5)}',
      ),
    ],
  );
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.payload});
  final ChatSharePayload payload;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.share_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(payload.title)),
        ],
      ),
      Text(payload.shareType),
      if (payload.subtitle != null) Text(payload.subtitle!),
    ],
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payload});
  final ChatPaymentPayload payload;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.payments_outlined, size: 20),
          SizedBox(width: 8),
          Text('Pago'),
        ],
      ),
      Text('${payload.currency} ${payload.amount.toStringAsFixed(0)}'),
      Text('Estado: ${payload.status}'),
      if (payload.description != null) Text(payload.description!),
    ],
  );
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({required this.payload});
  final ChatGiftPayload payload;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.card_giftcard_outlined, size: 20),
          SizedBox(width: 8),
          Text('Regalo'),
        ],
      ),
      Text(payload.giftType),
      Text('${payload.currency} ${payload.amount.toStringAsFixed(0)}'),
      if (payload.description != null) Text(payload.description!),
    ],
  );
}
