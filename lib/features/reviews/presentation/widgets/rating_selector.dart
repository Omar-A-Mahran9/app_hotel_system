import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/review_draft.dart';

/// A 1–5 star picker (`05 · Depart & Invoice` — "كيف كانت إقامتك؟"). Integer
/// only, min 1, max 5. Direction-agnostic (the row flips with RTL). Each star
/// is an individually labelled button for screen readers.
class RatingSelector extends StatelessWidget {
  const RatingSelector({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 40,
  });

  /// 0 = nothing chosen yet.
  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    const Color active = AppColors.bronze400;
    final Color inactive = theme.colorScheme.outlineVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (
          int star = ReviewDraft.minRating;
          star <= ReviewDraft.maxRating;
          star++
        )
          Semantics(
            button: true,
            selected: rating == star,
            label: l10n.reviewStarsLabel(star),
            child: IconButton(
              onPressed: onChanged == null ? null : () => onChanged!(star),
              iconSize: size,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                star <= rating ? AppIcons.rating : AppIcons.ratingOutline,
                color: star <= rating ? active : inactive,
              ),
            ),
          ),
      ],
    );
  }
}

/// A small read-only star row for showing a submitted rating.
class RatingDisplay extends StatelessWidget {
  const RatingDisplay({super.key, required this.rating, this.size = 20});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const Color active = AppColors.bronze400;
    return Semantics(
      label: context.l10n.reviewStarsLabel(rating),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int star = 1; star <= 5; star++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: Icon(
                star <= rating ? AppIcons.rating : AppIcons.ratingOutline,
                size: size,
                color: star <= rating
                    ? active
                    : theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}
