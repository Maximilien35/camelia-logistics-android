import 'package:camelia/core/platform/push_registrar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushHint.isInformational', () {
    test('campagnes et push de test : rien à relire (§ 7.7.3, lot 10)', () {
      for (final event in const ['campaign', 'campaign.test', 'admin.test']) {
        final hint = PushHint.fromData({'event': event, 'campaign_id': 'c1'});
        expect(hint.isInformational, isTrue, reason: event);
      }
    });

    test('les événements transactionnels restent à traiter', () {
      for (final event in const [
        'order.status_changed',
        'driver_offer.sent',
        'driver_account.approved',
      ]) {
        expect(PushHint.fromData({'event': event}).isInformational, isFalse);
      }
    });
  });
}
