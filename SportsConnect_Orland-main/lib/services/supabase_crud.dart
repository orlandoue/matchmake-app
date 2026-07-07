import 'dart:async';

import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Note: we intentionally avoid importing gotrue types directly to keep
// this helper resilient to package internal types. We'll match by message.

class SupabaseDatabaseService {
  // Private constructor
  SupabaseDatabaseService._privateConstructor();

  // Singleton instance variable
  static SupabaseDatabaseService? _instance;

  // Getter to access the singleton instance
  static SupabaseDatabaseService get instance {
    _instance ??= SupabaseDatabaseService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Handle auth-related errors (like invalid refresh token) centrally.
  /// Returns true if the error was an auth error that we handled (and caller
  /// should return early).
  bool _handleAuthError(Object e) {
    final msg = e.toString();
    if (msg.contains('refresh_token_not_found') ||
        msg.contains('Invalid Refresh Token')) {
      print('🔐 SUPABASE_CRUD - Invalid refresh token detected. Signing out.');
      try {
        // CustomToast.instance.showFailureToast(
        //   title: 'Session Expired',
        //   message: 'Your session has expired. Please sign in again.',
        // );
      } catch (_) {}

      try {
        // Best-effort sign out to clear local session
        _supabase.auth.signOut();
      } catch (_) {}

      return true;
    }
    return false;
  }

  /// Create a new row in table
  Future<bool> createRow({
    required String tableName,
    required dynamic rowId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // If rowId is provided, use it as the primary key
      final insertData = {...data};
      if (rowId.toString().isNotEmpty) {
        insertData['id'] = rowId;
        print('🔍 CRUD DEBUG - Adding rowId to insertData: $rowId');
      } else {
        print('🔍 CRUD DEBUG - Empty rowId, letting database generate UUID');
      }

      print('🔍 CRUD DEBUG - Final insertData: $insertData');
      await _supabase.from(tableName).insert(insertData);
      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      print('ERROR MSG CREATING ROW : ${errorMessage} , ${e}');
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception while creating row in Supabase: $e");
      return false;
    }
  }

  /// Read single row by ID
  Future<Map<String, dynamic>?> readSingleRow({
    required String tableName,
    required var rowId,
  }) async {
    try {
      // Add timestamp to prevent caching (if using query parameters)
      final response =
          await _supabase.from(tableName).select().eq('id', rowId).single();

      print(
          '🔍 CRUD readSingleRow - Response for $tableName/$rowId: $response');
      return response as Map<String, dynamic>?;
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST116') {
        // Ignore "No rows found" error
        final errorMessage = _getSupabaseErrorMessage(e);
        CustomToast.instance
            .showFailureToast(title: "Error", message: errorMessage);
      }
      return null;
    } catch (e) {
      if (_handleAuthError(e)) return null;
      print("Exception while reading row from Supabase: $e");
      return null;
    }
  }

  /// Read single row by field value
  Future<Map<String, dynamic>?> readSingleRowByField({
    required String tableName,
    required String fieldName,
    required dynamic fieldValue,
  }) async {
    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .eq(fieldName, fieldValue)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return null;
    } catch (e) {
      if (_handleAuthError(e)) return null;
      print("Exception while reading row from Supabase: $e");
      return null;
    }
  }

  /// Read multiple rows by field value
  Future<List<Map<String, dynamic>>?> readRowsByField({
    required String tableName,
    required String fieldName,
    required dynamic fieldValue,
  }) async {
    try {
      final response =
          await _supabase.from(tableName).select().eq(fieldName, fieldValue);

      return response as List<Map<String, dynamic>>?;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return null;
    } catch (e) {
      if (_handleAuthError(e)) return null;
      print("Exception while reading rows from Supabase: $e");
      return null;
    }
  }

  /// Read all rows from table
  Future<List<Map<String, dynamic>>?> readAllRows({
    required String tableName,
  }) async {
    try {
      final response = await _supabase.from(tableName).select();
      return response as List<Map<String, dynamic>>?;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return null;
    } catch (e) {
      if (_handleAuthError(e)) return null;
      print("Exception while reading all rows from Supabase: $e");
      return null;
    }
  }

  /// Stream changes to a single row
  Stream<Map<String, dynamic>?> streamSingleRow({
    required String tableName,
    required String rowId,
  }) {
    return _supabase
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('id', rowId)
        .map((data) => data.isNotEmpty ? data[0] : null);
  }

  /// Check if row exists by ID
  Future<bool> rowExists({
    required String tableName,
    required String rowId,
  }) async {
    try {
      final response = await _supabase
          .from(tableName)
          .select('id')
          .eq('id', rowId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception while checking row existence in Supabase: $e");
      return false;
    }
  }

  /// Check if rows exist by field value
  Future<(bool, List<Map<String, dynamic>>?)> rowsExistByField({
    required String tableName,
    required String fieldName,
    required dynamic fieldValue,
  }) async {
    try {
      final response =
          await _supabase.from(tableName).select().eq(fieldName, fieldValue);

      final data = response as List<Map<String, dynamic>>?;
      return (data?.isNotEmpty ?? false, data);
    } catch (e) {
      if (_handleAuthError(e)) return (false, null);
      print("Exception while checking row existence in Supabase: $e");
      return (false, null);
    }
  }

  /// Update row
  Future<bool> updateRow({
    required String tableName,
    required dynamic rowId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase.from(tableName).update(data).eq('id', rowId).select();
      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      print('ON UPDATEING ROW ERROR : ${errorMessage}');
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception while updating row in Supabase: $e");
      return false;
    }
  }

  /// Update single field in row
  Future<bool> updateRowField({
    required String tableName,
    required String rowId,
    required String fieldName,
    required dynamic fieldValue,
  }) async {
    try {
      await _supabase
          .from(tableName)
          .update({fieldName: fieldValue}).eq('id', rowId);
      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception while updating row field in Supabase: $e");
      return false;
    }
  }

  /// Update multiple rows by a specific field
  Future<bool> updateMultipleRowsByField({
    required String tableName,
    required String fieldName, // Field you want to match
    required dynamic fieldValue, // Value you want to match
    required Map<String, dynamic> dataToUpdate, // New data you want to set
  }) async {
    try {
      await _supabase
          .from(tableName)
          .update(dataToUpdate)
          .eq(fieldName, fieldValue);
      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      print('ON UPDATING MULTIPLE ROWS ERROR: $errorMessage');
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception while updating multiple rows in Supabase: $e");
      return false;
    }
  }

  /// Delete row
  Future<bool> deleteRow({
    required String tableName,
    required String rowId,
  }) async {
    try {
      await _supabase.from(tableName).delete().eq('id', rowId);
      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception while deleting row from Supabase: $e");
      return false;
    }
  }

  /// Stream all rows from table
  Stream<List<Map<String, dynamic>>> streamAllRows({
    required String tableName,
  }) {
    return _supabase.from(tableName).stream(primaryKey: ['id']);
  }

  /// Batch insert multiple rows
  Future<bool> batchInsertRows({
    required List<Map<String, dynamic>> rows,
    required List<String> rowIds,
    required String tableName,
  }) async {
    if (rows.length != rowIds.length) {
      print("The lengths of rows and rowIds lists should be the same!");
      return false;
    }

    try {
      // Prepare data with IDs
      final dataWithIds = rows
          .asMap()
          .map((index, row) {
            return MapEntry(index, {...row, 'id': rowIds[index]});
          })
          .values
          .toList();

      await _supabase.from(tableName).insert(dataWithIds);
      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception while batch inserting rows in Supabase: $e");
      return false;
    }
  }

  /// Adds a value to an array column if it doesn't already exist
  Future<bool> arrayUnion({
    required String tableName,
    required String rowId,
    required String columnName,
    required dynamic value,
  }) async {
    try {
      // First get the current array
      final response =
          await _supabase.from(tableName).select().eq('id', rowId).single();

      final currentArray = List.from(response[columnName] ?? []);

      if (currentArray.contains(value)) {
        return true; // Already exists
      }

      // Create new array with the added value
      final newArray = [...currentArray, value];

      // Update the row with the new array
      await _supabase
          .from(tableName)
          .update({columnName: newArray}).eq('id', rowId);

      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception in arrayUnion: $e");
      return false;
    }
  }

  /// Removes a value from an array column
  Future<bool> arrayRemove({
    required String tableName,
    required String rowId,
    required String columnName,
    required dynamic value,
  }) async {
    try {
      // First get the current array
      final response =
          await _supabase.from(tableName).select().eq('id', rowId).single();

      final currentArray = List.from(response[columnName] ?? []);

      if (!currentArray.contains(value)) {
        return true; // Doesn't exist
      }

      // Create new array without the value
      final newArray = currentArray.where((item) => item != value).toList();

      // Update the row with the new array
      await _supabase
          .from(tableName)
          .update({columnName: newArray}).eq('id', rowId);

      return true;
    } on PostgrestException catch (e) {
      final errorMessage = _getSupabaseErrorMessage(e);
      CustomToast.instance
          .showFailureToast(title: "Error", message: errorMessage);
      return false;
    } catch (e) {
      if (_handleAuthError(e)) return false;
      print("Exception in arrayRemove: $e");
      return false;
    }
  }

  /// Method to get a user-friendly message from PostgrestException
  String _getSupabaseErrorMessage(PostgrestException e) {
    switch (e.code) {
      case '23505':
        return 'This item already exists.';
      case '42501':
        return 'You do not have permission to execute this operation.';
      case 'PGRST116':
        return 'Requested item was not found.';
      case 'PGRST100':
        return 'Invalid data provided.';
      case 'PGRST201':
        return 'The operation was cancelled.';
      case 'PGRST204':
        return 'No data was returned.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : 'An unexpected error occurred, please try again.';
    }
  }
}
