import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/child_profile.dart';
import '../cubit/kids_cubit.dart';

class KidLoginAccessCard extends StatefulWidget {
  const KidLoginAccessCard({
    required this.child,
    required this.childId,
    super.key,
  });

  final ChildProfile child;
  final String childId;

  @override
  State<KidLoginAccessCard> createState() => _KidLoginAccessCardState();
}

class _KidLoginAccessCardState extends State<KidLoginAccessCard> {
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  final _newPinController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  Future<void> _copyUsername(String username) async {
    await Clipboard.setData(ClipboardData(text: username));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario copiado.')),
    );
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final pin = _pinController.text.trim();
    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El usuario debe tener al menos 3 caracteres.')),
      );
      return;
    }
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El PIN debe tener al menos 4 dígitos.')),
      );
      return;
    }
    await context.read<KidsCubit>().createKidAccount(
          childId: widget.childId,
          username: username,
          pin: pin,
        );
  }

  Future<void> _updatePin() async {
    final pin = _newPinController.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El PIN debe tener al menos 4 dígitos.')),
      );
      return;
    }
    await context.read<KidsCubit>().updateKidPin(
          childId: widget.childId,
          pin: pin,
        );
    if (mounted) _newPinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final username = child.kidUsername?.trim() ?? '';

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Acceso del menor',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Con este usuario y PIN el menor inicia sesión en "Soy hijo/a".',
          ),
          const SizedBox(height: AppSpacing.md),
          if (username.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usuario para iniciar sesión',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          username,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar usuario',
                    onPressed: () => _copyUsername(username),
                    icon: const Icon(Icons.copy_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nuevo PIN',
                helperText: 'Actualiza el PIN por seguridad cuando lo necesites.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            CiervoButton(
              label: 'Actualizar PIN',
              icon: Icons.lock_reset_outlined,
              onPressed: _updatePin,
            ),
          ] else ...[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuario de acceso',
                helperText: 'Ej: jose.montenegro',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PIN de acceso',
                helperText: 'Mínimo 4 dígitos.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CiervoButton(
              label: 'Crear cuenta de acceso',
              icon: Icons.person_add_alt_1,
              onPressed: _createAccount,
            ),
          ],
        ],
      ),
    );
  }
}
