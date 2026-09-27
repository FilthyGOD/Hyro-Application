import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de logica de negocio para el cambio de nombre de usuario.
/// Solo hace UPDATE en la columna nombre_usuario — el Trigger de Supabase
/// gestiona automaticamente las colisiones de codigo_amigo.
class UsernameService {
  static final _supabase = Supabase.instance.client;

  /// Valida el formato del nombre de usuario antes de enviarlo.
  static String? validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'El nombre no puede estar vacio.';
    if (trimmed.length < 3) return 'Minimo 3 caracteres.';
    if (trimmed.length > 24) return 'Maximo 24 caracteres.';
    final validChars = RegExp(r'^[a-zA-Z0-9_\-\.]+$');
    if (!validChars.hasMatch(trimmed)) {
      return 'Solo letras, numeros, _, - y . estan permitidos.';
    }
    return null;
  }

  /// Actualiza el nombre_usuario en Supabase para el usuario dado.
  /// Retorna null en caso de exito, o el mensaje de error como String.
  static Future<String?> updateUsername({
    required String userId,
    required String newUsername,
  }) async {
    try {
      await _supabase
          .from('perfiles')
          .update({'nombre_usuario': newUsername.trim()})
          .eq('id', userId);
      debugPrint('Nombre actualizado a: ${newUsername.trim()}');
      return null;
    } on PostgrestException catch (e) {
      debugPrint('Error Postgrest al actualizar nombre: ${e.message}');
      if (e.code == '23505') {
        return 'Ese nombre ya esta en uso. Intenta con otro.';
      }
      return 'Error al guardar el nombre: ${e.message}';
    } catch (e) {
      debugPrint('Error inesperado al actualizar nombre: $e');
      return 'Error inesperado. Intenta de nuevo.';
    }
  }
}
