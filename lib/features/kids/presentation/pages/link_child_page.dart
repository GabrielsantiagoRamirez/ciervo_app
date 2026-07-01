import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/repositories/kids_repository.dart';
import '../cubit/kids_cubit.dart';
import '../cubit/kids_state.dart';

class LinkChildPage extends StatelessWidget {
  const LinkChildPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KidsCubit(getIt<KidsRepository>()),
      child: const _LinkChildView(),
    );
  }
}

class _LinkChildView extends StatefulWidget {
  const _LinkChildView();

  @override
  State<_LinkChildView> createState() => _LinkChildViewState();
}

class _LinkChildViewState extends State<_LinkChildView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  int _relationshipType = 2;

  static const _relationships = <int, String>{
    1: 'Madre',
    2: 'Padre',
    3: 'Tutor legal',
    4: 'Familiar',
    5: 'Otro',
  };

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<KidsCubit>().linkChild(
          kidsPublicId: _codeController.text.trim(),
          relationshipType: _relationshipType,
        );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KidsCubit, KidsState>(
      builder: (context, state) {
        final loading = state.status == KidsStatus.actionLoading;
        return Scaffold(
          appBar: AppBar(title: const Text('Vincular hijo existente')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              CiervoCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Agregar hijo con código',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Pide al tutor principal el código KIDS-XXXXXXXX del menor.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Código del menor',
                          hintText: 'KIDS-12345678',
                          prefixIcon: Icon(Icons.qr_code_2_outlined),
                        ),
                        validator: (value) {
                          final code = value?.trim() ?? '';
                          if (code.isEmpty) return 'Ingresa el código.';
                          if (!code.toUpperCase().startsWith('KIDS-')) {
                            return 'El código debe iniciar con KIDS-.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int>(
                        initialValue: _relationshipType,
                        decoration: const InputDecoration(
                          labelText: 'Tu relación con el menor',
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                        ),
                        items: _relationships.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: loading
                            ? null
                            : (value) =>
                                setState(() => _relationshipType = value ?? 2),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: loading ? 'Vinculando' : 'Vincular hijo',
                        icon: Icons.link,
                        state: loading
                            ? CiervoButtonState.loading
                            : CiervoButtonState.normal,
                        onPressed: loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void copyKidsPublicId(BuildContext context, String kidsPublicId) {
  Clipboard.setData(ClipboardData(text: kidsPublicId));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Código copiado al portapapeles.')),
  );
}
