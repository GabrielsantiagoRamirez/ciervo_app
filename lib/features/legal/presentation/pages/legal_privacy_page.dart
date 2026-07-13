import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/ciervo_legal_urls.dart';
import '../../../../core/permissions/permission_kind.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';

/// Vista central de políticas, permisos, seguridad de pagos y soporte.
class LegalPrivacyPage extends StatelessWidget {
  const LegalPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal y privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CiervoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu confianza es prioridad',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Ciervo Club es una plataforma financiera y de entretenimiento. '
                  'Aquí encontrarás cómo tratamos tus datos, qué permisos usamos y '
                  'cómo protegemos tu wallet y pagos.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('Documentos legales'),
          CiervoCard(
            child: Column(
              children: [
                _LegalTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  subtitle: 'Reglas de uso de la plataforma.',
                  onTap: () => _open(context, CiervoLegalUrls.terms),
                ),
                const Divider(height: 1),
                _LegalTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de privacidad',
                  subtitle: 'Cómo recopilamos y usamos tu información.',
                  onTap: () => _open(context, CiervoLegalUrls.privacy),
                ),
                const Divider(height: 1),
                _LegalTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Tratamiento de datos personales',
                  subtitle: 'Ejerce tus derechos ARCO y solicita tus datos.',
                  onTap: () => _open(context, CiervoLegalUrls.dataRequest),
                ),
                const Divider(height: 1),
                _LegalTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Eliminación de cuenta',
                  subtitle: 'Solicita la eliminación permanente de tu cuenta.',
                  onTap: () => _open(context, CiervoLegalUrls.accountDeletion),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('Seguridad de pagos y wallet'),
          CiervoCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bullet(
                  'Los pagos con tarjeta se tokenizan con Mercado Pago. '
                  'CIERVO no almacena el número completo ni el CVV.',
                ),
                SizedBox(height: AppSpacing.sm),
                _Bullet(
                  'Tu wallet, transferencias, recargas y movimientos quedan '
                  'registrados con trazabilidad y notificaciones de seguridad.',
                ),
                SizedBox(height: AppSpacing.sm),
                _Bullet(
                  'Puedes bloquear tu tarjeta digital desde la wallet en cualquier momento.',
                ),
                SizedBox(height: AppSpacing.sm),
                _Bullet(
                  'La verificación de identidad protege tu cuenta y cumple normas KYC.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('Permisos de la app'),
          CiervoCard(
            child: Column(
              children: AppPermissionKind.values
                  .where((k) => k != AppPermissionKind.nfc)
                  .map(
                    (kind) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_iconFor(kind), color: AppColors.primary),
                      title: Text(kind.title),
                      subtitle: Text(kind.explanation),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('Soporte'),
          CiervoCard(
            child: _LegalTile(
              icon: Icons.support_agent_outlined,
              title: 'Contacto de soporte',
              subtitle: 'Ayuda con pagos, cuenta, verificación y más.',
              onTap: () => _open(context, CiervoLegalUrls.support),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(AppPermissionKind kind) => switch (kind) {
    AppPermissionKind.camera => Icons.photo_camera_outlined,
    AppPermissionKind.photos => Icons.photo_library_outlined,
    AppPermissionKind.contacts => Icons.contacts_outlined,
    AppPermissionKind.location => Icons.location_on_outlined,
    AppPermissionKind.notifications => Icons.notifications_active_outlined,
    AppPermissionKind.nfc => Icons.nfc,
  };

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No pudimos abrir $url')));
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text)),
      ],
    );
  }
}
