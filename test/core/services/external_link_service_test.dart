import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/external_link_service.dart';

void main() {
  group('ExternalLinkService', () {
    test('callPhone returns false for empty or non-numeric input', () async {
      expect(await ExternalLinkService.callPhone(''), isFalse);
      expect(await ExternalLinkService.callPhone('   '), isFalse);
      expect(await ExternalLinkService.callPhone('abc-xyz'), isFalse);
    });

    test('openMap returns false for empty or blank address', () async {
      expect(await ExternalLinkService.openMap(''), isFalse);
      expect(await ExternalLinkService.openMap('   '), isFalse);
    });
  });
}
