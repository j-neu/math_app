import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/answer_normalization.dart';

void main() {
  group('normalizeAnswer', () {
    test('trims surrounding whitespace', () {
      expect(normalizeAnswer('  7  '), '7');
      expect(normalizeAnswer(' 7'), '7');
      expect(normalizeAnswer('7 '), '7');
    });

    test('collapses internal whitespace runs to a single space', () {
      expect(normalizeAnswer('3  4'), '3 4');
      expect(normalizeAnswer('3\t4'), '3 4');
      expect(normalizeAnswer('3 \n  4'), '3 4');
      expect(normalizeAnswer('  3   4  '), '3 4');
    });

    test('keeps German decimal commas as-is', () {
      expect(normalizeAnswer('7,5'), '7,5');
      expect(normalizeAnswer('  7,5 '), '7,5');
    });
  });

  group('answersMatch', () {
    test('exact match after normalisation', () {
      expect(answersMatch('7', ['7']), isTrue);
      expect(answersMatch('  7 ', ['7']), isTrue);
      expect(answersMatch('7', [' 7 ']), isTrue);
    });

    test('mismatch', () {
      expect(answersMatch('8', ['7']), isFalse);
      expect(answersMatch('', ['7']), isFalse);
      expect(answersMatch('7', []), isFalse);
    });

    test('matches any of several expected values', () {
      expect(answersMatch('3', ['3', '4']), isTrue);
      expect(answersMatch('4', ['3', '4']), isTrue);
      expect(answersMatch('5', ['3', '4']), isFalse);
    });

    test('multi-value answers compare after whitespace collapse', () {
      expect(answersMatch('3  4', ['3 4']), isTrue);
      expect(answersMatch('3 4', ['3 4']), isTrue);
      expect(answersMatch('3  5', ['3 4']), isFalse);
    });

    test('German decimal comma is not conflated with a dot', () {
      expect(answersMatch('7,5', ['7,5']), isTrue);
      expect(answersMatch('7.5', ['7,5']), isFalse);
    });
  });
}
