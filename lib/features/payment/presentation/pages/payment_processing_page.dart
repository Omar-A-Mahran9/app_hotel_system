import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../state/payment_controller.dart';

/// `03 · Pay & Verify` — the transient "we're confirming your payment" screen.
///
/// It shows a clear processing state and never claims success: it forwards to
/// the result screen only once the repository has resolved the hold (done) or
/// reported an infrastructure failure. There is no cancel action — the request
/// is already with the backend.
class PaymentProcessingPage extends ConsumerStatefulWidget {
  const PaymentProcessingPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<PaymentProcessingPage> createState() =>
      _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends ConsumerState<PaymentProcessingPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _react(
          ref.read(paymentControllerProvider),
        ));
  }

  void _react(PaymentActionState state) {
    if (_navigated || !mounted) return;

    if (state is PaymentActionDone || state is PaymentActionFailed) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.paymentResultName,
        pathParameters: <String, String>{
          'reservationId': widget.reservationId,
        },
      );
    } else if (state is PaymentActionIdle) {
      // Reached without an in-flight request (deep link / reload) — send the
      // guest back to the review step.
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.paymentReviewName,
        pathParameters: <String, String>{
          'reservationId': widget.reservationId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    ref.listen<PaymentActionState>(paymentControllerProvider, (_, next) {
      _react(next);
    });

    return Scaffold(
      appBar: HotelAppBar(title: l10n.paymentProcessingTitle),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LoadingView(label: l10n.paymentProcessingBody),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.paymentDoNotClose,
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
