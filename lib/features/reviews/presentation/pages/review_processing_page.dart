import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../state/review_submission_controller.dart';

/// `05 · Depart & Invoice` — the transient "sending your review" screen.
///
/// Clear processing state, no cancel, never claims the review landed — it
/// forwards to the result screen only once the repository has resolved the
/// submission. Mirrors [CheckoutProcessingPage].
class ReviewProcessingPage extends ConsumerStatefulWidget {
  const ReviewProcessingPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<ReviewProcessingPage> createState() =>
      _ReviewProcessingPageState();
}

class _ReviewProcessingPageState extends ConsumerState<ReviewProcessingPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _react(ref.read(reviewSubmissionControllerProvider)),
    );
  }

  void _react(ReviewActionState state) {
    if (_navigated || !mounted) return;
    if (state is ReviewSubmitDone || state is ReviewSubmitFailed) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.reviewResultName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
    } else if (state is ReviewIdle) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.reviewFormName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    ref.listen<ReviewActionState>(
      reviewSubmissionControllerProvider,
      (_, ReviewActionState next) => _react(next),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.reviewProcessingTitle),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LoadingView(label: l10n.reviewProcessingBody),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.reviewDoNotClose,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
