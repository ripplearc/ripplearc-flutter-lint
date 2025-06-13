import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:source_span/source_span.dart';

/// A test implementation of [ErrorReporter] that collects analysis errors.
///
/// This class is used in tests to verify that lint rules are reporting the
/// expected errors. It implements the [ErrorReporter] interface and stores
/// all reported errors in the [errors] list.
///
/// Example:
/// ```dart
/// final reporter = TestErrorReporter();
/// rule.checkClassDeclaration(node, reporter);
/// expect(reporter.errors, hasLength(1));
/// ```
class TestErrorReporter implements ErrorReporter {
  /// The list of analysis errors that have been reported.
  final List<AnalysisError> errors = [];
  final bool isNonNullableByDefault = false;
  final _dummySource = StringSource('test.dart', '');
  int _lockLevel = 0;

  @override
  void atConstructorDeclaration(
    ConstructorDeclaration node,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    errors.add(AnalysisError.forValues(
      source: _dummySource,
      offset: node.offset,
      length: node.length,
      errorCode: errorCode,
      message: errorCode.problemMessage,
      contextMessages: contextMessages ?? const [],
    ));
  }

  @override
  void atElement(
    Element element,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {}

  @override
  void atElement2(
    Element2 element,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {}

  @override
  void atEntity(
    SyntacticEntity entity,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {}

  @override
  void atNode(
    AstNode node,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    errors.add(AnalysisError.forValues(
      source: _dummySource,
      offset: node.offset,
      length: node.length,
      errorCode: errorCode,
      message: errorCode.problemMessage,
      contextMessages: contextMessages ?? const [],
    ));
  }

  @override
  void atOffset({
    required int offset,
    required int length,
    required ErrorCode errorCode,
    List<Object>? arguments,
    List<dynamic>? contextMessages,
    Object? data,
  }) {}

  @override
  void atSourceSpan(
    SourceSpan span,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<dynamic>? contextMessages,
    Object? data,
  }) {}

  @override
  void atToken(
    Token token,
    ErrorCode errorCode, {
    List<Object>? arguments,
    List<dynamic>? contextMessages,
    Object? data,
  }) {}

  @override
  void reportError(AnalysisError error) {
    errors.add(error);
  }

  @override
  int get lockLevel => _lockLevel;
  @override
  set lockLevel(int value) => _lockLevel = value;
  @override
  get source => _dummySource;
} 