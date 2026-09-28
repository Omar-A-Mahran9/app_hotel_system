import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/platform/external_launcher.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/banner_screen.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../domain/entities/reservation.dart';
import '../state/reservation_detail_provider.dart';

/// `IDENTITY_ContactReception` (V11) — the shared "تواصل مع الاستقبال"
/// destination the service-request, problem-report and identity screens route
/// to. When the hotel has a front-desk number on file (dashboard hotel form →
/// `hotel.reception_phone`) the primary action dials it; otherwise the screen
/// is informational, exactly as the Figma frame.
class ContactReceptionPage extends ConsumerWidget {
  const ContactReceptionPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> reservation =
        ref.watch(reservationDetailProvider(reservationId));

    return reservation.when(
      loading: () => Scaffold(
        appBar: HotelAppBar(title: l10n.identityContactReceptionCta),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      ),
      error: (Object error, _) => Scaffold(
        appBar: HotelAppBar(title: l10n.identityContactReceptionCta),
        body: MessageView(
          icon: AppIcons.support,
          title: l10n.stateErrorTitle,
          message: l10n.errorGeneric,
          actionLabel: l10n.actionRetry,
          onAction: () => ref.invalidate(reservationDetailProvider(reservationId)),
        ),
      ),
      data: (Reservation r) {
        final String? phone = r.hotelReceptionPhone;
        void toReservation() => context.goNamed(
              AppRoutes.reservationDetailName,
              pathParameters: <String, String>{'reservationId': reservationId},
            );
        void back() => context.canPop() ? context.pop() : toReservation();

        return BannerScreen(
          title: l10n.identityContactReceptionCta,
          tone: InfoBannerTone.info,
          bannerTitle: l10n.identityContactReceptionBannerTitle,
          bannerMessage: phone == null
              ? l10n.contactReceptionNoPhoneBody
              : l10n.contactReceptionBody(phone),
          primaryLabel:
              phone == null ? l10n.identityBackToReservation : l10n.contactReceptionCallCta,
          onPrimary: phone == null
              ? toReservation
              : () async {
                  final bool opened =
                      await ref.read(externalLauncherProvider).dial(phone);
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.contactReceptionCallFailed(phone))),
                      );
                  }
                },
          secondaryLabel: l10n.commonBack,
          onSecondary: back,
        );
      },
    );
  }
}
