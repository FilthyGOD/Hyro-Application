/// Helper para extracción y normalización de contenido de estudio (Flashcards y Notas).
/// Filtra por etiquetas preferidas (Concepto, Examen, Pregunta) y elimina tags de formato como [{TAG:...}] y [{TITLE}]...[{/TITLE}].
class ParsedStudyNote {
  final String id;
  final String? tag;
  final String? title;
  final String body;

  const ParsedStudyNote({
    required this.id,
    this.tag,
    this.title,
    required this.body,
  });
}

class QuizContentHelper {
  QuizContentHelper._();

  /// Parsea una nota extrayendo etiqueta, título y cuerpo limpio de texto.
  static ParsedStudyNote parseNote({required String id, required String rawContent}) {
    String text = rawContent.trim();
    String? tag;
    String? title;

    // 1. Extraer [{TAG:...}]
    final tagMatch = RegExp(r'^\[\{TAG:\s*([^}\]]+)\}\]\s*', caseSensitive: false).firstMatch(text);
    if (tagMatch != null) {
      tag = tagMatch.group(1)?.trim();
      text = text.substring(tagMatch.end).trim();
    }

    // 2. Extraer [{TITLE}]...[{/TITLE}]
    final titleMatch = RegExp(r'^\[\{TITLE\}\](.*?)\[\{/TITLE\}\]\s*', caseSensitive: false, dotAll: true).firstMatch(text);
    if (titleMatch != null) {
      title = titleMatch.group(1)?.trim();
      text = text.substring(titleMatch.end).trim();
    }

    // 3. Limpiar cualquier tag residual en el cuerpo
    text = text
        .replaceAll(RegExp(r'\[\{TAG:[^}\]]*\}\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[\{/?TITLE\}\]', caseSensitive: false), '')
        .trim();

    return ParsedStudyNote(
      id: id,
      tag: tag,
      title: (title != null && title.isNotEmpty) ? title : null,
      body: text,
    );
  }

  /// Verifica si la etiqueta de la nota corresponde a Pregunta, Examen o Concepto
  static bool isPreferredTag(String? tag) {
    if (tag == null) return false;
    final t = tag.toLowerCase();
    return t.contains('concepto') || t.contains('examen') || t.contains('pregunta');
  }

  /// Limpia y normaliza un token para comparación (minúsculas, sin tildes ni signos)
  static String normalizeToken(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[^a-z0-9ñ]'), '');
    return s;
  }

  /// Verifica si una palabra es candidata válida para ocultar (palabra real de 4 a 16 letras, no fórmulas ni signos)
  static bool isEligibleWord(String raw) {
    final clean = raw.replaceAll(RegExp(r'[.,;!?:¿¡()"\[\]{}|\\/\-]'), '');
    if (clean.length < 4 || clean.length > 16) return false;
    // Debe contener únicamente letras en español
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+$').hasMatch(clean)) return false;
    // Evitar palabras de sintaxis matemática o markdown
    final lower = clean.toLowerCase();
    if (lower == 'true' || lower == 'false' || lower == 'null' || lower == 'bits' || lower == 'host') {
      return false;
    }
    return true;
  }

  /// Extrae la palabra limpia de puntuación
  static String cleanWord(String raw) {
    return raw.replaceAll(RegExp(r'[.,;!?:¿¡()"\[\]{}|\\/\-]'), '').trim();
  }
}

