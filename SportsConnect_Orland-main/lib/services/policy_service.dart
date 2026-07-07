import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/models/policy_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PolicyService {
  PolicyService._privateConstructor();

  static PolicyService? _instance;

  static PolicyService get instance {
    _instance ??= PolicyService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  Future<PolicyModel?> getPolicyBySlug(String slug) async {
    for (final candidate in _buildSlugCandidates(slug)) {
      final row = await _supabase
          .from(SupabaseTables.policyTable)
          .select('id, slug, title, content, created_at, updated_at')
          .eq('slug', candidate)
          .limit(1)
          .maybeSingle();

      if (row != null) {
        return PolicyModel.fromJson(row);
      }
    }

    if (_isPrivacySlug(slug)) {
      return _getLatestPrivacyPolicyFallback();
    }

    return null;
  }

  List<String> _buildSlugCandidates(String slug) {
    final normalized = slug.trim().toLowerCase();
    final candidates = <String>{normalized};

    if (normalized.contains('_')) {
      candidates.add(normalized.replaceAll('_', '-'));
    }

    if (normalized.contains('-')) {
      candidates.add(normalized.replaceAll('-', '_'));
    }

    if (_isPrivacySlug(normalized)) {
      candidates.addAll(const ['privacy_policy', 'privacy-policy', 'privacy']);
    }

    return candidates.toList();
  }

  bool _isPrivacySlug(String slug) {
    return slug.toLowerCase().contains('privacy');
  }

  Future<PolicyModel?> _getLatestPrivacyPolicyFallback() async {
    final response = await _supabase
        .from(SupabaseTables.policyTable)
        .select('id, slug, title, content, created_at, updated_at')
        .order('updated_at', ascending: false)
        .limit(25);

    for (final item in (response as List)) {
      final row = item as Map<String, dynamic>;
      final rowSlug = (row['slug'] as String? ?? '').toLowerCase();
      final rowTitle = (row['title'] as String? ?? '').toLowerCase();

      if (rowSlug.contains('privacy') || rowTitle.contains('privacy')) {
        return PolicyModel.fromJson(row);
      }
    }

    return null;
  }
}
