// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../data/kyc_repository.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  late Future<KycSubmission?> _kyc;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _kyc = getIt<KycRepository>().me().then(
      (result) => result.when(
        success: (value) => value,
        failure: (error) => throw error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verificación de identidad')),
    body: FutureBuilder<KycSubmission?>(
      future: _kyc,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CiervoLoadingState();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CiervoErrorState(
              title: 'No pudimos cargar tu verificación',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(_reload),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _KycStatusCard(kyc: snapshot.data),
              const SizedBox(height: AppSpacing.lg),
              if (_canSubmit(snapshot.data)) _KycSubmitForm(onSubmitted: () {
                setState(_reload);
              }),
            ],
          ),
        );
      },
    ),
  );
}

class _KycStatusCard extends StatelessWidget {
  const _KycStatusCard({required this.kyc});

  final KycSubmission? kyc;

  @override
  Widget build(BuildContext context) {
    final rawStatus = kyc?.status ?? 'No enviado';
    final status = DisplayLabels.kycStatus(rawStatus);
    final color = _color(rawStatus);
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(rawStatus), color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _statusDescription(rawStatus, kyc),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (kyc != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _infoRow(
              context,
              'Documento',
              '${DisplayLabels.documentType(kyc!.documentType ?? '-')} ${kyc!.documentNumber ?? ''}',
            ),
            if (kyc!.submittedAt != null)
              _infoRow(
                context,
                'Enviado',
                kyc!.submittedAt!.toLocal().toString().substring(0, 16),
              ),
          ],
          if ((kyc?.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Motivo de rechazo: ${kyc!.rejectionReason}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  String _statusDescription(String status, KycSubmission? kyc) {
    final key = status.toLowerCase();
    if (kyc == null) {
      return 'Envía tus datos para iniciar la verificación de identidad.';
    }
    if (key.contains('approve')) {
      return 'Tu identidad fue verificada correctamente.';
    }
    if (key.contains('reject')) {
      return 'Tu solicitud fue rechazada. Puedes corregir los datos y reenviar.';
    }
    if (key.contains('pending') || key.contains('review')) {
      return 'Estamos validando tu información. Te notificaremos cuando sea aprobada.';
    }
    return 'Tu solicitud está en proceso.';
  }
}

class _KycSubmitForm extends StatefulWidget {
  const _KycSubmitForm({required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<_KycSubmitForm> createState() => _KycSubmitFormState();
}

class _KycSubmitFormState extends State<_KycSubmitForm> {
  final _documentController = TextEditingController();
  final _notesController = TextEditingController();
  String _documentType = 'CC';
  bool _saving = false;

  @override
  void dispose() {
    _documentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CiervoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enviar verificación',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Necesitamos validar tu identidad para habilitar pagos y beneficios.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          value: _documentType,
          items: const [
            DropdownMenuItem(value: 'CC', child: Text('Cédula')),
            DropdownMenuItem(value: 'CE', child: Text('Cédula de extranjería')),
            DropdownMenuItem(value: 'PASSPORT', child: Text('Pasaporte')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _documentType = value);
          },
          decoration: const InputDecoration(labelText: 'Tipo de documento'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _documentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Número de documento'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notas opcionales'),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(_saving ? 'Enviando…' : 'Enviar verificación'),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    if (_documentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el número de documento.')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await getIt<KycRepository>().submit(
      documentType: _documentType,
      documentNumber: _documentController.text.trim(),
      notes: _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verificación enviada para revisión.')),
        );
        widget.onSubmitted();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

bool _canSubmit(KycSubmission? kyc) {
  final status = kyc?.status.toLowerCase() ?? '';
  return kyc == null ||
      status.contains('reject') ||
      status.contains('rechazado');
}

IconData _icon(String status) {
  final text = status.toLowerCase();
  if (text.contains('approve')) return Icons.verified_outlined;
  if (text.contains('reject')) return Icons.cancel_outlined;
  return Icons.hourglass_top_outlined;
}

Color _color(String status) {
  final text = status.toLowerCase();
  if (text.contains('approve')) return Colors.green;
  if (text.contains('reject')) return Colors.red;
  return Colors.orange;
}
