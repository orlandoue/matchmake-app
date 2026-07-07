import 'dart:io';

import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/models/identity_verification_model.dart';
import 'package:orland_sports/services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for identity verification operations
class IdentityVerificationService {
  IdentityVerificationService._privateConstructor();

  static IdentityVerificationService? _instance;

  static IdentityVerificationService get instance {
    _instance ??= IdentityVerificationService._privateConstructor();
    return _instance!;
  }

  final _storageService = SupabaseStorageService();
  final _supabase = Supabase.instance.client;

  static const String storageBucket = 'publicbucket';

  /// Upload identity document image and return public URL
  Future<String?> uploadIdentityImage({
    required String userId,
    required File imageFile,
    required String imageType, // 'front', 'back', or 'selfie'
  }) async {
    try {
      final extension = imageFile.path.split('.').last;
      final fileName =
          '${userId}_${imageType}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = 'identity_documents/$fileName';

      final publicUrl = await _storageService.uploadFile(
        bucketName: storageBucket,
        filePath: filePath,
        file: imageFile,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      return publicUrl;
    } catch (e) {
      print('Error uploading identity image: $e');
      return null;
    }
  }

  /// Submit identity verification to the separate table
  Future<bool> submitVerification({
    required String userId,
    required String documentType,
    required String frontUrl,
    required String backUrl,
    required String selfieUrl,
  }) async {
    try {
      final model = IdentityVerificationModel(
        userId: userId,
        documentType: documentType,
        frontImageUrl: frontUrl,
        backImageUrl: backUrl,
        selfieUrl: selfieUrl,
        status: 'pending',
      );

      await _supabase
          .from(SupabaseTables.identityVerificationsTable)
          .insert(model.toJson());

      return true;
    } catch (e) {
      print('Error submitting identity verification: $e');
      return false;
    }
  }

  /// Get the latest verification record for a user
  Future<IdentityVerificationModel?> getVerification(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.identityVerificationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return IdentityVerificationModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting identity verification: $e');
      return null;
    }
  }
}
