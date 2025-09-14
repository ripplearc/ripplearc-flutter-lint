import 'package:test/test.dart';

void main() {
  group('Missing Mutation Test', () {
    test('should demonstrate missing mutation file', () {
      // This test file should trigger the rule because there's no corresponding
      // mutation file at test/mutations/missing_mutation_test.xml
      expect(true, isTrue);
    });
  });
}
