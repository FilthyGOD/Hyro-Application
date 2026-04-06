import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Genera un UUID v4 para cualquier entidad de negocio.
/// Usar SIEMPRE este generador para IDs de tareas, categorías, notas, etc.
/// Esto garantiza que los IDs son únicos globalmente y compatibles
/// con PostgreSQL (Supabase) sin colisiones al sincronizar.
String generateId() => _uuid.v4();

/// UUID constante que identifica al usuario Guest localmente.
/// Se reemplaza por auth.uid() durante la sincronización a Supabase.
const kLocalGuestUserId = '00000000-0000-0000-0000-000000000000';
