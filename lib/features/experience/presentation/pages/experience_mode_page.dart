import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';

class ExperienceModePage extends StatefulWidget {
  const ExperienceModePage({super.key});

  @override
  State<ExperienceModePage> createState() => _ExperienceModePageState();
}

class _ExperienceModePageState extends State<ExperienceModePage> {
  late ExperienceMode _selectedMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = context.read<ExperienceModeCubit>().state.mode;
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    await context.read<ExperienceModeCubit>().setMode(_selectedMode);
    if (mounted) context.go(AppRoutePaths.root);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.15,
            colors: [Color(0xFF1B1810), AppColors.background],
            stops: [0, 0.72],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _ExperiencePanel(
                      selectedMode: _selectedMode,
                      saving: _saving,
                      onChanged: (mode) => setState(() => _selectedMode = mode),
                      onContinue: _continue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperiencePanel extends StatelessWidget {
  const _ExperiencePanel({
    required this.selectedMode,
    required this.saving,
    required this.onChanged,
    required this.onContinue,
  });

  final ExperienceMode selectedMode;
  final bool saving;
  final ValueChanged<ExperienceMode> onChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF20D0D0E),
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.38)),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 32, offset: Offset(0, 18)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 116,
            height: 116,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Image.asset('assets/icon/icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'CIERVO',
            style: TextStyle(
              color: AppColors.primaryHigh,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 9,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Elige cuándo inicia\ntu momento',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Selecciona el modo en el que quieres disfrutar la app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ModeSelector(selectedMode: selectedMode, onChanged: onChanged),
          const SizedBox(height: AppSpacing.xl),
          _ContinueButton(saving: saving, onPressed: onContinue),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selectedMode, required this.onChanged});

  final ExperienceMode selectedMode;
  final ValueChanged<ExperienceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF151516),
        borderRadius: AppRadii.chip,
        border: Border.all(color: AppColors.goldDark.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              label: 'Día',
              icon: Icons.wb_sunny_outlined,
              selected: selectedMode == ExperienceMode.day,
              onTap: () => onChanged(ExperienceMode.day),
            ),
          ),
          Expanded(
            child: _ModeSegment(
              label: 'Noche',
              icon: Icons.nightlight_round,
              selected: selectedMode == ExperienceMode.night,
              onTap: () => onChanged(ExperienceMode.night),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Modo $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.chip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primaryHigh, AppColors.goldDark],
                  )
                : null,
            borderRadius: AppRadii.chip,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.dayText : AppColors.primaryHigh,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.dayText : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.chip,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: saving ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.dayText,
          disabledBackgroundColor: AppColors.goldDark,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: saving
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continuar'),
                  SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
      ),
    );
  }
}
