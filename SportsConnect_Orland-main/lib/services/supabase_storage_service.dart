import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generic Supabase Storage Service
/// Can be reused in any project for file upload/download operations
class SupabaseStorageService {
  final _supabaseService = Supabase.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// Upload file to storage
  /// [bucketName] - Name of the storage bucket
  /// [filePath] - Path within the bucket (e.g., 'folder/filename.jpg')
  /// [file] - File to upload
  /// [fileOptions] - Optional file options (contentType, cacheControl, etc.)
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required String bucketName,
    required String filePath,
    required File file,
    FileOptions? fileOptions,
  }) async {
    try {
      // Upload file to Supabase Storage
      await _client.storage.from(bucketName).upload(
            filePath,
            file,
            fileOptions: fileOptions ??
                FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
          );

      // Get public URL
      final publicUrl = _client.storage.from(bucketName).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload file with auto-generated unique name
  /// [bucketName] - Name of the storage bucket
  /// [folder] - Folder path within the bucket
  /// [file] - File to upload
  /// [extension] - File extension (e.g., 'jpg', 'png')
  /// Returns the public URL of the uploaded file
  Future<String> uploadFileWithUniqueId({
    required String bucketName,
    required String folder,
    required File file,
    required String extension,
    FileOptions? fileOptions,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = '${timestamp}_${file.hashCode}';
      final fileName = '$uniqueId.$extension';
      final filePath = '$folder/$fileName';

      return await uploadFile(
        bucketName: bucketName,
        filePath: filePath,
        file: file,
        fileOptions: fileOptions,
      );
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Delete file from storage
  /// [bucketName] - Name of the storage bucket
  /// [filePath] - Path of the file to delete
  Future<void> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      await _client.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Delete multiple files from storage
  /// [bucketName] - Name of the storage bucket
  /// [filePaths] - List of file paths to delete
  Future<void> deleteFiles({
    required String bucketName,
    required List<String> filePaths,
  }) async {
    try {
      await _client.storage.from(bucketName).remove(filePaths);
    } catch (e) {
      throw Exception('Failed to delete files: ${e.toString()}');
    }
  }

  /// Get public URL for a file
  /// [bucketName] - Name of the storage bucket
  /// [filePath] - Path of the file
  String getPublicUrl({
    required String bucketName,
    required String filePath,
  }) {
    return _client.storage.from(bucketName).getPublicUrl(filePath);
  }

  /// Download file from storage
  /// [bucketName] - Name of the storage bucket
  /// [filePath] - Path of the file to download
  /// Returns file data as bytes
  Future<Uint8List> downloadFile({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      final data = await _client.storage.from(bucketName).download(filePath);
      return data;
    } catch (e) {
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  /// List files in a folder
  /// [bucketName] - Name of the storage bucket
  /// [path] - Folder path to list files from
  /// [searchQuery] - Optional search query
  /// [limit] - Maximum number of files to return
  /// [offset] - Number of files to skip
  Future<List<FileObject>> listFiles({
    required String bucketName,
    String? path,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      List<FileObject> files;
      if (searchQuery != null) {
        files = await _client.storage.from(bucketName).list(
              path: path,
              searchOptions: SearchOptions(
                search: searchQuery,
                limit: limit,
                offset: offset,
              ),
            );
      } else {
        files = await _client.storage.from(bucketName).list(
              path: path,
            );
      }
      return files;
    } catch (e) {
      throw Exception('Failed to list files: ${e.toString()}');
    }
  }

  /// Move/Rename a file
  /// [bucketName] - Name of the storage bucket
  /// [fromPath] - Current file path
  /// [toPath] - New file path
  Future<void> moveFile({
    required String bucketName,
    required String fromPath,
    required String toPath,
  }) async {
    try {
      await _client.storage.from(bucketName).move(fromPath, toPath);
    } catch (e) {
      throw Exception('Failed to move file: ${e.toString()}');
    }
  }

  /// Copy a file
  /// [bucketName] - Name of the storage bucket
  /// [fromPath] - Source file path
  /// [toPath] - Destination file path
  Future<void> copyFile({
    required String bucketName,
    required String fromPath,
    required String toPath,
  }) async {
    try {
      await _client.storage.from(bucketName).copy(fromPath, toPath);
    } catch (e) {
      throw Exception('Failed to copy file: ${e.toString()}');
    }
  }

  /// Extract file path from public URL
  /// [publicUrl] - The public URL of the file
  /// [bucketName] - Name of the storage bucket
  /// Returns the file path within the bucket
  String extractFilePathFromUrl(String publicUrl, String bucketName) {
    final baseUrl = '/storage/v1/object/public/$bucketName/';
    if (publicUrl.contains(baseUrl)) {
      return publicUrl.split(baseUrl).last;
    }
    return '';
  }
}
