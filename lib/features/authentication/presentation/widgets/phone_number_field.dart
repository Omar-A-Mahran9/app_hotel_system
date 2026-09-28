import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/guest_phone.dart';

/// Mobile-number input from `09 · Authentication`: a fixed `+966` dialling-code
/// box next to the national-number field. The number itself is always entered
/// left-to-right, even in an RTL layout.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.onSubmitted,
    this.dialCode = GuestPhone.defaultDialCode,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final VoidCallback? onSubmitted;
  final String dialCode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Text(
                  '🇸🇦  $dialCode',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmitted?.call(),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: hintText,
                    errorText: errorText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
