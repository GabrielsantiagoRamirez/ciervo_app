import '../domain/entities/vakupli_plan.dart';

abstract final class MockVakupliData {
  static const VakupliPlan activePlan = VakupliPlan(
    title: 'Plan Velvet Room',
    timeLeftLabel: '02:14:36',
    statusLabel: 'Activo',
    totalAmount: 2400,
    selfDestructLabel: 'Chat temporal: se autodestruye en 2h 14m',
    friends: [
      VakupliFriend(name: 'Gabriel', initials: 'GA'),
      VakupliFriend(name: 'Camila', initials: 'CA'),
      VakupliFriend(name: 'Luis', initials: 'LU'),
      VakupliFriend(name: 'Nora', initials: 'NO'),
    ],
    messages: [
      VakupliMessage(
        senderName: 'Camila',
        text: 'Yo me apunto para las 10:30 🙌',
        timeLabel: '21:01',
        isCurrentUser: false,
      ),
      VakupliMessage(
        senderName: 'Gabriel',
        text: 'Perfecto, reservo mesa VIP.',
        timeLabel: '21:02',
        isCurrentUser: true,
      ),
      VakupliMessage(
        senderName: 'Luis',
        text: 'Hagamos split equitativo para avanzar.',
        timeLabel: '21:03',
        isCurrentUser: false,
      ),
    ],
  );
}
