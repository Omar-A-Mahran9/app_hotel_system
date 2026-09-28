import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_content.dart';
import 'app_content_data_source.dart';

typedef Json = Map<String, Object?>;

/// API-backed source: `GET /guest/app-content` (anonymous — shown before any
/// sign-in). Text arrives as full `{"en","ar"}` maps so the entry screens can
/// switch language client-side; image URLs are re-hosted for the emulator via
/// [ApiClient.resolveMediaUrl], never fabricated.
class ApiAppContentDataSource
    implements AppContentDataSource, RemoteDataSource {
  ApiAppContentDataSource(this._client);

  final ApiClient _client;

  @override
  Future<AppContent> fetchContent() async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/app-content',
    );
    final Object? data = json['data'];
    if (data is! Json) return AppContent.empty;
    final Json policy = ((json['meta'] as Json?)?['booking_policy'] as Json?) ?? const <String, Object?>{};

    return AppContent(
      appName: _text(data['app_name_i18n']),
      logoUrl: _url(data['logo_url']),
      onboardingImageUrl: _url(data['onboarding_image_url']),
      onboardingTitle: _text(data['onboarding_title_i18n']),
      onboardingBody: _text(data['onboarding_body_i18n']),
      onboardingCta: _text(data['onboarding_cta_i18n']),
      freeCancellationHours: (policy['free_cancellation_hours'] as num?)?.toInt(),
      identityRetentionDays: (policy['identity_retention_days'] as num?)?.toInt(),
      faq: <FaqEntry>[
        for (final Object? item in (data['faq'] as List<Object?>?) ?? const <Object?>[])
          if (item is Json)
            FaqEntry(
              question: _text(item['question_i18n']),
              answer: _text(item['answer_i18n']),
            ),
      ],
    );
  }

  String? _url(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return _client.resolveMediaUrl(raw);
  }

  static ManagedText _text(Object? raw) {
    if (raw is! Map) return const ManagedText();
    String? pick(String locale) {
      final Object? v = raw[locale];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    return ManagedText(ar: pick('ar'), en: pick('en'));
  }
}
