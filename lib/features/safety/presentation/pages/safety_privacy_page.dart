import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/ciervo_legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import 'blocked_users_page.dart';

class SafetyPrivacyPage extends StatelessWidget {
  const SafetyPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Seguridad y privacidad')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CiervoCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.block),
                    title: const Text('Usuarios bloqueados'),
                    subtitle: const Text(
                      'Gestiona personas que ocultaste de tu experiencia.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BlockedUsersPage(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Reportes'),
                    subtitle: const Text(
                      'Los reportes ayudan a moderar la comunidad CIERVO.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Solicitud de datos'),
                    subtitle: const Text(
                      'Ejerce tus derechos sobre tu informacion personal.',
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _openLegalUrl(context, CiervoLegalUrls.dataRequest),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

Future<void> _openLegalUrl(BuildContext context, String url) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No pudimos abrir $url')),
    );
  }
}
