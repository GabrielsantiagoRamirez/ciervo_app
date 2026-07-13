import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/ciervo_legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../legal/presentation/pages/legal_privacy_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../safety/presentation/pages/safety_privacy_page.dart';
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
                icon: Icons.gavel_outlined,
                title: 'Legal y privacidad',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalPrivacyPage(),
                  ),
                ),
              ),
              _tile(
                context,
                icon: Icons.shield_outlined,
                title: 'Seguridad y privacidad',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SafetyPrivacyPage(),
                  ),
                ),
              ),
              _tile(
                context,
                icon: Icons.description_outlined,
                title: 'Terminos',
                onTap: () => _open(context, CiervoLegalUrls.terms),
              ),
              _tile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Politica de privacidad',
                onTap: () => _open(context, CiervoLegalUrls.privacy),
              ),
              _tile(
                context,
                icon: Icons.support_agent_outlined,
                title: 'Centro de ayuda',
                onTap: () => _open(context, CiervoLegalUrls.support),
              ),
              _tile(
                context,
                icon: Icons.manage_accounts_outlined,
                title: 'Solicitud de datos',
                onTap: () => _open(context, CiervoLegalUrls.dataRequest),
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
                icon: Icons.support_agent_outlined,
                title: 'Abrir soporte',
                onTap: () => _open(context, CiervoLegalUrls.support),
              ),
              _tile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Politica de privacidad',
                onTap: () => _open(context, CiervoLegalUrls.privacy),
              ),
              _tile(
                context,
                icon: Icons.description_outlined,
                title: 'Terminos de uso',
                onTap: () => _open(context, CiervoLegalUrls.terms),
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
}) => ListTile(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('No pudimos abrir $url')));
  }
}
