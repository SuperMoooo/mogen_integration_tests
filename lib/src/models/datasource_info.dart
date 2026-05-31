/// Metadata for a datasource file and its discovered endpoints.
///
/// Represents a single datasource file within a feature, along with all
/// GET endpoints found within it.
class DataSourceInfo {
  /// Creates metadata for a datasource file.
  const DataSourceInfo({
    required this.featureName,
    required this.sourceFilePath,
    required this.endpoints,
  });

  /// The feature name (e.g., 'auth', 'cart').
  final String featureName;

  /// Absolute file path to the datasource source file.
  final String sourceFilePath;

  /// All GET endpoints discovered in this datasource.
  final List<EndpointInfo> endpoints;
}

/// Details for a single GET endpoint discovered in a datasource.
///
/// Contains information about a specific `dio.get(...)` call found in a
/// datasource method, including the endpoint path, HTTP method, class and
/// method names, and derived grouping information.
class EndpointInfo {
  /// Creates endpoint metadata for a discovered GET call.
  const EndpointInfo({
    required this.className,
    required this.methodName,
    required this.httpMethod,
    required this.endpoint,
    required this.group,
    required this.name,
    required this.sourceFilePath,
  });

  /// The datasource class name containing this endpoint call.
  final String className;

  /// The method name within the datasource class.
  final String methodName;

  /// The HTTP method (always 'GET' for current implementation).
  final String httpMethod;

  /// The endpoint path (e.g., '/Authenticate/Auth').
  final String endpoint;

  /// The primary path segment, used for test file grouping (e.g., 'Authenticate').
  final String group;

  /// The secondary path segment(s), used for test naming (e.g., 'Auth').
  final String name;

  /// Absolute file path to the datasource file containing this endpoint.
  final String sourceFilePath;

  /// Generates the test file name from the endpoint's name and group.
  ///
  /// Example: endpoint `/Authenticate/Auth` → fileName: 'auth_test.dart'
  String get fileName {
    final segment = name.isEmpty ? group : name;
    return '${_toSnakeCase(segment)}_test.dart';
  }

  /// Returns the test directory name based on the endpoint's group.
  ///
  /// Used to organize test files under `test/integration/features/<importGroup>/`
  /// Example: group 'Authenticate' → importGroup: 'authenticate'
  String get importGroup => _toSnakeCase(group);

  String _toSnakeCase(String value) {
    final words = value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'__+'), '_')
        .trim();
    return words.toLowerCase().replaceAll(RegExp(r'^_|_$'), '');
  }
}
