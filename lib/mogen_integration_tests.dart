/// CLI tool that scans `lib/features/**/data/datasources/`, extracts GET
/// endpoints, and generates integration tests for each discovered endpoint.
///
/// Run from your Flutter project root:
/// ```sh
/// dart run mogen_integration_tests
/// ```
library mogen_integration_tests;

export 'src/analyzers/datasource_parser.dart';
export 'src/analyzers/datasource_scanner.dart';
export 'src/generators/integration_test_generator.dart';
export 'src/generators/test_orchestrator.dart';
export 'src/models/datasource_info.dart';
