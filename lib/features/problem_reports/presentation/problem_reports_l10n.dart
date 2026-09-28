import '../../../core/localization/l10n.dart';
import '../domain/entities/problem_category.dart';
import '../domain/entities/problem_report_status.dart';
import '../domain/entities/problem_urgency.dart';

/// Localized labels for the problem-reports feature's enums. One home for
/// each enum -> string mapping, mirroring `ReviewsL10n` / `StayServicesL10n`.
extension ProblemReportsL10n on AppLocalizations {
  String problemCategoryLabel(ProblemCategory category) => switch (category) {
        ProblemCategory.acHeating => reportCategoryAcHeating,
        ProblemCategory.plumbingWater => reportCategoryPlumbingWater,
        ProblemCategory.electricityLighting => reportCategoryElectricityLighting,
        ProblemCategory.roomCleanliness => reportCategoryRoomCleanliness,
        ProblemCategory.internetWifi => reportCategoryInternetWifi,
        ProblemCategory.noiseDisturbance => reportCategoryNoiseDisturbance,
      };

  String problemUrgencyLabel(ProblemUrgency urgency) => switch (urgency) {
        ProblemUrgency.normal => reportUrgencyNormal,
        ProblemUrgency.important => reportUrgencyImportant,
        ProblemUrgency.urgent => reportUrgencyUrgent,
      };

  String problemReportStatusLabel(ProblemReportStatus status) => switch (status) {
        ProblemReportStatus.open => reportStatusOpen,
        ProblemReportStatus.inProgress => reportStatusInProgress,
        ProblemReportStatus.resolved => reportStatusResolved,
      };
}
