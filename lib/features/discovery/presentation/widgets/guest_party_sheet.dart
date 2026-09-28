import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/guest_party.dart';
import '../state/guest_party_controller.dart';
import 'guest_stepper.dart';
import 'sheet_scaffold.dart';

/// `16 · Stay dates & available rooms` — the "عدد الضيوف" sheet. Edits the
/// shared [guestPartyControllerProvider] directly and pops on confirm.
Future<void> showGuestPartySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => const _GuestPartySheet(),
  );
}

class _GuestPartySheet extends ConsumerWidget {
  const _GuestPartySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final GuestParty party = ref.watch(guestPartyControllerProvider);
    final GuestPartyController controller =
        ref.read(guestPartyControllerProvider.notifier);

    return SheetScaffold(
      title: l10n.guestsTitle,
      body: <Widget>[
        GuestStepper(
          label: l10n.guestsAdults,
          value: party.adults,
          min: GuestParty.minAdults,
          max: GuestParty.maxAdults,
          onChanged: controller.setAdults,
        ),
        const SizedBox(height: AppSpacing.sm),
        GuestStepper(
          label: l10n.guestsChildren,
          value: party.children,
          min: GuestParty.minChildren,
          max: GuestParty.maxChildren,
          onChanged: controller.setChildren,
        ),
      ],
      footer: PrimaryButton(
        label: l10n.guestsConfirm,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// The " · "-joined party summary, e.g. "2 adults · 1 child". The separator is a
/// visual glyph, not translatable copy.
String guestPartySummaryText(AppLocalizations l10n, GuestParty party) {
  final String adults = l10n.guestsAdultsCount(party.adults);
  if (party.children == 0) return adults;
  return '$adults · ${l10n.guestsChildrenCount(party.children)}';
}
