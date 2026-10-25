import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final UserRole activeRole;
  final bool isLoading;

  AuthState({
    required this.isAuthenticated,
    this.user,
    required this.activeRole,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserProfile? user,
    UserRole? activeRole,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      activeRole: activeRole ?? this.activeRole,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(
          AuthState(
            isAuthenticated: false, // Default to unauthenticated so user starts at welcome screen
            activeRole: UserRole.donor,
            user: null,
          ),
        ) {
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    try {
      final client = SupabaseService.instance.client;
      final session = client?.auth.currentSession;
      if (session != null) {
        final email = session.user.email;
        final phone = session.user.phone ?? '';
        final metadataRole = session.user.userMetadata?['role'] as String?;
        final name = session.user.userMetadata?['full_name'] as String? ?? 
            (email != null ? email.split('@').first : 'CongoActions User');

        UserRole resolvedRole = metadataRole != null
            ? UserRole.fromString(metadataRole)
            : UserRole.donor;

        // Attempt to fetch actual role from profiles table
        try {
          final profileRes = await client
              ?.from('profiles')
              .select('role, full_name, preferred_currency')
              .eq('id', session.user.id)
              .maybeSingle();

          if (profileRes != null && profileRes['role'] != null) {
            resolvedRole = UserRole.fromString(profileRes['role'] as String);
          }
        } catch (_) {}

        state = state.copyWith(
          isAuthenticated: true,
          activeRole: resolvedRole,
          user: UserProfile(
            id: session.user.id,
            email: email,
            phoneNumber: phone,
            fullName: name,
            role: resolvedRole,
            preferredCurrency: 'USD',
          ),
        );
      }
    } catch (_) {}
  }

  void loginWithEmail({
    required String id,
    required String email,
    String? fullName,
    UserRole? role,
  }) {
    final effectiveRole = role ?? state.activeRole;
    state = state.copyWith(
      isAuthenticated: true,
      activeRole: effectiveRole,
      user: UserProfile(
        id: id,
        email: email,
        phoneNumber: '',
        fullName: fullName ?? (email.split('@').first),
        role: effectiveRole,
        preferredCurrency: 'USD',
      ),
    );
  }

  void switchRole(UserRole newRole) {
    state = state.copyWith(activeRole: newRole);
  }

  void setUser(UserProfile user) {
    state = state.copyWith(
      isAuthenticated: true,
      user: user,
    );
  }

  void loginWithPhone(String phone, String code, {String? fullName}) {
    state = state.copyWith(
      isAuthenticated: true,
      user: UserProfile(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: phone,
        fullName: fullName ?? 'Junior Lutula',
        role: state.activeRole,
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        preferredCurrency: 'USD',
      ),
    );
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.instance.client?.auth.signOut();
    } catch (_) {}
    state = AuthState(
      isAuthenticated: false,
      user: null,
      activeRole: UserRole.donor,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
