import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final campaignsProvider = StateProvider<List<Campaign>>((ref) {
  return SupabaseService.instance.campaigns;
});

final filteredCampaignsProvider = Provider<List<Campaign>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final allCampaigns = ref.watch(campaignsProvider);

  if (category == 'All') return allCampaigns;
  return allCampaigns.where((c) => c.category.toLowerCase() == category.toLowerCase()).toList();
});

final subscriptionsProvider = StateProvider<List<Subscription>>((ref) {
  return SupabaseService.instance.subscriptions;
});

final kycDocumentsProvider = StateProvider<List<KYCDocument>>((ref) {
  return SupabaseService.instance.kycDocuments;
});

final payoutsProvider = StateProvider<List<PayoutRequest>>((ref) {
  return SupabaseService.instance.payouts;
});

// Refresh triggers
void refreshAllData(WidgetRef ref) {
  ref.read(campaignsProvider.notifier).state = [...SupabaseService.instance.campaigns];
  ref.read(subscriptionsProvider.notifier).state = [...SupabaseService.instance.subscriptions];
  ref.read(kycDocumentsProvider.notifier).state = [...SupabaseService.instance.kycDocuments];
  ref.read(payoutsProvider.notifier).state = [...SupabaseService.instance.payouts];
}
