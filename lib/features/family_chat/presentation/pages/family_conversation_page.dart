import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/result/result.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/widgets/membership_upgrade_dialog.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/session/auth_token_claims.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/chat_location_card.dart';
import '../../../chat/domain/entities/chat_button.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../chat/domain/entities/chat_message.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/widgets/chat_buttons_bar.dart';
import '../../../chat/presentation/widgets/chat_message_image.dart';
import '../../data/family_chat_repository.dart';

class FamilyConversationPage extends StatefulWidget {
  const FamilyConversationPage({required this.conversation, super.key});
  final ChatConversation conversation;

  @override
  State<FamilyConversationPage> createState() => _FamilyConversationPageState();
}

class _FamilyConversationPageState extends State<FamilyConversationPage> {
  static const _maxPhotoBytes = 5 * 1024 * 1024;
  static const _extensions = {'jpg', 'jpeg', 'png', 'webp'};

  final _repository = getIt<FamilyChatRepository>();
  final _chatRepository = getIt<ChatRepository>();
  final _controller = TextEditingController();
  List<ChatMessage> _messages = const [];
  List<ChatButton> _chatButtons = const [];
  bool _loading = true;
  bool _sending = false;
  bool _isKidSession = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessionKind();
    _open();
  }

  Future<void> _loadSessionKind() async {
    final token = await getIt<SessionManager>().accessToken();
    if (!mounted || token == null) return;
    setState(() {
      _isKidSession = AuthTokenClaims.fromJwt(token).routeKind == 'Kid';
    });
  }

  Future<void> _open() async {
    await _repository.markRead(widget.conversation.id);
    final results = await Future.wait([
      _repository.messages(widget.conversation.id),
      _chatRepository.buttons(),
    ]);
    if (!mounted) return;
    final messagesResult = results[0] as Result<List<ChatMessage>>;
    final buttonsResult = results[1] as Result<List<ChatButton>>;
    messagesResult.when(
      success: (messages) => setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
    buttonsResult.when(
      success: (buttons) => setState(() => _chatButtons = buttons),
      failure: (_) {},
    );
  }

  Future<void> _sendText() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await _repository.sendText(widget.conversation.id, body);
    if (!mounted) return;
    result.when(
      success: (message) => setState(() {
        _messages = [message, ..._messages];
        _controller.clear();
        _sending = false;
      }),
      failure: (error) {
        setState(() => _sending = false);
        _showError(error);
      },
    );
  }

  Future<void> _sendImage() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (photo == null || !mounted) return;
    final extension = photo.name.split('.').last.toLowerCase();
    final length = await photo.length();
    if (!_extensions.contains(extension) || length > _maxPhotoBytes) {
      _showMessage('Usa JPG, PNG o WEBP de máximo 5 MB.');
      return;
    }
    setState(() => _sending = true);
    final result = await _repository.sendMedia(
      widget.conversation.id,
      path: photo.path,
      fileName: photo.name,
    );
    if (!mounted) return;
    result.when(
      success: (message) => setState(() {
        _messages = [message, ..._messages];
        _sending = false;
      }),
      failure: (error) {
        setState(() => _sending = false);
        _showError(error);
      },
    );
  }

  Future<void> _sendLocation() async {
    setState(() => _sending = true);
    try {
      final location = await getIt<LocationService>().currentLocation();
      final result = await _repository.sendLocation(
        widget.conversation.id,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted) return;
      result.when(
        success: (message) => setState(() {
          _messages = [message, ..._messages];
          _sending = false;
        }),
        failure: (error) {
          setState(() => _sending = false);
          _showError(error);
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        _showMessage('No pudimos obtener tu ubicación.');
      }
    }
  }

  void _showError(Object error) async {
    if (!await handlePlanLimitError(context, error)) {
      _showMessage(UserErrorMessage.from(error));
    }
  }

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.conversation.title)),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .82,
                        ),
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: message.isMine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _FamilyMessageBody(message: message),
                      ),
                    );
                  },
                ),
              ),
              if (widget.conversation.canSend)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChatButtonsBar(
                      buttons: _chatButtons,
                      conversationId: widget.conversation.id,
                      enabled: !_sending,
                      familyKidMode: _isKidSession,
                      onActionCompleted: _open,
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _sending ? null : _sendImage,
                              icon: const Icon(Icons.image_outlined),
                              tooltip: 'Enviar imagen',
                            ),
                            IconButton(
                              onPressed: _sending ? null : _sendLocation,
                              icon: const Icon(Icons.location_on_outlined),
                              tooltip: 'Enviar ubicación',
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                enabled: !_sending,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendText(),
                                decoration: const InputDecoration(
                                  hintText: 'Escribe un mensaje',
                                ),
                              ),
                            ),
                            IconButton.filled(
                              onPressed: _sending ? null : _sendText,
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Esta conversación está cerrada y no acepta mensajes.',
                  ),
                ),
            ],
          ),
  );
}

class _FamilyMessageBody extends StatelessWidget {
  const _FamilyMessageBody({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.paymentPayload != null) {
      return _FamilyPaymentCard(payload: message.paymentPayload!);
    }
    if (message.giftPayload != null) {
      return _FamilyGiftCard(payload: message.giftPayload!);
    }
    if (message.locationPayload != null) {
      return ChatLocationCard(payload: message.locationPayload!);
    }
    if (message.isImageMessage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatMessageImage(message: message),
          if (message.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(message.body),
          ],
        ],
      );
    }
    final attachment = message.attachmentUrl;
    if (attachment != null && attachment.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatMessageImage(message: message),
          if (message.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(message.body),
          ],
        ],
      );
    }
    return Text(message.body);
  }
}

class _FamilyPaymentCard extends StatelessWidget {
  const _FamilyPaymentCard({required this.payload});

  final ChatPaymentPayload payload;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.request_page_outlined, size: 20),
          SizedBox(width: 8),
          Text('Solicitud de pago'),
        ],
      ),
      Text('${payload.currency} ${payload.amount.toStringAsFixed(0)}'),
      Text('Estado: ${DisplayLabels.bookingStatus(payload.status)}'),
      if (payload.description != null) Text(payload.description!),
    ],
  );
}

class _FamilyGiftCard extends StatelessWidget {
  const _FamilyGiftCard({required this.payload});

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
