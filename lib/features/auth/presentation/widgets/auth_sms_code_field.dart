import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';

/// Campo OTP de 6 dígitos con cuadros individuales.
class AuthSmsCodeField extends StatefulWidget {
  const AuthSmsCodeField({
    required this.controller,
    this.enabled = true,
    this.onCompleted,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  State<AuthSmsCodeField> createState() => _AuthSmsCodeFieldState();
}

class _AuthSmsCodeFieldState extends State<AuthSmsCodeField> {
  static const _length = 6;

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCodeChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final digits = _digitsOnly(widget.controller.text);
    if (digits != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
      return;
    }
    if (digits.length == _length) {
      widget.onCompleted?.call(digits);
    }
    setState(() {});
  }

  String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '').substring(
            0,
            value.replaceAll(RegExp(r'\D'), '').length.clamp(0, _length),
          );

  @override
  Widget build(BuildContext context) {
    final code = _digitsOnly(widget.controller.text);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_length, (index) {
              final digit = index < code.length ? code[index] : '';
              final isActive =
                  widget.enabled && _focusNode.hasFocus && index == code.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.5),
                    width: isActive ? 2 : 1,
                  ),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  digit,
                  style: theme.textTheme.headlineSmall,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 0,
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              maxLength: _length,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
      ],
    );
  }
}
