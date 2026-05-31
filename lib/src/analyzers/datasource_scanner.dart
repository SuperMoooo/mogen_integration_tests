import 'dart:io';

import 'package:path/path.dart' as p;

/// Scans `lib/features/<feature>/data/datasources` for datasource files.
///
/// This scanner discovers all `*_remote_datasource.dart` files organized
/// under the features directory structure, grouping them by feature name.
class DataSourceScanner {
  /// Creates a scanner for the given features root directory.
  ///
  /// The [featuresRoot] should point to `lib/features` in your Flutter project.
  /// Throws [ArgumentError] if the directory does not exist.
  DataSourceScanner({required this.featuresRoot});

  /// The root directory containing feature folders.
  final String featuresRoot;

  /// Scans the features directory and returns bundles of datasource files per feature.
  ///
  /// Returns a list of [DataSourceBundle] objects, one per feature that contains
  /// at least one `*_remote_datasource.dart` file.
  /// Throws [ArgumentError] if [featuresRoot] does not exist.
  List<DataSourceBundle> scan() {
    final dir = Directory(featuresRoot);
    if (!dir.existsSync()) {
      throw ArgumentError('Features directory not found: $featuresRoot');
    }
    final bundles = <DataSourceBundle>[];
    for (final featureDir in dir.listSync().whereType<Directory>()) {
      final featureName = p.basename(featureDir.path);
      final datasourceDir =
          Directory(p.join(featureDir.path, 'data', 'datasources'));
      if (!datasourceDir.existsSync()) continue;
      final datasourceFiles = _dartFiles(datasourceDir);
      if (datasourceFiles.isEmpty) continue;
      bundles.add(DataSourceBundle(
        featureName: featureName,
        datasourceFiles: datasourceFiles,
      ));
    }
    return bundles;
  }

  List<String> _dartFiles(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_remote_datasource.dart'))
      .map((f) => f.path)
      .toList();
}

/// A bundle of datasource files for a single feature.
class DataSourceBundle {
  /// Creates a datasource bundle for a feature.
  const DataSourceBundle({
    required this.featureName,
    required this.datasourceFiles,
  });

  /// The name of the feature (e.g., 'auth', 'cart').
  final String featureName;

  /// Absolute paths to all `*_remote_datasource.dart` files in this feature.
  final List<String> datasourceFiles;
}
