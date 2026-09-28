import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/problem_category.dart';
import '../problem_reports_l10n.dart';
import '../widgets/problem_category_row.dart';

/// `13 · Report a problem` screen 1 — "الإبلاغ عن مشكلة". A category picker;
/// choosing one and continuing moves to screen 2 with the category carried in
/// the route.
class ReportProblemCategoryPage extends StatefulWidget {
  const ReportProblemCategoryPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  State<ReportProblemCategoryPage> createState() =>
      _ReportProblemCategoryPageState();
}

class _ReportProblemCategoryPageState extends State<ReportProblemCategoryPage> {
  ProblemCategory? _selected;

  static const List<ProblemCategory> _firstGroup = <ProblemCategory>[
    ProblemCategory.acHeating,
    ProblemCategory.plumbingWater,
    ProblemCategory.electricityLighting,
  ];

  static const List<ProblemCategory> _secondGroup = <ProblemCategory>[
    ProblemCategory.roomCleanliness,
    ProblemCategory.internetWifi,
    ProblemCategory.noiseDisturbance,
  ];

  IconData _iconFor(ProblemCategory category) => switch (category) {
        ProblemCategory.acHeating => AppIcons.climate,
        ProblemCategory.plumbingWater => AppIcons.plumbing,
        ProblemCategory.electricityLighting => AppIcons.electrical,
        ProblemCategory.roomCleanliness => AppIcons.cleaning,
        ProblemCategory.internetWifi => AppIcons.wifi,
        ProblemCategory.noiseDisturbance => AppIcons.noise,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    void continueToDescription() {
      final ProblemCategory? category = _selected;
      if (category == null) return;
      context.pushNamed(
        AppRoutes.reportProblemDescribeName,
        pathParameters: <String, String>{
          'reservationId': widget.reservationId,
          'category': category.wireValue,
        },
      );
    }

    return Scaffold(
      appBar: HotelAppBar(title: l10n.reportProblemTitle),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pageGutter),
                children: <Widget>[
                  InfoBanner(
                    tone: InfoBannerTone.info,
                    title: l10n.reportProblemCategoryHeading,
                    message: l10n.reportProblemCategoryBody,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _CategoryGroup(
                    categories: _firstGroup,
                    selected: _selected,
                    iconFor: _iconFor,
                    onSelect: (ProblemCategory c) => setState(() => _selected = c),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryGroup(
                    categories: _secondGroup,
                    selected: _selected,
                    iconFor: _iconFor,
                    onSelect: (ProblemCategory c) => setState(() => _selected = c),
                  ),
                ],
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.xs,
                AppSpacing.pageGutter,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SecondaryButton(
                    label: l10n.myReportsTitle,
                    icon: AppIcons.report,
                    onPressed: () => context.pushNamed(
                      AppRoutes.problemReportsName,
                      pathParameters: <String, String>{
                        'reservationId': widget.reservationId,
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: l10n.reportProblemContinueCta,
                    onPressed: _selected == null ? null : continueToDescription,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.categories,
    required this.selected,
    required this.iconFor,
    required this.onSelect,
  });

  final List<ProblemCategory> categories;
  final ProblemCategory? selected;
  final IconData Function(ProblemCategory) iconFor;
  final ValueChanged<ProblemCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AppCard.list(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < categories.length; i++)
            ProblemCategoryRow(
              category: categories[i],
              icon: iconFor(categories[i]),
              label: l10n.problemCategoryLabel(categories[i]),
              selected: categories[i] == selected,
              onTap: () => onSelect(categories[i]),
              showDivider: i != categories.length - 1,
            ),
        ],
      ),
    );
  }
}
