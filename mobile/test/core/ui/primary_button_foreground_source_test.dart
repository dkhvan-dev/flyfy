import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buttons with primary background use textPrimary foreground', () {
    final projectRoot = Directory.current;
    final libDir = Directory('${projectRoot.path}/lib');
    final offenders = <String>[];

    for (final file in _dartFiles(libDir)) {
      final source = file.readAsStringSync();
      for (final match in _buttonStyleFromPattern.allMatches(source)) {
        final block = match.group(0)!;
        if (!_hasPrimaryBackground(block)) continue;
        if (_hasTextPrimaryForeground(block)) continue;

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, match.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Any button style with AppPalette.primary/AppPalette.primary '
          'background must explicitly use textPrimary as foreground.',
    );
  });

  test('button loaders use textPrimary spinner color', () {
    final projectRoot = Directory.current;
    final libDir = Directory('${projectRoot.path}/lib');
    final offenders = <String>[];

    for (final file in _dartFiles(libDir)) {
      final source = file.readAsStringSync();
      for (final block in _buttonBlocks(source)) {
        if (!block.source.contains('CircularProgressIndicator(')) continue;
        if (_hasTextPrimaryLoaderColor(block.source)) continue;

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Loading indicators rendered inside button states must use '
          'textPrimary, not onPrimary/black/warmInk/default theme color.',
    );
  });
}

final _buttonStyleFromPattern = RegExp(
  r'(?:FilledButton|ElevatedButton)\.styleFrom\([\s\S]*?\n\s*\)',
  multiLine: true,
);
final _buttonStartPattern = RegExp(
  r'(?:FilledButton|ElevatedButton|OutlinedButton|TextButton|IconButton)'
  r'(?:\.(?:icon|filled|filledTonal|outlined|tonal))?\(',
);

bool _hasPrimaryBackground(String block) {
  return RegExp(
    r'backgroundColor:\s*AppPalette(?:V2)?\.primary\b',
  ).hasMatch(block);
}

bool _hasTextPrimaryForeground(String block) {
  return RegExp(
    r'foregroundColor:\s*AppPalette(?:V2)?\.textPrimary\b',
  ).hasMatch(block);
}

bool _hasTextPrimaryLoaderColor(String context) {
  return RegExp(
        r'CircularProgressIndicator\([\s\S]*?color:\s*'
        r'AppPalette(?:V2)?\s*\.\s*textPrimary',
      ).hasMatch(context) ||
      RegExp(
        r'AlwaysStoppedAnimation(?:\s*<\s*Color\s*>)?\s*\(\s*'
        r'AppPalette(?:V2)?\s*\.\s*textPrimary',
      ).hasMatch(context);
}

Iterable<_SourceBlock> _buttonBlocks(String source) sync* {
  for (final match in _buttonStartPattern.allMatches(source)) {
    final openParen = source.indexOf('(', match.start);
    final end = _matchingParenEnd(source, openParen);
    if (end == null) continue;
    yield _SourceBlock(
      start: match.start,
      source: source.substring(match.start, end),
    );
  }
}

int? _matchingParenEnd(String source, int openParen) {
  var depth = 0;
  for (var i = openParen; i < source.length; i++) {
    final char = source.codeUnitAt(i);
    if (char == 40) {
      depth++;
      continue;
    }
    if (char == 41) {
      depth--;
      if (depth == 0) return i + 1;
    }
  }
  return null;
}

class _SourceBlock {
  const _SourceBlock({required this.start, required this.source});

  final int start;
  final String source;
}

Iterable<File> _dartFiles(Directory root) sync* {
  for (final entity in root.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

int _lineNumber(String source, int offset) {
  return '\n'.allMatches(source.substring(0, offset)).length + 1;
}
