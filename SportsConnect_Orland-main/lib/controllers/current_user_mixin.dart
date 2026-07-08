import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared resolution of the current user's id for match controllers.
///
/// Prefers the live Supabase session (works for both players and referees)
/// and falls back to [AuthController] when needed.
mixin CurrentUserMixin {
  String? get currentUserId {
    final supabaseUserId = Supabase.instance.client.auth.currentUser?.id;
    if (supabaseUserId != null) {
      return supabaseUserId;
    }

    try {
      return AuthController.instance.currentUser.value?.id;
    } catch (e) {
      return null;
    }
  }
}
