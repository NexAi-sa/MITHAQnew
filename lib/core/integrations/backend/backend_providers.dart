import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_client.dart';
import 'supabase_backend_client.dart';

/// Provider for the Backend Client.
/// Automatically switches between Real and Mock based on feature flags.
final backendClientProvider = Provider<BackendClient>((ref) {
  return SupabaseBackendClient(Supabase.instance.client);
});
