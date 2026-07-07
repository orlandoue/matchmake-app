import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/models/faq_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for FAQ-related operations
class FaqService {
  FaqService._privateConstructor();

  static FaqService? _instance;

  static FaqService get instance {
    _instance ??= FaqService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Fetch all active FAQs from the database
  Future<List<FaqModel>> getActiveFaqs() async {
    final response = await _supabase
        .from(SupabaseTables.faqsTable)
        .select('id, question, answer, created_at, updated_at')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FaqModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
