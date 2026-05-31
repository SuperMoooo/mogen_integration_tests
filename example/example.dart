// ignore_for_file: avoid_print

/// Example usage for mogen_integration_tests.
///
/// Place your datasource files under:
///
/// ```
/// lib/
/// └── features/
///     └── auth/
///         └── data/
///             └── datasources/
///                 └── auth_remote_datasource.dart
/// ```
///
/// Then from the project root run:
///
/// ```
/// dart run mogen_integration_tests
/// ```
///
/// To generate tests for a single feature:
///
/// ```
/// dart run mogen_integration_tests --feature auth
/// ```
///
/// Generated tests are written to:
///
/// ```
/// test/integration/features/auth/
/// ```
library;

void main() {
  print(
      'Run `dart run mogen_integration_tests` from your Flutter project root.');
}
