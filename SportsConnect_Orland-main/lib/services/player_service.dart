import 'dart:io';

import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/enums/user_role.dart';
import 'package:orland_sports/models/user_model.dart';
import 'package:orland_sports/services/supabase_crud.dart';
import 'package:orland_sports/services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for player-specific operations
class PlayerService {
  // Private constructor
  PlayerService._privateConstructor();

  // Singleton instance variable
  static PlayerService? _instance;

  // Getter to access the singleton instance
  static PlayerService get instance {
    _instance ??= PlayerService._privateConstructor();
    return _instance!;
  }

  final _crudService = SupabaseDatabaseService.instance;
  final _storageService = SupabaseStorageService();
  final _supabase = Supabase.instance.client;

  /// Storage bucket name for uploads
  static const String storageBucket = 'publicbucket';

  /// Create a new player user in the database
  Future<bool> createPlayer({
    required String id,
    required String email,
    required String name,
    UserRole role = UserRole.player,
  }) async {
    try {
      final userData = {
        'id': id,
        'email': email,
        'name': name,
        'role': role.value,
        'is_profile_complete': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      return await _crudService.createRow(
        tableName: SupabaseTables.usersTable,
        rowId: id,
        data: userData,
      );
    } catch (e) {
      print('Error creating player: $e');
      return false;
    }
  }

  /// Get player by ID
  Future<UserModel?> getPlayerById(String id) async {
    try {
      final response = await _crudService.readSingleRow(
        tableName: SupabaseTables.usersTable,
        rowId: id,
      );

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting player: $e');
      return null;
    }
  }

  /// Get current logged in player
  Future<UserModel?> getCurrentPlayer() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      return await getPlayerById(user.id);
    } catch (e) {
      print('Error getting current player: $e');
      return null;
    }
  }

  /// Update player profile
  Future<bool> updatePlayerProfile({
    required String id,
    String? name,
    String? country,
    String? dateOfBirth,
    String? gender,
    String? skillLevel,
    String? favoritePosition,
    String? profileImageUrl,
    bool? isProfileComplete,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (country != null) updateData['country'] = country;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth;
      if (gender != null) updateData['gender'] = gender;
      if (skillLevel != null) updateData['skill_level'] = skillLevel;
      if (favoritePosition != null) {
        updateData['favorite_position'] = favoritePosition;
      }
      if (profileImageUrl != null) {
        updateData['profile_image_url'] =
            profileImageUrl.isEmpty ? null : profileImageUrl;
      }
      if (isProfileComplete != null) {
        updateData['is_profile_complete'] = isProfileComplete;
      }

      return await _crudService.updateRow(
        tableName: SupabaseTables.usersTable,
        rowId: id,
        data: updateData,
      );
    } catch (e) {
      print('Error updating player profile: $e');
      return false;
    }
  }

  /// Upload profile image and update user
  Future<String?> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Generate unique filename
      final extension = imageFile.path.split('.').last;
      final fileName =
          '${userId}_profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = 'profile_images/$fileName';

      // Upload to storage
      final publicUrl = await _storageService.uploadFile(
        bucketName: storageBucket,
        filePath: filePath,
        file: imageFile,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Update user profile with new image URL
      await updatePlayerProfile(
        id: userId,
        profileImageUrl: publicUrl,
      );

      return publicUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Check if player profile is complete
  Future<bool> isProfileComplete(String userId) async {
    try {
      final player = await getPlayerById(userId);
      return player?.isProfileComplete ?? false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  /// Complete player profile setup
  Future<bool> completeProfileSetup({
    required String id,
    required String country,
    required String dateOfBirth,
    required String gender,
    required String skillLevel,
    required String favoritePosition,
    String? profileImageUrl,
  }) async {
    try {
      return await updatePlayerProfile(
        id: id,
        country: country,
        dateOfBirth: dateOfBirth,
        gender: gender,
        skillLevel: skillLevel,
        favoritePosition: favoritePosition,
        profileImageUrl: profileImageUrl,
        isProfileComplete: true,
      );
    } catch (e) {
      print('Error completing profile setup: $e');
      return false;
    }
  }

  /// Delete player account
  Future<bool> deletePlayer(String id) async {
    try {
      return await _crudService.deleteRow(
        tableName: SupabaseTables.usersTable,
        rowId: id,
      );
    } catch (e) {
      print('Error deleting player: $e');
      return false;
    }
  }

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.usersTable)
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }
}
