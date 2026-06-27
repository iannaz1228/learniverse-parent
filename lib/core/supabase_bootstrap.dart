import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

Future<SupabaseClient?> initSupabaseOrNull() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.publishableKey,
    );
    return Supabase.instance.client;
  } catch (e) {
    debugPrint('Supabase init failed: $e');
    return null;
  }
}
