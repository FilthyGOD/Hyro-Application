import 'package:flutter/material.dart';

/// Stub de FileStorageService para web — la subida/descarga de archivos locales
/// no aplica en el navegador.
class FileStorageService {
  FileStorageService(dynamic client);

  Future<String> uploadFile({
    required String localPath,
    required String userId,
    required String fileId,
  }) async {
    debugPrint('⚠️ FileStorageService.uploadFile no disponible en web');
    return localPath; // devolver la ruta tal cual
  }

  Future<String> downloadFile({
    required String remotePath,
    required String localDir,
    required String fileName,
  }) async {
    debugPrint('⚠️ FileStorageService.downloadFile no disponible en web');
    return '';
  }
}
