import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/validators/auth_validators.dart';
import '../state/login_flow_controller.dart';
import '../widgets/otp_code_field.dart';
import '../widgets/resend_timer.dart';

/// `09 · Authentication` — "Enter the code we sent". Handles the correct-code,
/// incorrect-code (with the attempts-left banner) and locked-out states, plus
/// the resend countdown and "change mobile number".
class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final TextEditingController _controller = TextEditingController();
  int _resendSignal = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _backToPhone() {
    ref.read(loginFlowControllerProvider.notifier).reset();
    context.goNamed(AppRoutes.signInName);
  }

  void _verify(LoginOtpStep step) {
    if (!AuthValidators.isOtpFormatValid(
      _controller.text,
      length: step.challenge.codeLength,
    )) {
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(loginFlowControllerProvider.notifier).submitCode(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final LoginFlowState flow = ref.watch(loginFlowControllerProvider);
    final Duration cooldown = ref.watch(otpResendCooldownProvider);

    ref.listen<LoginFlowState>(loginFlowControllerProvider, (
      LoginFlowState? prev,
      LoginFlowState next,
    ) {
      if (next is LoginOtpStep &&
          prev is LoginOtpStep &&
          next.challenge.challengeId != prev.challenge.challengeId) {
        _controller.clear();
        setState(() => _resendSignal++);
      }
    });

    if (flow is! LoginOtpStep) {
      // Reached without a challenge (e.g. app restart). Bounce to phone entry.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(AppRoutes.signInName);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final bool busy = flow.isBusy;
    final bool locked = flow.status == OtpEntryStatus.lockedOut;
    final bool rejected = flow.status == OtpEntryStatus.rejected;

    return Scaffold(
      appBar: HotelAppBar(title: l10n.authOtpTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          children: <Widget>[
            Text(l10n.authOtpHeading, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    flow.challenge.phone.display,
                    style: theme.textTheme.titleSmall,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : _backToPhone,
                  child: Text(l10n.authOtpChange),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (rejected) ...<Widget>[
              InfoBanner(
                tone: InfoBannerTone.error,
                title: l10n.authOtpErrorTitle,
                message: l10n.authOtpErrorBody(flow.attemptsRemaining),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (locked) ...<Widget>[
              InfoBanner(
                tone: InfoBannerTone.error,
                title: l10n.authOtpLockedTitle,
                message: l10n.authOtpLockedBody,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            OtpCodeField(
              length: flow.challenge.codeLength,
              controller: _controller,
              enabled: !busy && !locked,
              hasError: rejected || locked,
              onCompleted: (_) => _verify(flow),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ResendTimer(
                cooldown: locked ? Duration.zero : cooldown,
                resetSignal: _resendSignal,
                enabled: !busy,
                onResend: () =>
                    ref.read(loginFlowControllerProvider.notifier).resendCode(),
              ),
            ),
            if (flow.infraFailure != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                flow.infraFailure!.localizedMessage(l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: locked ? l10n.authOtpRetry : l10n.authOtpSubmit,
              isLoading: flow.status == OtpEntryStatus.verifying,
              onPressed: (locked || busy) ? null : () => _verify(flow),
            ),
            if (rejected || locked) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: l10n.authOtpChangeNumber,
                onPressed: busy ? null : _backToPhone,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
