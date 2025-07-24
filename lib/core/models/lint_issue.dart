class LintIssue {
  final int offset;
  final int length;
  final int line;
  final int column;
  final String ruleName;
  final String message;
  final String correctionMessage;
  final String severity;

  const LintIssue({
    required this.offset,
    required this.length,
    required this.line,
    required this.column,
    required this.ruleName,
    required this.message,
    required this.correctionMessage,
    required this.severity,
  });

  @override
  String toString() => '$line:$column • $message';
}
