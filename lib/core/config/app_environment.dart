/// Deployment targets. Each maps to a different Laravel API base URL
/// (mobile/docs/ci_cd_guide.md — "Build Configuration").
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromName(String value) {
    return AppEnvironment.values.firstWhere(
      (AppEnvironment e) => e.name == value,
      orElse: () => AppEnvironment.development,
    );
  }
}
