import '../../../vakupli/domain/entities/vakupli_plan.dart';
import 'chat_conversation.dart';

enum ChatInboxSource { internal, family, vakupli }

class ChatInboxItem {
  const ChatInboxItem({
    required this.conversation,
    required this.source,
    this.vakupliPlan,
  });

  final ChatConversation conversation;
  final ChatInboxSource source;
  final VakupliPlan? vakupliPlan;

  String get id => conversation.id;

  String get kindLabel => switch (source) {
    ChatInboxSource.vakupli => 'Vakupli',
    ChatInboxSource.family => 'Familia',
    _ => switch (conversation.type.toLowerCase()) {
      'business' => 'Negocio',
      'family' => 'Familia',
      'delivery' => 'Domicilio',
      'support' => 'Soporte',
      'direct' => 'Directo',
      _ => 'Chat',
    },
  };
}
