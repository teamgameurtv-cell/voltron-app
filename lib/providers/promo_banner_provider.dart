import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promo_banner.dart';
import 'auth_provider.dart';

final promoBannerProvider = StreamProvider<PromoBanner?>((ref) {
  return ref
      .watch(supabaseProvider)
      .from('promo_banner')
      .stream(primaryKey: ['id'])
      .map((rows) => rows.isEmpty ? null : PromoBanner.fromMap(rows.first));
});

class PromoBannerActions {
  final SupabaseClient _client;

  PromoBannerActions(this._client);

  Future<void> update({
    required String title,
    required String subtitle,
    required String ctaLabel,
    required String ctaRoute,
    required bool active,
  }) async {
    await _client.from('promo_banner').update({
      'title': title,
      'subtitle': subtitle,
      'cta_label': ctaLabel,
      'cta_route': ctaRoute,
      'active': active,
    }).eq('id', true);
  }
}

final promoBannerActionsProvider = Provider<PromoBannerActions>(
  (ref) => PromoBannerActions(ref.watch(supabaseProvider)),
);
