import 'dart:async';

import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:build/build.dart';
import 'package:angular/src/compiler/source_module.dart';
import 'package:angular/src/source_gen/common/url_resolver.dart';
import 'package:angular_compiler/cli.dart';

import '../common/ng_compiler.dart';
import 'zone.dart' as zone;

Future<Map<AssetId, String>> processStylesheet(
    BuildStep buildStep, AssetId stylesheetId, CompilerFlags flags) async {
  final stylesheetUrl = toAssetUri(stylesheetId);
  final templateCompiler =
      zone.templateCompiler ?? createTemplateCompiler(buildStep, flags);
  final cssText = await buildStep.readAsString(stylesheetId);
  final sourceModules =
      templateCompiler.compileStylesheet(stylesheetUrl, cssText);

  return new Map.fromIterable(sourceModules,
      key: (module) => new AssetId.resolve((module as SourceModule).moduleUrl),
      value: (module) => _writeSourceModule(module as SourceModule));
}

/// Writes the full Dart code for the provided [SourceModule].
String _writeSourceModule(SourceModule sourceModule, {String libraryName}) {
  if (sourceModule == null) return null;
  var buf = new StringBuffer();
  libraryName = _sanitizeLibName(
      libraryName != null ? libraryName : sourceModule.moduleUrl);
  buf..writeln('library $libraryName;')..writeln();

  buf..writeln()..writeln(sourceModule.source);

  return buf.toString();
}

final _unsafeCharsPattern = new RegExp(r'[^a-zA-Z0-9_\.]');
String _sanitizeLibName(String moduleUrl) {
  var sanitized =
      moduleUrl.replaceAll(_unsafeCharsPattern, '_').replaceAll('/', '.');
  for (var keyword in Keyword.values) {
    sanitized.replaceAll(keyword.lexeme, '${keyword.lexeme}_');
  }
  return sanitized;
}
