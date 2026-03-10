/// Development bootstrap configuration for the first developer account.
///
/// SECURITY NOTE:
/// - Defaults are intentionally only for development/testing bootstrap.
/// - In production, provide values through secure env injection or remove
///   bootstrap account creation entirely.
class DevBootstrapConfig {
  static const enabled = bool.fromEnvironment(
    'DEV_BOOTSTRAP_ENABLED',
    defaultValue: true,
  );

  static const seedDeveloperEmail = String.fromEnvironment(
    'DEV_SEED_DEVELOPER_EMAIL',
    defaultValue: 'justinramdin001@gmail.com',
  );

  static const seedDeveloperPassword = String.fromEnvironment(
    'DEV_SEED_DEVELOPER_PASSWORD',
    defaultValue: '8yyncjWKstqd',
  );
}
