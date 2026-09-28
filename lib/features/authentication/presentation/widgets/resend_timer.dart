import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';

/// "Resend in 00:42" → "Resend the code" from `09 · Authentication`.
///
/// Owns a one-second [Timer] that counts [cooldown] down and then offers the
/// resend action. Changing [resetSignal] (e.g. after a resend) restarts the
/// countdown. The timer is cancelled at zero and on dispose, so widget tests
/// can `pump` past it without a pending-timer failure; passing
/// [cooldown] `Duration.zero` skips the countdown entirely.
class ResendTimer extends StatefulWidget {
  const ResendTimer({
    super.key,
    required this.cooldown,
    required this.onResend,
    this.resetSignal = 0,
    this.enabled = true,
  });

  final Duration cooldown;
  final VoidCallback onResend;
  final int resetSignal;
  final bool enabled;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ResendTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetSignal != widget.resetSignal) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _secondsLeft = widget.cooldown.inSeconds;
    if (_secondsLeft <= 0) {
      setState(() {});
      return;
    }
    setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String get _formatted {
    final int m = _secondsLeft ~/ 60;
    final int s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (_secondsLeft > 0) {
      return Text(
        l10n.authOtpResendCountdown(_formatted),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return TextButton(
      onPressed: widget.enabled ? widget.onResend : null,
      child: Text(l10n.authOtpResendAction),
    );
  }
}
