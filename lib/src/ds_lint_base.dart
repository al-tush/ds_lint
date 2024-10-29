import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _DSLintPlugin();

// inspired by https://pub.dev/packages/l10n_lint

class _DSLintPlugin extends PluginBase {
  _DSLintPlugin();

  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      const AvoidCupertinoPackage(),
      const AvoidRelativeImports(),
      AvoidNonTranslatedStringRule(
        tsvName: configs.rules[AvoidNonTranslatedStringRule.name]
            ?.json['tsv_file'] as String?,
        configs: configs,
      ),
    ];
  }
}

class AvoidCupertinoPackage extends DartLintRule {
  const AvoidCupertinoPackage() : super(code: _code);

  static const name = 'avoid_cupertino_package_ds';

  static const _code = LintCode(
    name: name,
    problemMessage: 'Cupertino package should not be used currently',
    correctionMessage: 'Use material.dart instead',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      if (node.uri.toString().contains('/cupertino.dart')) {
        reporter.atNode(node, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_AvoidCupertinoPackageFix()];
}

class _AvoidCupertinoPackageFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addImportDirective((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
          message: 'Remove cupertino.dart import', priority: 100);

      var range = node.sourceRange;
      range = SourceRange(range.offset, range.length + 1);
      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(range, '');
      });
    });
  }
}

/// Relates with https://dart.dev/tools/linter-rules/always_use_package_imports
class AvoidRelativeImports extends DartLintRule {
  const AvoidRelativeImports() : super(code: _code);

  static const name = 'avoid_relative_imports_ds';

  static const _code = LintCode(
    name: name,
    problemMessage: 'Do not use .. in import directives',
    correctionMessage: 'Use package import instead',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      if (node.uri.toString().contains('..')) {
        reporter.atNode(node, code);
      }
    });
  }
}

class TsvReader {
  final AvoidNonTranslatedStringRule owner;
  TsvReader({
    required this.owner,
  });

  var _lastTsvRead = DateTime(0);
  var _lastTsvCheck = DateTime(0);
  final transl = <String>{};

  void checkTsvActual() {
    if (owner.tsvName == null) {
      _lastTsvCheck = DateTime.now().add(Duration(minutes: 1));
      throw Exception(
          'tsv_file should be assigned for ${AvoidNonTranslatedStringRule.name} in analysis_options.yaml');
    }

    if (_lastTsvCheck.add(Duration(seconds: 1)).isAfter(DateTime.now())) return;
    _lastTsvCheck = DateTime.now();

    final file = File(owner.tsvName!);
    final lastModified = file.lastModifiedSync();
    if (!lastModified.isAfter(_lastTsvRead)) return;

    _lastTsvRead = lastModified;
    final lines = file.readAsLinesSync();
    transl.clear();
    for (final (idx, line) in lines.indexed) {
      if (idx == 0) continue;
      final parts = line.split('\t');
      if (parts[0].trim().isEmpty) continue;
      transl.add(parts[0]);
    }
  }
}

class AvoidNonTranslatedStringRule extends DartLintRule {
  AvoidNonTranslatedStringRule({
    required this.tsvName,
    required this.configs,
  }) : super(code: _code);

  /// Metadata about the warning that will show-up in the IDE.
  /// This is used for `// ignore: code` and enabling/disabling the lint

  final String? tsvName;
  late final _reader = TsvReader(owner: this);

  final CustomLintConfigs configs;

  static const name = 'avoid_non_translated_string_ds';

  static final _code = LintCode(
    name: name,
    problemMessage: 'Not found in easy_localization file',
    correctionMessage: 'Add this string to easy_localization translation',
    errorSeverity: ErrorSeverity.WARNING,
    uniqueName: name,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    try {
      _reader.checkTsvActual();
    } catch (e) {
      print('$e');
      return;
    }


    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'tr') {
        if (node.realTarget is! StringLiteral) return;
        var s = (node.realTarget as StringLiteral).stringValue;
        if (s == null) return;

        if (_reader.transl.isEmpty) {
          reporter.atNode(
              node,
              LintCode(
                name: name,
                problemMessage: 'No tsv file found',
                correctionMessage:
                    'Add a tsv file to the rule in analysis_options.yaml',
                errorSeverity: ErrorSeverity.WARNING,
                uniqueName: name,
              ));
          return;
        }

        if (s.startsWith("'") && s.endsWith("'") ||
            s.startsWith('"') && s.endsWith('"')) {
          s = s.substring(1, s.length - 1);
        }
        s = s.replaceAll('\n', '\\n');

        if (_reader.transl.contains(s)) return;
        reporter.atNode(
            node,
            LintCode(
              name: name,
              problemMessage: 'Not found in easy_localization file: $s',
              correctionMessage:
                  'Add this string to easy_localization translation',
              errorSeverity: ErrorSeverity.WARNING,
              uniqueName: name,
            ));
      }
    });
  }
}
