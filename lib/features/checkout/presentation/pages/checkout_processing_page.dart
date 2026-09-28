import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../state/checkout_controller.dart';

/// `05 · Depart & Invoice` — the transient "settling your account" screen.
///
/// Clear processing state, no cancel, never claims success — it forwards to the
/// completion screen only once the repository has resolved the checkout.
class CheckoutProcessingPage extends ConsumerStatefulWidget {
  const CheckoutProcessingPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<CheckoutProcessingPage> createState() =>
      _CheckoutProcessingPageState();
}

class _CheckoutProcessingPageState
    extends ConsumerState<CheckoutProcessingPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _react(ref.read(checkoutControllerProvider)),
    );
  }

  void _react(CheckoutActionState state) {
    if (_navigated || !mounted) return;
    if (state is CheckoutDone || state is CheckoutFailed) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.checkoutCompleteName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
    } else if (state is CheckoutIdle) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.checkoutName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    ref.listen<CheckoutActionState>(checkoutControllerProvider, (_, next) {
      _react(next);
    });

    return Scaffold(
      appBar: HotelAppBar(title: l10n.checkoutProcessingTitle),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LoadingView(label: l10n.checkoutProcessingBody),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.checkoutDoNotClose,
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
