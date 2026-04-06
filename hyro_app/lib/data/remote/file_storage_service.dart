import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

/// Handles uploading local files to and downloading files from
/// the Supabase Storage bucket `task_documents`.
class FileStorageService {
  final SupabaseClient _client;
  static const String _bucket = 'task_documents';

  FileStorageService(this._client);

  /// Uploads a local file to the Supabase `task_documents` bucket.
  ///
  /// Returns the public URL of the uploaded file.
  /// Files are stored under `{userId}/{fileId}{extension}`.
  Future<String> uploadFile({
    required String localPath,
    required String userId,
    required String fileId,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Archivo no encontrado: $localPath');
    }

    final extension = p.extension(localPath); // e.g. .pdf
    final remotePath = '$userId/$fileId$extension';

    debugPrint('📤 Uploading file: $localPath → $remotePath');

    await _client.storage.from(_bucket).upload(
          remotePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from(_bucket).getPublicUrl(remotePath);
    debugPrint('✅ File uploaded: $publicUrl');
    return publicUrl;
  }

  /// Downloads a file from Supabase Storage to local storage.
  /// Used when syncing data TO a new device (future use).
  Future<String> downloadFile({
    required String remotePath,
    required String localDir,
    required String fileName,
  }) async {
    final bytes = await _client.storage.from(_bucket).download(remotePath);

    final localFile = File(p.join(localDir, fileName));
    await localFile.create(recursive: true);
    await localFile.writeAsBytes(bytes);

    debugPrint('📥 File downloaded: ${localFile.path}');
    return localFile.path;
  }
}
