import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile UI files use the app design system instead of inline styles', () {
    final projectRoot = Directory.current;
    final libDir = Directory('${projectRoot.path}/lib');
    final offenders = <String>[];

    for (final file in _uiSourceFiles(libDir)) {
      final source = file.readAsStringSync();
      for (final rule in _rules) {
        final matches = rule.pattern.allMatches(source);
        for (final match in matches) {
          final line = _lineNumber(source, match.start);
          offenders.add(
            '${file.path.replaceFirst('${projectRoot.path}/', '')}:$line ${rule.message}',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'UI files must consume mobile/lib/core/ui/app_design_system.dart. '
          'Move low-level style primitives into the design system before using them.',
    );
  });
}

final _rules = <_DesignSystemRule>[
  _DesignSystemRule(
    RegExp(r'''app_colors\.dart['"]'''),
    'imports app_colors.dart directly',
  ),
  _DesignSystemRule(RegExp(r'\bColor\s*\(0x'), 'uses direct Color constructor'),
  _DesignSystemRule(
    RegExp(r'\bAppColor\s*\('),
    'uses low-level AppColor constructor',
  ),
  _DesignSystemRule(RegExp(r'\bColors\.'), 'uses direct Material Colors token'),
  _DesignSystemRule(
    RegExp(r'\bAppColors\s*\.'),
    'uses low-level AppColors token',
  ),
  _DesignSystemRule(
    RegExp(r'\bAppMaterialColors\s*\.'),
    'uses low-level AppMaterialColors token',
  ),
  _DesignSystemRule(RegExp(r'\bTextStyle\s*\('), 'uses direct TextStyle'),
  _DesignSystemRule(
    RegExp(r'\bEdgeInsets(?:Directional)?\.'),
    'uses direct EdgeInsets',
  ),
  _DesignSystemRule(
    RegExp(r'\bBoxDecoration\s*\('),
    'uses direct BoxDecoration',
  ),
  _DesignSystemRule(RegExp(r'\bBorderRadius\.'), 'uses direct BorderRadius'),
  _DesignSystemRule(
    RegExp(r'\bRadius\.circular\s*\('),
    'uses direct Radius.circular',
  ),
  _DesignSystemRule(
    RegExp(r'\bInputDecoration\s*\('),
    'uses direct InputDecoration',
  ),
];

Iterable<File> _uiSourceFiles(Directory libDir) sync* {
  final appBootstrap = File('${libDir.path}/main.dart');
  if (appBootstrap.existsSync()) {
    yield appBootstrap;
  }

  final uiRoots = <String>[
    '${libDir.path}/screens',
    '${libDir.path}/features',
    '${libDir.path}/shared/widgets',
    '${libDir.path}/core/ui',
  ];

  for (final rootPath in uiRoots) {
    final root = Directory(rootPath);
    if (!root.existsSync()) continue;

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (_isExcluded(entity)) continue;
      yield entity;
    }
  }
}

bool _isExcluded(File file) {
  final path = file.path;
  return path.endsWith('/core/ui/app_design_system.dart') ||
      path.endsWith('/core/ui/app_design_system.dart') ||
      path.endsWith('/core/ui/app_colors.dart') ||
      path.contains('/l10n/generated/');
}

int _lineNumber(String source, int offset) {
  return '\n'.allMatches(source.substring(0, offset)).length + 1;
}

class _DesignSystemRule {
  const _DesignSystemRule(this.pattern, this.message);

  final RegExp pattern;
  final String message;
}
