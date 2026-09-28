import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../state/service_review_submission_controller.dart';

/// The transient "sending your service review" screen. Mirrors
/// `ReviewProcessingPage`: no cancel, never claims the review landed — it
/// forwards to the result screen only once the repository has resolved.
class ServiceReviewProcessingPage extends ConsumerStatefulWidget {
  const ServiceReviewProcessingPage({
    super.key,
    required this.reservationId,
    required this.serviceOrderId,
  });

  final String reservationId;
  final String serviceOrderId;

  @override
  ConsumerState<ServiceReviewProcessingPage> createState() =>
      _ServiceReviewProcessingPageState();
}

class _ServiceReviewProcessingPageState
    extends ConsumerState<ServiceReviewProcessingPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _react(ref.read(serviceReviewSubmissionControllerProvider)),
    );
  }

  void _react(ServiceReviewActionState state) {
    if (_navigated || !mounted) return;
    if (state is ServiceReviewSubmitDone || state is ServiceReviewSubmitFailed) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.serviceReviewResultName,
        pathParameters: <String, String>{
          'reservationId': widget.reservationId,
          'serviceOrderId': widget.serviceOrderId,
        },
      );
    } else if (state is ServiceReviewIdle) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.serviceReviewFormName,
        pathParameters: <String, String>{
          'reservationId': widget.reservationId,
          'serviceOrderId': widget.serviceOrderId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    ref.listen<ServiceReviewActionState>(
      serviceReviewSubmissionControllerProvider,
      (_, ServiceReviewActionState next) => _react(next),
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
