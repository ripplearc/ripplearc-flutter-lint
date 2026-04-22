import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:source_span/source_span.dart';

/// A test implementation of [DiagnosticReporter] that collects diagnostics.
///
/// This class is used in tests to verify that lint rules are reporting the
/// expected errors. It implements the [DiagnosticReporter] interface and stores
/// all reported errors in the [errors] list.
///
/// Example:
/// ```dart
/// final reporter = TestErrorReporter();
/// rule.checkClassDeclaration(node, reporter);
/// expect(reporter.errors, hasLength(1));
/// ```
class TestErrorReporter implements DiagnosticReporter {
  /// The list of diagnostics that have been reported.
  final List<Diagnostic> errors = [];
  final bool isNonNullableByDefault = false;
  final _dummySource = StringSource('test.dart', '');
  int _lockLevel = 0;

  Diagnostic _make(
    int offset,
    int length,
    DiagnosticCode code,
    List<DiagnosticMessage>? contextMessages,
  ) {
    final error = Diagnostic.forValues(
      source: _dummySource,
      offset: offset,
      length: length,
      diagnosticCode: code,
      message: code.problemMessage,
      contextMessages: contextMessages ?? const [],
    );
    errors.add(error);
    return error;
  }

  @override
  Diagnostic atConstructorDeclaration(
    ConstructorDeclaration node,
    DiagnosticCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) => _make(node.offset, node.length, errorCode, contextMessages);

  @override
  Diagnostic atElement2(
    Element element,
    DiagnosticCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) => _make(0, 0, errorCode, contextMessages);

  @override
  Diagnostic atEntity(
    SyntacticEntity entity,
    DiagnosticCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) => _make(entity.offset, entity.length, errorCode, contextMessages);

  @override
  Diagnostic atNode(
    AstNode node,
    DiagnosticCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) => _make(node.offset, node.length, errorCode, contextMessages);

  @override
  Diagnostic atOffset({
    required int offset,
    required int length,
    DiagnosticCode? diagnosticCode,
    DiagnosticCode? errorCode,
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) => _make(offset, length, (diagnosticCode ?? errorCode)!, contextMessages);

  @override
  Diagnostic atSourceSpan(
    SourceSpan span,
    DiagnosticCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) => _make(span.start.offset, span.length, errorCode, contextMessages);

  @override
  Diagnostic atToken(
    Token token,
    DiagnosticCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) => _make(token.offset, token.length, errorCode, contextMessages);

  @override
  void reportError(Diagnostic diagnostic) {
    errors.add(diagnostic);
  }

  @override
  int get lockLevel => _lockLevel;
  @override
  set lockLevel(int value) => _lockLevel = value;
  @override
  get source => _dummySource;
}
