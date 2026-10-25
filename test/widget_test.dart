import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:congo_actions/core/models/models.dart';
import 'package:congo_actions/core/services/supabase_service.dart';
import 'package:congo_actions/core/state/currency_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SupabaseService initial seed data and donation recording test', () async {
    final service = SupabaseService.instance;
    await service.init();

    // Offline unit test without network starts with empty campaigns list
    expect(service.subscriptions.isEmpty, true);

    // Record a donation
    final donation = await service.recordDonation(
      campaignId: 'camp-test-123',
      campaignTitle: 'Emergency Hospital Relief',
      amountUsdCents: 5000,
      amountCdf: 140000,
      currency: 'USD',
      feeCoveredUsdCents: 175,
      feeCoveredCdf: 4900,
      isAnonymous: false,
      paymentMethod: PaymentMethod.mpesa,
      phoneNumber: '+243810001234',
    );

    expect(donation.status, 'SUCCESS');
    expect(donation.amountUsdCents, 5000);
    expect(service.donations.first.id, donation.id);
  });

  test('Currency state formatting and conversions', () {
    final usdFormatted = CurrencyNotifier.formatAmount(
      amountUsdCents: 2500,
      amountCdf: 70000,
      activeCurrency: AppCurrency.usd,
    );
    expect(usdFormatted, '\$25');

    final cdfFormatted = CurrencyNotifier.formatAmount(
      amountUsdCents: 2500,
      amountCdf: 70000,
      activeCurrency: AppCurrency.cdf,
    );
    expect(cdfFormatted.contains('FC'), true);

    expect(CurrencyNotifier.convertUsdToCdf(1000), 28000);
  });
}
