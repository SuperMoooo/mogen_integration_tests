import 'dart:io';

import 'package:path/path.dart' as p;

import '../analyzers/datasource_parser.dart';
import '../analyzers/datasource_scanner.dart';
import '../generators/integration_test_generator.dart';

/// Runs the datasource scan and writes generated integration tests into
/// `test/integration/features`.
class TestOrchestrator {
  /// Creates an orchestrator for the given project.
  TestOrchestrator({
    required this.projectRoot,
    required this.packageName,
    this.dryRun = false,
    this.verbose = false,
    this.feature,
  });

  /// Absolute path to the project root.
  final String projectRoot;

  /// The Dart package name, used to construct datasource import paths.
  final String packageName;

  /// When `true`, generated files are not written to disk.
  final bool dryRun;

  /// When `true`, progress messages are emitted during execution.
  final bool verbose;

  /// If non-null, only generate tests for this feature name.
  final String? feature;

  /// Scans the project, parses datasources, and writes tests.
  Future<OrchestratorResult> run() async {
    final featuresRoot = p.join(projectRoot, 'lib', 'features');
    final testRoot = p.join(projectRoot, 'test', 'integration');

    final scanner = DataSourceScanner(featuresRoot: featuresRoot);
    final parser = DataSourceParser(projectRoot: projectRoot);
    final generator = IntegrationTestGenerator();

    var bundles = scanner.scan();
    if (feature != null && feature!.isNotEmpty) {
      bundles = bundles.where((b) => b.featureName == feature).toList();
    }
    _log('Found ${bundles.length} feature(s)\n');

    int written = 0;
    int skipped = 0;
    final errors = <String>[];

    _prepareHelper(testRoot);

    for (final bundle in bundles) {
      _log('📁  ${bundle.featureName}');

      final sources = parser.parseAll(bundle.datasourceFiles);
      _log('    datasource files: ${bundle.datasourceFiles.length}');
      _log(
          '    endpoints: ${sources.fold<int>(0, (sum, source) => sum + source.endpoints.length)}');

      for (final source in sources) {
        for (final endpoint in source.endpoints) {
          try {
            final content = generator.generate(
              endpoint,
              packageName: packageName,
            );
            final outPath = p.join(
              testRoot,
              'features',
              endpoint.importGroup,
              endpoint.fileName,
            );

            if (dryRun) {
              _log('    [dry-run] → $outPath');
              skipped++;
            } else {
              _write(outPath, content);
              _log('    📝  → $outPath');
              written++;
            }
          } catch (e, st) {
            final msg = 'Error generating ${source.sourceFilePath}: $e\n$st';
            errors.add(msg);
            stderr.writeln('⚠️   $msg');
          }
        }
      }
      _log('');
    }

    return OrchestratorResult(
      featuresScanned: bundles.length,
      filesWritten: written,
      filesSkipped: skipped,
      errors: errors,
    );
  }

  void _prepareHelper(String testRoot) {
    final helperPath = p.join(testRoot, 'dio_helper.dart');
    if (dryRun) {
      _log('    [dry-run] → $helperPath');
      return;
    }

    final helper = File(helperPath);
    if (!helper.existsSync()) {
      helper.parent.createSync(recursive: true);
      helper.writeAsStringSync(_dioHelperContent);
      _log('    🛠  created helper $helperPath');
    }
  }

  void _write(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  void _log(String msg) {
    if (verbose) stdout.writeln(msg);
  }

  static const _dioHelperContent = '''import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../../lib/config/env/app_env.dart';
import '../../lib/core/constants/api_constants.dart';
import '../../lib/core/utils/app_logger.dart';

/// Builds a plain Dio client for integration tests.
///
/// Replace the values below with your own API base URL and request
/// timeouts before running the generated tests.
Dio buildTestDio() {
  final dio =
      Dio(
          BaseOptions(
            baseUrl: "",
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (msg) => appLogger.d(msg.toString()),
          ),
        );

  return dio;
}

''';
}

/// Summary of the results produced by a test generation run.
class OrchestratorResult {
  /// Number of features scanned.
  final int featuresScanned;

  /// Number of files successfully written.
  final int filesWritten;

  /// Number of files skipped because dry-run mode was active.
  final int filesSkipped;

  /// Errors encountered during generation.
  final List<String> errors;

  /// Creates a result summary.
  const OrchestratorResult({
    required this.featuresScanned,
    required this.filesWritten,
    required this.filesSkipped,
    required this.errors,
  });

  /// Returns `true` when the run produced one or more errors.
  bool get hasErrors => errors.isNotEmpty;
}
