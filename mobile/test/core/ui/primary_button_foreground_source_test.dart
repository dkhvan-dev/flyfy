import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';

void main() {
  test('primary foreground is invariant dark ink in every theme', () {
    expect(AppColorSchemes.dark.onPrimary, const Color(0xFF111827));
    expect(AppColorSchemes.light.onPrimary, const Color(0xFF111827));
  });

  test('buttons with primary background use onPrimary foreground', () {
    final projectRoot = Directory.current;
    final libDir = Directory('${projectRoot.path}/lib');
    final offenders = <String>[];

    for (final file in _dartFiles(libDir)) {
      final source = file.readAsStringSync();
      for (final block in _buttonBlocks(source)) {
        if (!_hasPrimaryBackground(block.source)) continue;
        if (_hasOnPrimaryForeground(block.source) ||
            block.source.contains('AppButtonStyles.primary(')) {
          continue;
        }

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'Any button style with a primary background must explicitly use '
            'the invariant #111827 onPrimary foreground.',
        ...offenders,
      ].join('\n'),
    );
  });

  test('primary button loaders use onPrimary spinner color', () {
    final projectRoot = Directory.current;
    final libDir = Directory('${projectRoot.path}/lib');
    final offenders = <String>[];

    for (final file in _dartFiles(libDir)) {
      final source = file.readAsStringSync();
      for (final block in _buttonBlocks(source)) {
        if (!block.source.contains('CircularProgressIndicator(')) continue;
        if (!_usesPrimaryButtonBackground(block.source)) continue;
        if (_hasOnPrimaryLoaderColor(block.source)) continue;

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'Loading indicators rendered inside primary buttons must use '
            'the invariant #111827 onPrimary color.',
        ...offenders,
      ].join('\n'),
    );
  });

  test('disabled primary buttons keep onPrimary foreground semantics', () {
    final projectRoot = Directory.current;
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('${projectRoot.path}/lib'))) {
      final source = file.readAsStringSync();
      for (final block in _buttonBlocks(source)) {
        final background = _namedArgumentValue(
          block.source,
          'disabledBackgroundColor',
        );
        if (background == null || !_hasPrimaryValue(background)) continue;
        final foreground = _namedArgumentValue(
          block.source,
          'disabledForegroundColor',
        );
        if (foreground != null && _hasOnPrimaryContent(foreground)) continue;

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'Disabled controls derived from a primary background must retain '
            '#111827 onPrimary foreground semantics.',
        ...offenders,
      ].join('\n'),
    );
  });

  test('custom tappable primary surfaces use onPrimary content', () {
    final projectRoot = Directory.current;
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('${projectRoot.path}/lib'))) {
      final source = file.readAsStringSync();
      for (final block in _interactiveBlocks(source)) {
        if (!_hasFullPrimarySurface(block.source)) continue;
        if (RegExp(
          r'\.(?:onPrimary|actionOnPrimary)\b',
        ).hasMatch(block.source)) {
          continue;
        }

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'InkWell/GestureDetector controls with a full primary surface must '
            'render content with #111827 onPrimary.',
        ...offenders,
      ].join('\n'),
    );
  });

  test('Material-owned primary controls use onPrimary content', () {
    final projectRoot = Directory.current;
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('${projectRoot.path}/lib'))) {
      final source = file.readAsStringSync();
      for (final block in _sourceBlocks(source, _materialStartPattern)) {
        final color = _topLevelNamedArgumentValue(block.source, 'color');
        if (color == null || !_hasFullPrimaryValue(color)) continue;
        if (!RegExp(
          r'\b(?:InkWell|InkResponse|GestureDetector)\(',
        ).hasMatch(block.source)) {
          continue;
        }
        if (_hasOnPrimaryContent(block.source)) continue;

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'Interactive Material controls that own a full primary surface must '
            'render their content with #111827 onPrimary.',
        ...offenders,
      ].join('\n'),
    );
  });

  test('primary chips use onPrimary labels and checkmarks', () {
    final projectRoot = Directory.current;
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('${projectRoot.path}/lib'))) {
      final source = file.readAsStringSync();
      for (final block in _sourceBlocks(source, _chipStartPattern)) {
        final selectedColor = _topLevelNamedArgumentValue(
          block.source,
          'selectedColor',
        );
        final backgroundColor = _topLevelNamedArgumentValue(
          block.source,
          'backgroundColor',
        );
        final hasPrimarySurface =
            (selectedColor != null && _hasFullPrimaryValue(selectedColor)) ||
            (backgroundColor != null && _hasFullPrimaryValue(backgroundColor));
        if (!hasPrimarySurface) continue;

        final labelStyle = _topLevelNamedArgumentValue(
          block.source,
          'labelStyle',
        );
        final label = _topLevelNamedArgumentValue(block.source, 'label');
        final hasOnPrimaryLabel =
            (labelStyle != null && _hasOnPrimaryContent(labelStyle)) ||
            (label != null && _hasOnPrimaryContent(label));
        final showCheckmark = _topLevelNamedArgumentValue(
          block.source,
          'showCheckmark',
        );
        final needsCheckmark =
            selectedColor != null && showCheckmark != 'false';
        final checkmarkColor = _topLevelNamedArgumentValue(
          block.source,
          'checkmarkColor',
        );
        final hasOnPrimaryCheckmark =
            !needsCheckmark ||
            (checkmarkColor != null && _hasOnPrimaryContent(checkmarkColor));

        if (hasOnPrimaryLabel && hasOnPrimaryCheckmark) continue;
        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'Choice/Filter/Action/Input chips with a full primary surface must '
            'use #111827 onPrimary for labels and visible checkmarks.',
        ...offenders,
      ].join('\n'),
    );
  });

  test('stateful primary button styles use onPrimary content', () {
    final projectRoot = Directory.current;
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('${projectRoot.path}/lib'))) {
      final source = file.readAsStringSync();
      for (final block in _sourceBlocks(source, _buttonStyleStartPattern)) {
        final background = _topLevelNamedArgumentValue(
          block.source,
          'backgroundColor',
        );
        if (background == null || !_hasFullPrimaryValue(background)) continue;

        final foreground = _topLevelNamedArgumentValue(
          block.source,
          'foregroundColor',
        );
        final iconColor = _topLevelNamedArgumentValue(
          block.source,
          'iconColor',
        );
        final foregroundIsValid =
            foreground != null && _hasOnPrimaryContent(foreground);
        final iconIsValid =
            iconColor == null || _hasOnPrimaryContent(iconColor);
        if (foregroundIsValid && iconIsValid) continue;

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'ButtonStyle selected states with a full primary surface must use '
            '#111827 onPrimary for text and explicitly styled icons.',
        ...offenders,
      ].join('\n'),
    );
  });

  test('primary chip themes use onPrimary selected content', () {
    final projectRoot = Directory.current;
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('${projectRoot.path}/lib'))) {
      final source = file.readAsStringSync();
      for (final block in _sourceBlocks(source, _chipThemeStartPattern)) {
        final selectedColor = _topLevelNamedArgumentValue(
          block.source,
          'selectedColor',
        );
        if (selectedColor == null || !_hasFullPrimaryValue(selectedColor)) {
          continue;
        }

        final selectedLabel = _topLevelNamedArgumentValue(
          block.source,
          'secondaryLabelStyle',
        );
        final checkmark = _topLevelNamedArgumentValue(
          block.source,
          'checkmarkColor',
        );
        if (selectedLabel != null &&
            _hasOnPrimaryContent(selectedLabel) &&
            checkmark != null &&
            _hasOnPrimaryContent(checkmark)) {
          continue;
        }

        offenders.add(
          '${file.path.replaceFirst('${projectRoot.path}/', '')}:'
          '${_lineNumber(source, block.start)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'ChipThemeData with a full primary selected surface must use '
            '#111827 onPrimary for selected labels and checkmarks.',
        ...offenders,
      ].join('\n'),
    );
  });
}

final _buttonStartPattern = RegExp(
  r'(?:FilledButton|ElevatedButton|OutlinedButton|TextButton|IconButton|'
  r'FloatingActionButton)'
  r'(?:\.(?:icon|filled|filledTonal|outlined|tonal))?\(',
);
final _interactiveStartPattern = RegExp(
  r'(?:InkWell|InkResponse|GestureDetector)\(',
);
final _materialStartPattern = RegExp(r'\bMaterial\(');
final _chipStartPattern = RegExp(
  r'\b(?:ChoiceChip|FilterChip|ActionChip|InputChip)\(',
);
final _buttonStyleStartPattern = RegExp(r'\bButtonStyle\(');
final _chipThemeStartPattern = RegExp(
  r'(?:\bChipThemeData|\bchipTheme\.copyWith)\(',
);

bool _hasPrimaryBackground(String block) {
  final value = _namedArgumentValue(block, 'backgroundColor');
  return value != null && _hasFullPrimaryValue(value);
}

bool _hasOnPrimaryForeground(String block) {
  final value = _namedArgumentValue(block, 'foregroundColor');
  return value != null && RegExp(r'\.onPrimary\b').hasMatch(value);
}

bool _usesPrimaryButtonBackground(String block) {
  if (_hasPrimaryBackground(block)) return true;
  if (block.contains('AppButtonStyles.primary(')) return true;

  final isFilledButton = RegExp(r'^FilledButton(?:\.icon)?\(').hasMatch(block);
  if (!isFilledButton) return false;

  final background = _namedArgumentValue(block, 'backgroundColor');
  return background == null;
}

String? _namedArgumentValue(String source, String argument) {
  final match = RegExp('$argument\\s*:').firstMatch(source);
  if (match == null) return null;

  final buffer = StringBuffer();
  var parenDepth = 0;
  for (var index = match.end; index < source.length; index++) {
    final char = source[index];
    if (char == '(' || char == '[' || char == '{') parenDepth++;
    if (char == ')' || char == ']' || char == '}') parenDepth--;
    if (char == ',' && parenDepth == 0) break;
    buffer.write(char);
  }
  return buffer.toString().trim();
}

bool _hasFullPrimarySurface(String source) {
  final surface = _topLevelNamedArgumentValue(source, 'child');
  if (surface == null ||
      !RegExp(
        r'^(?:Container|AnimatedContainer|Ink|DecoratedBox)\(',
      ).hasMatch(surface.trimLeft())) {
    return false;
  }
  var color = _topLevelNamedArgumentValue(surface, 'color');
  if (color == null) {
    final decoration = _topLevelNamedArgumentValue(surface, 'decoration');
    if (decoration != null) {
      color = _topLevelNamedArgumentValue(decoration, 'color');
    }
  }

  return color != null && _hasFullPrimaryValue(color);
}

bool _hasFullPrimaryValue(String value) {
  return RegExp(r'\.(?:primary|amber)\b(?!\s*\.withValues)').hasMatch(value);
}

bool _hasPrimaryValue(String value) {
  return RegExp(r'\.(?:primary|amber)\b').hasMatch(value);
}

bool _hasOnPrimaryContent(String source) {
  return RegExp(r'\.(?:onPrimary|actionOnPrimary)\b').hasMatch(source);
}

String? _topLevelNamedArgumentValue(String source, String argument) {
  final openParen = source.indexOf('(');
  if (openParen < 0) return null;

  var depth = 0;
  for (var index = openParen; index < source.length; index++) {
    final char = source[index];
    if (char == '(' || char == '[' || char == '{') {
      depth++;
      continue;
    }
    if (char == ')' || char == ']' || char == '}') {
      depth--;
      continue;
    }
    if (depth != 1 || !source.startsWith(argument, index)) continue;

    var cursor = index + argument.length;
    while (cursor < source.length && RegExp(r'\s').hasMatch(source[cursor])) {
      cursor++;
    }
    if (cursor >= source.length || source[cursor] != ':') continue;
    cursor++;

    final buffer = StringBuffer();
    var valueDepth = depth;
    for (; cursor < source.length; cursor++) {
      final valueChar = source[cursor];
      if (valueChar == '(' || valueChar == '[' || valueChar == '{') {
        valueDepth++;
      } else if (valueChar == ')' || valueChar == ']' || valueChar == '}') {
        valueDepth--;
      }
      if (valueChar == ',' && valueDepth == depth) break;
      buffer.write(valueChar);
    }
    return buffer.toString().trim();
  }
  return null;
}

bool _hasOnPrimaryLoaderColor(String context) {
  return RegExp(
    r'CircularProgressIndicator\([\s\S]*?'
    r'(?:color|valueColor):[\s\S]*?\.onPrimary\b',
  ).hasMatch(context);
}

Iterable<_SourceBlock> _buttonBlocks(String source) sync* {
  yield* _sourceBlocks(source, _buttonStartPattern);
}

Iterable<_SourceBlock> _sourceBlocks(String source, RegExp pattern) sync* {
  for (final match in pattern.allMatches(source)) {
    final openParen = source.indexOf('(', match.start);
    final end = _matchingParenEnd(source, openParen);
    if (end == null) continue;
    yield _SourceBlock(
      start: match.start,
      source: source.substring(match.start, end),
    );
  }
}

Iterable<_SourceBlock> _interactiveBlocks(String source) sync* {
  for (final match in _interactiveStartPattern.allMatches(source)) {
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
