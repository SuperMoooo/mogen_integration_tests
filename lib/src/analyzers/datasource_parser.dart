import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import '../models/datasource_info.dart';

/// Parses datasource source files and extracts GET endpoints for integration tests.
///
/// This parser analyzes Dart source code using the Dart analyzer to find all
/// `dio.get(...)` method calls within datasource classes, extracting endpoint
/// paths and organizing them by HTTP group and name.
class DataSourceParser {
  /// Creates a parser that operates within the given project root.
  ///
  /// The [projectRoot] is used to extract relative feature paths from
  /// datasource file paths.
  DataSourceParser({required this.projectRoot});

  /// The root directory of the Dart/Flutter project.
  final String projectRoot;

  /// Parses all provided datasource files and extracts endpoint information.
  ///
  /// Returns a list of [DataSourceInfo] objects, one per file that contains
  /// at least one GET endpoint. Files that cannot be parsed are silently skipped.
  List<DataSourceInfo> parseAll(List<String> filePaths) {
    final result = <DataSourceInfo>[];
    for (final path in filePaths) {
      try {
        final source = _parse(path);
        if (source.endpoints.isNotEmpty) {
          result.add(source);
        }
      } catch (_) {
        // Skip files that cannot be parsed.
      }
    }
    return result;
  }

  DataSourceInfo _parse(String filePath) {
    final content = File(filePath).readAsStringSync();
    final parsed = parseString(content: content, path: filePath);
    final visitor = _DataSourceVisitor(filePath: filePath);
    parsed.unit.visitChildren(visitor);

    final featureName = _extractFeatureName(filePath);
    return DataSourceInfo(
      featureName: featureName,
      sourceFilePath: filePath,
      endpoints: visitor.endpoints,
    );
  }

  String _extractFeatureName(String filePath) {
    final rel = p.relative(filePath, from: projectRoot).replaceAll('\\', '/');
    final segments = rel.split('/');
    final featureIndex = segments.indexOf('features');
    if (featureIndex >= 0 && segments.length > featureIndex + 1) {
      return segments[featureIndex + 1];
    }
    return 'unknown';
  }
}

class _DataSourceVisitor extends RecursiveAstVisitor<void> {
  _DataSourceVisitor({required this.filePath});

  final String filePath;
  final endpoints = <EndpointInfo>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Use node.name.lexeme (correct AST API for the class identifier).
    final className = node.namePart.typeName.lexeme;
    final body = node.body;
    if (body is! BlockClassBody) return;
    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      final methodName = member.name.lexeme;
      final visitor = _DioGetVisitor();
      member.body.visitChildren(visitor);
      for (final endpoint in visitor.endpoints) {
        endpoints.add(EndpointInfo(
          className: className,
          methodName: methodName,
          httpMethod: 'GET',
          endpoint: endpoint,
          group: _extractGroup(endpoint),
          name: _extractName(endpoint),
          sourceFilePath: filePath,
        ));
      }
    }
  }

  String _extractGroup(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final parts =
        path.split('/').where((segment) => segment.isNotEmpty).toList();
    return parts.isEmpty ? 'unknown' : parts.first;
  }

  String _extractName(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final parts =
        path.split('/').where((segment) => segment.isNotEmpty).toList();
    if (parts.length <= 1) return parts.isEmpty ? 'root' : parts.first;
    return parts.skip(1).join('-');
  }
}

class _DioGetVisitor extends RecursiveAstVisitor<void> {
  final endpoints = <String>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final methodName = node.methodName.name;
    if (methodName != 'get') return;

    final target = node.realTarget?.toSource();
    if (target == null) return;
    if (!target.endsWith('dio') && !target.endsWith('Dio')) return;

    if (node.argumentList.arguments.isEmpty) return;

    final firstArgNode = node.argumentList.arguments.first;
    Expression? expr;
    final dynamic dyn = firstArgNode;
    try {
      final maybe = dyn.expression;
      if (maybe is Expression) expr = maybe;
    } catch (_) {
      // ignore - no `.expression` property
    }
    expr ??= firstArgNode;

    final endpoint = _extractEndpoint(expr);
    if (endpoint != null) {
      if (!endpoints.contains(endpoint)) {
        endpoints.add(endpoint);
      }
    }
  }

  String? _extractEndpoint(Expression arg) {
    if (arg is StringLiteral) {
      return arg.stringValue;
    }
    return null;
  }
}
