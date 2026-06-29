import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../domain/entities/user_profile.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Configuracion')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CiervoCard(
              child: Column(
                children: [
                  _tile(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Editar perfil',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EditProfilePage(profile: profile),
                      ),
                    ),
                  ),
                  _tile(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsPage(),
                      ),
                    ),
                  ),
                  _tile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terminos',
                    onTap: () => _open(context, 'https://ciervoclub.com/terms'),
                  ),
                  _tile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Politica de privacidad',
                    onTap: () =>
                        _open(context, 'https://ciervoclub.com/privacy'),
                  ),
                  _tile(
                    context,
                    icon: Icons.help_outline,
                    title: 'Centro de ayuda',
                    onTap: () => _open(context, 'https://ciervoclub.com/help'),
                  ),
                  _tile(
                    context,
                    icon: Icons.language_outlined,
                    title: 'Landing web',
                    onTap: () => _open(context, 'https://ciervoclub.com'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ayuda')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CiervoCard(
              child: Column(
                children: [
                  _tile(
                    context,
                    icon: Icons.language_outlined,
                    title: 'Abrir landing',
                    onTap: () => _open(context, 'https://ciervoclub.com'),
                  ),
                  _tile(
                    context,
                    icon: Icons.quiz_outlined,
                    title: 'Abrir FAQ',
                    onTap: () => _open(context, 'https://ciervoclub.com/faq'),
                  ),
                  _tile(
                    context,
                    icon: Icons.support_agent_outlined,
                    title: 'Abrir soporte',
                    onTap: () => _open(context, 'https://ciervoclub.com/support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

Widget _tile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) =>
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );

Future<void> _open(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No pudimos abrir $url')),
    );
  }
}
