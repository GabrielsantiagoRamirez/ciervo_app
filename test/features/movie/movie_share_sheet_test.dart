import 'package:ciervo_clud/core/result/result.dart';
import 'package:ciervo_clud/features/chat/domain/entities/chat_conversation.dart';
import 'package:ciervo_clud/features/chat/domain/entities/chat_message.dart';
import 'package:ciervo_clud/features/chat/domain/repositories/chat_repository.dart';
import 'package:ciervo_clud/features/movie/domain/models/movie_models.dart';
import 'package:ciervo_clud/features/movie/presentation/widgets/movie_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('comparte seleccionando una conversación accesible', (
    tester,
  ) async {
    final repository = _ShareRepository();
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showMovieShareSheet(
                context: context,
                movie: const MovieSummary(
                  id: '11111111-1111-1111-1111-111111111111',
                  title: 'La película',
                  minimumAge: 7,
                  durationMinutes: 90,
                  language: 'ES',
                ),
                repository: repository,
              ),
              child: const Text('Compartir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    expect(find.text('Chat familiar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Vamos a verla');
    await tester.tap(find.text('Chat familiar'));
    await tester.pumpAndSettle();

    expect(repository.conversationId, '44');
    expect(repository.movieId, '11111111-1111-1111-1111-111111111111');
    expect(repository.message, 'Vamos a verla');
  });
}

class _ShareRepository implements ChatRepository {
  String? conversationId;
  String? movieId;
  String? message;

  @override
  Future<Result<List<ChatConversation>>> conversations() async =>
      const Success([
        ChatConversation(
          id: '44',
          title: 'Chat familiar',
          type: 'Family',
          unreadCount: 0,
          status: 'Open',
        ),
      ]);

  @override
  Future<Result<ChatMessage>> shareMovie({
    required String movieId,
    String? conversationId,
    String? chatId,
    String? ciervoId,
    String? message,
  }) async {
    this.movieId = movieId;
    this.conversationId = conversationId;
    this.message = message;
    return const Success(
      ChatMessage(id: '1', body: '', messageType: 'Movie', isMine: true),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
