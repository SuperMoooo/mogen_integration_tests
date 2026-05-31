import 'package:dio/dio.dart';

/// Builds a plain Dio client for integration tests.
///
/// Replace the values below with your own API base URL and request
/// timeouts before running the generated tests.
Dio buildTestDio() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://example.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: <String, dynamic>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}

/// Builds an authenticated Dio client for integration tests.
///
/// Implement token acquisition or authentication setup for your app.
Future<Dio> buildAuthenticatedTestDio() async {
  final dio = buildTestDio();
  // TODO: Use a real test account or authentication flow here.
  return dio;
}
