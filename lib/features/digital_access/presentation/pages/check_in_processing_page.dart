import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../state/check_in_controller.dart';
import '../state/digital_access_providers.dart';

/// `04 · Check in & Stay` — the transient "checking you in" screen.
///
/// Shows a clear processing state and never claims success. It forwards to the
/// digital-access screen only once the repository has resolved the grant
/// (checked in / issue failed / pending). No cancel action.
class CheckInProcessingPage extends ConsumerStatefulWidget {
  const CheckInProcessingPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<CheckInProcessingPage> createState() =>
      _CheckInProcessingPageState();
}

class _CheckInProcessingPageState extends ConsumerState<CheckInProcessingPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _react(ref.read(checkInControllerProvider)),
    );
  }

  void _react(CheckInActionState state) {
    if (_navigated || !mounted) return;
    if (state is CheckInDone || state is CheckInFailed) {
      _navigated = true;
      // The repository grant is authoritative — refresh it before the access
      // screen reads it.
      ref.invalidate(accessGrantProvider(widget.reservationId));
      context.pushReplacementNamed(
        AppRoutes.digitalAccessName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
    } else if (state is CheckInIdle) {
      _navigated = true;
      context.pushReplacementNamed(
        AppRoutes.checkInName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    ref.listen<CheckInActionState>(checkInControllerProvider, (_, next) {
      _react(next);
    });

    return Scaffold(
      appBar: HotelAppBar(title: l10n.checkInProcessingTitle),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LoadingView(label: l10n.checkInProcessingBody),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.checkInDoNotClose,
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
