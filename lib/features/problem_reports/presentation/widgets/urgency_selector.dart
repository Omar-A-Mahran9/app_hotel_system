import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/problem_urgency.dart';
import '../problem_reports_l10n.dart';

/// The 3-way urgency picker (`13 · Report a problem` screen 2 —
/// عادي / مهم / عاجل). Built on the same tokens as the design system's
/// button pair rather than a new primitive: a filled `bg/inverse` pill for the
/// selected option, an outlined one otherwise.
class UrgencySelector extends StatelessWidget {
  const UrgencySelector({
    super.key,
    required this.urgency,
    this.onChanged,
  });

  final ProblemUrgency urgency;
  final ValueChanged<ProblemUrgency>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Row(
      children: <Widget>[
        for (final ProblemUrgency option in ProblemUrgency.values) ...<Widget>[
          if (option != ProblemUrgency.values.first)
            const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _UrgencyOption(
              label: l10n.problemUrgencyLabel(option),
              selected: option == urgency,
              onTap: onChanged == null ? null : () => onChanged!(option),
            ),
          ),
        ],
      ],
    );
  }
}

class _UrgencyOption extends StatelessWidget {
  const _UrgencyOption({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allPill,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.bgInverse : Colors.transparent,
            borderRadius: AppRadius.allPill,
            border: selected ? null : Border.all(color: c.borderDefault),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected ? c.textOnInverse : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
