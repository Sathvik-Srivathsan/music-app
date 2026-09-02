import 'package:flutter_test/flutter_test.dart';
import 'package:music_collection/features/insert/presentation/providers/insert_provider.dart';

/// Unit tests for the pure INSERT-tab validation used by Preview and
/// Submit: record name mandatory, at least one artist mandatory.
void main() {
  group('validateInsertInput', () {
    test('empty name is rejected', () {
      expect(
        validateInsertInput(recordName: '   ', artistCount: 2),
        'Record name is required',
      );
      expect(
        validateInsertInput(recordName: '', artistCount: 1),
        'Record name is required',
      );
    });

    test('zero artists is rejected', () {
      expect(
        validateInsertInput(recordName: 'Seraphim', artistCount: 0),
        'At least one artist is required',
      );
    });

    test('valid form passes', () {
      expect(
        validateInsertInput(recordName: 'Seraphim', artistCount: 1),
        isNull,
      );
    });

    test('name check takes precedence over artist check', () {
      expect(
        validateInsertInput(recordName: '', artistCount: 0),
        'Record name is required',
      );
    });
  });
}
