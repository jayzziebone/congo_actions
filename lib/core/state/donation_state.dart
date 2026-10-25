import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class DonationFlowState {
  final Campaign? selectedCampaign;
  final bool isMonthlySubscription;
  final int selectedAmountUsdCents;
  final int selectedAmountCdf;
  final bool coverFees;
  final bool isAnonymous;
  final PaymentMethod selectedPaymentMethod;
  final String donorPhoneNumber;
  final bool isProcessing;
  final int ussdRemainingSeconds;
  final Donation? completedDonation;
  final String? errorMessage;

  DonationFlowState({
    this.selectedCampaign,
    this.isMonthlySubscription = false,
    this.selectedAmountUsdCents = 2500, // $25 default
    this.selectedAmountCdf = 70000, // 70,000 FC default
    this.coverFees = true,
    this.isAnonymous = false,
    this.selectedPaymentMethod = PaymentMethod.mpesa,
    this.donorPhoneNumber = '+243810001234',
    this.isProcessing = false,
    this.ussdRemainingSeconds = 60,
    this.completedDonation,
    this.errorMessage,
  });

  // Calculate 3.5% fee
  int get feeUsdCents => coverFees ? (selectedAmountUsdCents * 0.035).round() : 0;
  int get feeCdf => coverFees ? (selectedAmountCdf * 0.035).round() : 0;

  int get totalChargedUsdCents => selectedAmountUsdCents + feeUsdCents;
  int get totalChargedCdf => selectedAmountCdf + feeCdf;

  DonationFlowState copyWith({
    Campaign? selectedCampaign,
    bool? isMonthlySubscription,
    int? selectedAmountUsdCents,
    int? selectedAmountCdf,
    bool? coverFees,
    bool? isAnonymous,
    PaymentMethod? selectedPaymentMethod,
    String? donorPhoneNumber,
    bool? isProcessing,
    int? ussdRemainingSeconds,
    Donation? completedDonation,
    String? errorMessage,
  }) {
    return DonationFlowState(
      selectedCampaign: selectedCampaign ?? this.selectedCampaign,
      isMonthlySubscription: isMonthlySubscription ?? this.isMonthlySubscription,
      selectedAmountUsdCents: selectedAmountUsdCents ?? this.selectedAmountUsdCents,
      selectedAmountCdf: selectedAmountCdf ?? this.selectedAmountCdf,
      coverFees: coverFees ?? this.coverFees,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      donorPhoneNumber: donorPhoneNumber ?? this.donorPhoneNumber,
      isProcessing: isProcessing ?? this.isProcessing,
      ussdRemainingSeconds: ussdRemainingSeconds ?? this.ussdRemainingSeconds,
      completedDonation: completedDonation ?? this.completedDonation,
      errorMessage: errorMessage,
    );
  }
}

class DonationFlowNotifier extends StateNotifier<DonationFlowState> {
  DonationFlowNotifier() : super(DonationFlowState());

  void setCampaign(Campaign campaign) {
    state = state.copyWith(selectedCampaign: campaign);
  }

  void setFrequency(bool isMonthly) {
    state = state.copyWith(isMonthlySubscription: isMonthly);
  }

  void setAmountUsdCents(int cents) {
    // 1 USD = 2800 CDF
    final cdf = (cents / 100 * 2800).round();
    state = state.copyWith(selectedAmountUsdCents: cents, selectedAmountCdf: cdf);
  }

  void setAmountCdf(int cdf) {
    final usdCents = ((cdf / 2800) * 100).round();
    state = state.copyWith(selectedAmountCdf: cdf, selectedAmountUsdCents: usdCents);
  }

  void toggleCoverFees() {
    state = state.copyWith(coverFees: !state.coverFees);
  }

  void toggleAnonymous() {
    state = state.copyWith(isAnonymous: !state.isAnonymous);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(donorPhoneNumber: phone);
  }

  void decrementUssdSecond() {
    if (state.ussdRemainingSeconds > 0) {
      state = state.copyWith(ussdRemainingSeconds: state.ussdRemainingSeconds - 1);
    }
  }

  void resetUssdTimer() {
    state = state.copyWith(ussdRemainingSeconds: 60);
  }

  Future<Donation?> finalizeDonation(String currency) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final campaign = state.selectedCampaign;
      if (campaign == null) throw Exception("No campaign selected");

      final donation = await SupabaseService.instance.recordDonation(
        campaignId: campaign.id,
        campaignTitle: campaign.title,
        amountUsdCents: state.selectedAmountUsdCents,
        amountCdf: state.selectedAmountCdf,
        currency: currency,
        feeCoveredUsdCents: state.feeUsdCents,
        feeCoveredCdf: state.feeCdf,
        isAnonymous: state.isAnonymous,
        paymentMethod: state.selectedPaymentMethod,
        phoneNumber: state.donorPhoneNumber,
      );

      state = state.copyWith(
        isProcessing: false,
        completedDonation: donation,
      );
      return donation;
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.toString());
      return null;
    }
  }
}

final donationFlowProvider = StateNotifierProvider<DonationFlowNotifier, DonationFlowState>((ref) {
  return DonationFlowNotifier();
});
