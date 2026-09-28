import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/presentation/form_submission.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/validators/auth_validators.dart';
import '../state/complete_profile_controller.dart';

/// `09 · Authentication` — "Complete your details". First-time guests supply a
/// full name and email; the banner explains the name must match the ID.
class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onChange);
    _email.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _isValid =>
      AuthValidators.fullName(_name.text) == null &&
      AuthValidators.email(_email.text) == null;

  void _submit() {
    setState(() => _showValidation = true);
    if (!_isValid) return;
    FocusScope.of(context).unfocus();
    ref
        .read(completeProfileControllerProvider.notifier)
        .submit(fullName: _name.text, email: _email.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final FormSubmission submission = ref.watch(
      completeProfileControllerProvider,
    );
    final bool busy = submission.isInProgress;

    final NameInputError? nameError = _showValidation
        ? AuthValidators.fullName(_name.text)
        : null;
    final EmailInputError? emailError = _showValidation
        ? AuthValidators.email(_email.text)
        : null;

    return Scaffold(
      appBar: HotelAppBar(title: l10n.authProfileTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          children: <Widget>[
            InfoBanner(
              tone: InfoBannerTone.info,
              title: l10n.authProfileBannerTitle,
              message: l10n.authProfileBannerBody,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: l10n.authProfileNameLabel,
              hintText: l10n.authProfileNameHint,
              controller: _name,
              enabled: !busy,
              textInputAction: TextInputAction.next,
              errorText: nameError == null ? null : l10n.authProfileNameInvalid,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.authProfileEmailLabel,
              hintText: l10n.authProfileEmailHint,
              controller: _email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              errorText: emailError == null
                  ? null
                  : l10n.authProfileEmailInvalid,
            ),
            if (submission.failureOrNull != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                submission.failureOrNull!.localizedMessage(l10n),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.authProfileSubmit,
              isLoading: busy,
              onPressed: busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
