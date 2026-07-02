import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

/// Maneja la subida de archivos locales y descarga de archivos desde
/// el bucket de Supabase Storage `task_documents`.
class FileStorageService {
  final SupabaseClient _client;
  static const String _bucket = 'task_documents';

  FileStorageService(this._client);

  /// Sube un archivo local al bucket `task_documents` de Supabase.
  ///
  /// Devuelve la URL p\u00fablica del archivo subido.
  /// Los archivos se almacenan bajo `{userId}/{fileId}{extension}`.
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

  /// Descarga un archivo de Supabase Storage al almacenamiento local.
  /// Usado al sincronizar datos A un nuevo dispositivo (uso futuro).
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
