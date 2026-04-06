/// Result of a full sync operation.
class SyncResult {
  bool success = false;
  int categoriasSynced = 0;
  int tareasSynced = 0;
  int notasSynced = 0;
  int archivosSynced = 0;
  int cardsSynced = 0;
  List<String> errors = [];

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'SyncResult(ok: $success, cats: $categoriasSynced, tasks: $tareasSynced, '
      'notes: $notasSynced, files: $archivosSynced, cards: $cardsSynced, '
      'errors: ${errors.length})';
}
