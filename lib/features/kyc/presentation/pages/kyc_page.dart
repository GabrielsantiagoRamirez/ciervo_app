// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
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
    appBar: AppBar(title: const Text('Verificacion KYC')),
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
              title: 'No pudimos cargar tu KYC',
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
    final status = kyc?.status ?? 'No enviado';
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(status), color: _color(status)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Estado: $status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            kyc == null
                ? 'Envia tus datos para iniciar la verificacion.'
                : 'Documento: ${kyc!.documentType ?? '-'} ${kyc!.documentNumber ?? ''}',
          ),
          if ((kyc?.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Motivo de rechazo: ${kyc!.rejectionReason}'),
          ],
        ],
      ),
    );
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
        Text('Enviar verificacion', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          value: _documentType,
          items: const [
            DropdownMenuItem(value: 'CC', child: Text('Cedula')),
            DropdownMenuItem(value: 'CE', child: Text('Cedula extranjeria')),
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
          decoration: const InputDecoration(labelText: 'Numero de documento'),
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
          label: Text(_saving ? 'Enviando' : 'Enviar KYC'),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    if (_documentController.text.trim().isEmpty) return;
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
          const SnackBar(content: Text('KYC enviado para revision.')),
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
  final status = kyc?.status.toLowerCase();
  return kyc == null || status == 'rejected' || status == 'rechazado';
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
