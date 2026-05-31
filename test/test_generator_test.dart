import 'dart:io';

import 'package:mogen_integration_tests/src/analyzers/datasource_parser.dart';
import 'package:mogen_integration_tests/src/analyzers/datasource_scanner.dart';
import 'package:mogen_integration_tests/src/generators/integration_test_generator.dart';
import 'package:mogen_integration_tests/src/models/datasource_info.dart';
import 'package:test/test.dart';

void main() {
  group('DataSourceScanner', () {
    test('finds _remote_datasource.dart files in datasource folders', () {
      final tmpDir = Directory.systemTemp.createTempSync('mogen_ds_scan_');
      try {
        final featureDir =
            Directory('${tmpDir.path}${Platform.pathSeparator}auth');
        final datasourceDir = Directory(
            '${featureDir.path}${Platform.pathSeparator}data${Platform.pathSeparator}datasources');
        datasourceDir.createSync(recursive: true);
        File('${datasourceDir.path}${Platform.pathSeparator}auth_remote_datasource.dart')
            .writeAsStringSync('class AuthRemoteDataSource {}');
        File('${datasourceDir.path}${Platform.pathSeparator}other_data_source.dart')
            .writeAsStringSync('class OtherDataSource {}');

        final scanner = DataSourceScanner(featuresRoot: tmpDir.path);
        final bundles = scanner.scan();

        expect(bundles, hasLength(1));
        expect(bundles.first.featureName, 'auth');
        expect(bundles.first.datasourceFiles, hasLength(1));
        expect(bundles.first.datasourceFiles.single,
            endsWith('auth_remote_datasource.dart'));
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });
  });

  group('DataSourceParser', () {
    test('parses GET endpoints from datasource files', () {
      final tmpDir = Directory.systemTemp.createTempSync('mogen_ds_parse_');
      try {
        final featureDir = Directory(
            '${tmpDir.path}${Platform.pathSeparator}features${Platform.pathSeparator}auth${Platform.pathSeparator}data${Platform.pathSeparator}datasources');
        featureDir.createSync(recursive: true);
        final file = File(
            '${featureDir.path}${Platform.pathSeparator}auth_remote_datasource.dart');
        file.writeAsStringSync('''
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<void> login() async {
    await dio.get('/Authenticate/Auth');
  }
}
''');

        final parser = DataSourceParser(projectRoot: tmpDir.path);
        final sources = parser.parseAll([file.path]);

        expect(sources, hasLength(1));
        expect(sources.first.endpoints, hasLength(1));
        expect(sources.first.endpoints.first.endpoint, '/Authenticate/Auth');
        expect(sources.first.endpoints.first.group, 'Authenticate');
        expect(sources.first.endpoints.first.name, 'Auth');
        expect(sources.first.endpoints.first.featureName, 'auth');
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('skips invalid GET endpoint arguments', () {
      final tmpDir = Directory.systemTemp.createTempSync('mogen_ds_parse_');
      try {
        final featureDir = Directory(
            '${tmpDir.path}${Platform.pathSeparator}features${Platform.pathSeparator}auth${Platform.pathSeparator}data${Platform.pathSeparator}datasources');
        featureDir.createSync(recursive: true);
        final file = File(
            '${featureDir.path}${Platform.pathSeparator}auth_remote_datasource.dart');
        file.writeAsStringSync('''
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<void> login() async {
    await dio.get(url);
  }
}
''');

        final parser = DataSourceParser(projectRoot: tmpDir.path);
        final sources = parser.parseAll([file.path]);

        expect(sources, isEmpty);
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });
  });

  group('IntegrationTestGenerator', () {
    test('generates a valid Dio integration test for a GET endpoint', () {
      const endpoint = EndpointInfo(
        className: 'AuthRemoteDataSource',
        methodName: 'login',
        httpMethod: 'GET',
        endpoint: '/Authenticate/Auth',
        group: 'Authenticate',
        name: 'Auth',
        featureName: 'auth',
        sourceFilePath:
            '/project/lib/features/auth/data/datasources/auth_remote_datasource.dart',
      );

      final generator = IntegrationTestGenerator();
      final output = generator.generate(
        endpoint,
        packageName: 'my_app',
      );

      expect(output, contains("group('GET /Authenticate/Auth'"));
      expect(output, contains('datasource.login()'));
      expect(output, contains('buildTestDio()'));
      expect(output, contains('AuthRemoteDataSource(dio)'));
      expect(output, contains('on DioException catch'));
    });
  });
}
