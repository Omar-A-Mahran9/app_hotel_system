import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/presentation/form_submission.dart';
import '../../data/datasources/auth_demo_config.dart';
import '../../domain/entities/guest_phone.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_controller.dart';

/// The linear guest sign-in flow: enter phone → enter code. It is a single
/// controller (not one per screen) so the challenge, the attempt budget and the
/// current step live in one testable place. Profile completion is a separate
/// concern driven by [AuthState.awaitingProfile].
sealed class LoginFlowState {
  const LoginFlowState();
}

/// Phone-number entry step.
class LoginPhoneStep extends LoginFlowState {
  const LoginPhoneStep({this.submission = const FormSubmission.idle()});
  final FormSubmission submission;
}

/// What the code-entry step is currently doing. One explicit value instead of a
/// spread of `isVerifying` / `hasError` / `isLocked` booleans.
enum OtpEntryStatus {
  /// Waiting for the guest to type / submit a code.
  editing,

  /// A code is being verified.
  verifying,

  /// A new code is being requested.
  resending,

  /// The last code was wrong; the guest may try again.
  rejected,

  /// The attempt budget is spent; a new code is required.
  lockedOut,
}

/// Code-entry step for [challenge].
class LoginOtpStep extends LoginFlowState {
  const LoginOtpStep({
    required this.challenge,
    this.status = OtpEntryStatus.editing,
    this.infraFailure,
  });

  final OtpChallenge challenge;
  final OtpEntryStatus status;

  /// Set when verify/resend failed for an infrastructure reason (offline,
  /// server) rather than a wrong code.
  final Failure? infraFailure;

  int get attemptsRemaining => challenge.attemptsRemaining;
  bool get isBusy =>
      status == OtpEntryStatus.verifying || status == OtpEntryStatus.resending;

  LoginOtpStep copyWith({
    OtpChallenge? challenge,
    OtpEntryStatus? status,
    Failure? infraFailure,
    bool clearInfraFailure = false,
  }) {
    return LoginOtpStep(
      challenge: challenge ?? this.challenge,
      status: status ?? this.status,
      infraFailure: clearInfraFailure
          ? null
          : (infraFailure ?? this.infraFailure),
    );
  }
}

class LoginFlowController extends Notifier<LoginFlowState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  LoginFlowState build() => const LoginPhoneStep();

  /// Resets the flow to a clean phone-entry step (used by "change number" and
  /// when re-entering sign-in).
  void reset() => state = const LoginPhoneStep();

  /// Sends a code to [phone]. On success the state becomes [LoginOtpStep].
  Future<void> submitPhone(GuestPhone phone) async {
    state = const LoginPhoneStep(submission: FormSubmission.inProgress());
    try {
      final OtpChallenge challenge = await _repository.requestOtp(phone);
      state = LoginOtpStep(challenge: challenge);
    } catch (error) {
      state = LoginPhoneStep(
        submission: FormSubmission.failed(ErrorMapper.toFailure(error)),
      );
    }
  }

  /// Submits [code] for the current challenge.
  Future<void> submitCode(String code) async {
    final LoginFlowState current = state;
    if (current is! LoginOtpStep ||
        current.status == OtpEntryStatus.lockedOut ||
        current.isBusy) {
      return;
    }

    state = current.copyWith(
      status: OtpEntryStatus.verifying,
      clearInfraFailure: true,
    );
    try {
      final OtpVerification result = await _repository.verifyOtp(
        challenge: current.challenge,
        code: code,
      );
      switch (result) {
        case OtpAuthenticated(:final session):
          ref.read(authControllerProvider.notifier).onOtpVerified(session);
          state = current.copyWith(status: OtpEntryStatus.editing);
        case OtpRejected(:final challenge):
          state = current.copyWith(
            challenge: challenge,
            status: OtpEntryStatus.rejected,
          );
        case OtpLockedOut(:final challenge):
          state = current.copyWith(
            challenge: challenge,
            status: OtpEntryStatus.lockedOut,
          );
      }
    } catch (error) {
      state = current.copyWith(
        status: OtpEntryStatus.editing,
        infraFailure: ErrorMapper.toFailure(error),
      );
    }
  }

  /// Requests a fresh code, clearing the rejected / locked-out state.
  Future<void> resendCode() async {
    final LoginFlowState current = state;
    if (current is! LoginOtpStep || current.isBusy) return;

    state = current.copyWith(
      status: OtpEntryStatus.resending,
      clearInfraFailure: true,
    );
    try {
      final OtpChallenge challenge = await _repository.resendOtp(
        current.challenge,
      );
      state = LoginOtpStep(challenge: challenge);
    } catch (error) {
      state = current.copyWith(
        status: OtpEntryStatus.editing,
        infraFailure: ErrorMapper.toFailure(error),
      );
    }
  }
}

final loginFlowControllerProvider =
    NotifierProvider<LoginFlowController, LoginFlowState>(
      LoginFlowController.new,
    );

/// Cooldown before the OTP screen offers "resend the code" (`00:42` in the
/// reference). A provider so widget tests can override it to [Duration.zero]
/// and avoid a running countdown timer.
final otpResendCooldownProvider = Provider<Duration>(
  (Ref ref) => AuthDemoConfig.resendCooldown,
);
