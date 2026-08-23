import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop_item.dart';
import 'package:hyro/data/models/user_profile.dart';

/// Administra el catálogo de la tienda, el inventario del usuario y las compras a través de Supabase o Isar.
class ShopProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final dynamic isar; // Isar en nativo, null en web

  ShopProvider(this.isar);

  List<ShopItem> catalog = [];
  Set<int> ownedItemIds = {};
  Map<int, int> ownedQuantities = {};
  bool isLoading = false;
  String? error;

  // ─── Cargar Catálogo e Inventario ──────────────────────────────────────────

  static const List<ShopItem> _defaultCatalog = [
    ShopItem(
      id: 101,
      nombre: 'Sombrero de Copa',
      categoria: 'Sombrero',
      precio: 1,
    ),
    ShopItem(
      id: 102,
      nombre: 'Sombrero Vaquero',
      categoria: 'Sombrero',
      precio: 1,
    ),
    ShopItem(
      id: 103,
      nombre: 'Sombrero Payaso',
      categoria: 'Sombrero',
      precio: 1,
    ),
    ShopItem(id: 201, nombre: 'Monóculo', categoria: 'Cara', precio: 1),
    ShopItem(id: 202, nombre: 'Gafas de Sol', categoria: 'Cara', precio: 1),
    ShopItem(id: 203, nombre: 'Nariz de Payaso', categoria: 'Cara', precio: 1),
    ShopItem(id: 301, nombre: 'Smoking', categoria: 'Traje', precio: 1),
    ShopItem(id: 302, nombre: 'Poncho', categoria: 'Traje', precio: 1),
    ShopItem(id: 303, nombre: 'Traje Payaso', categoria: 'Traje', precio: 1),
  ];

  /// Obtiene el catálogo completo de la tienda y los artículos propiedad del usuario.
  Future<void> loadShop(String? userId) async {
    isLoading = true;
    error = null;
    Future.microtask(() => notifyListeners());

    try {
      try {
        // 1. Cargar catálogo desde Supabase
        final catalogData =
            await _supabase
                    .from('objetos_tienda')
                    .select('id, nombre, categoria, precio')
                    .order('id')
                as List<dynamic>;

        if (catalogData.isEmpty) {
          throw Exception(
            'Catálogo vacío (posible bloqueo de RLS o sin conexión)',
          );
        }

        catalog =
            catalogData
                .map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e)))
                .toList();
      } catch (e) {
        debugPrint('Usando catálogo local por error de BD: $e');
        catalog = List.from(_defaultCatalog);
      }

      // ─── Sobreescribir precios de consumibles (Local Override) ───
      for (int i = 0; i < catalog.length; i++) {
        final item = catalog[i];
        if (item.id == 401) {
          catalog[i] = ShopItem(
            id: item.id,
            nombre: item.nombre,
            categoria: item.categoria,
            precio: 50, // Protector de racha -> 50
          );
        } else if (item.nombre.contains('3 lecciones')) {
          catalog[i] = ShopItem(
            id: item.id,
            nombre: item.nombre,
            categoria: item.categoria,
            precio: 40, // x2 xp por 3 lecciones -> 40
          );
        } else if (item.nombre.contains('6 lecciones')) {
          catalog[i] = ShopItem(
            id: item.id,
            nombre: item.nombre,
            categoria: item.categoria,
            precio: 70, // x2 xp por 6 lecciones -> 70
          );
        }
      }

      if (userId == null) {
        // Inventario local y monedas (solo nativo con Isar)
        if (!kIsWeb && isar != null) {
          final activeUser =
              await isar.userProfiles
                  .filter()
                  .isActivelyLoggedInEqualTo(true)
                  .findFirst();
          if (activeUser != null) {
            ownedItemIds = activeUser.comprasLocales.toSet();
            ownedQuantities = {for (var id in activeUser.comprasLocales) id: 1};
          }
        }
      } else {
        // Inventario en la nube
        final inventoryData =
            await _supabase
                    .from('inventario_usuarios')
                    .select('objeto_id, cantidad')
                    .eq('usuario_id', userId)
                as List<dynamic>;

        ownedItemIds =
            inventoryData.map((e) => (e['objeto_id'] as num).toInt()).toSet();
        ownedQuantities = {
          for (var e in inventoryData)
            (e['objeto_id'] as num).toInt(): (e['cantidad'] as num?)?.toInt() ?? 1
        };
      }
    } catch (e) {
      error = 'Error cargando tienda: $e';
      debugPrint(error);
    } finally {
      isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  // ─── Compra ──────────────────────────────────────────────────────────────

  /// Intenta comprar un artículo.
  Future<bool> purchaseItem(String? userId, int itemId) async {
    final item = catalog.firstWhere(
      (i) => i.id == itemId,
      orElse: () => _defaultCatalog.firstWhere((i) => i.id == itemId),
    );
    final isStackable = item.categoria.toLowerCase() == 'objeto' || itemId >= 400;

    // Verificación previa local
    if (!isStackable && ownedItemIds.contains(itemId)) {
      error = 'Ya posees este objeto';
      notifyListeners();
      return false;
    }

    try {
      if (userId == null) {
        if (kIsWeb || isar == null) {
          error = 'Inicia sesión para comprar objetos';
          notifyListeners();
          return false;
        }
        // Compra local (solo nativo)
        final item = catalog.firstWhere((i) => i.id == itemId);
        final activeUser =
            await isar.userProfiles
                .filter()
                .isActivelyLoggedInEqualTo(true)
                .findFirst();

        if (activeUser == null) {
          throw Exception("No user found");
        }

        if (activeUser.monedas < item.precio) {
          error = 'No tienes suficientes monedas';
          notifyListeners();
          return false;
        }

        await isar.writeTxn(() async {
          activeUser.monedas -= item.precio;
          activeUser.comprasLocales = [...activeUser.comprasLocales, itemId];
          await isar.userProfiles.put(activeUser);
        });

        ownedItemIds.add(itemId);
        error = null;
        notifyListeners();
        return true;
      } else {
        await _supabase.rpc(
          'comprar_objeto',
          params: {'p_usuario_id': userId, 'p_objeto_id': itemId},
        );

        ownedItemIds.add(itemId);
        error = null;
        notifyListeners();
        return true;
      }
    } on PostgrestException catch (e) {
      error = _friendlyError(e.message);
      debugPrint('Error en la compra: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Error de red al comprar: $e';
      debugPrint(error);
      notifyListeners();
      return false;
    }
  }

  // ─── Funciones Auxiliares ──────────────────────────────────────────

  /// Comprueba si el usuario posee un artículo dado.
  bool ownsItem(int itemId) => ownedItemIds.contains(itemId);

  /// Obtiene los artículos del catálogo filtrados por palabra clave de categoría.
  List<ShopItem> itemsByCategory(String category) =>
      catalog
          .where(
            (item) =>
                item.categoria.toLowerCase().contains(category.toLowerCase()),
          )
          .toList();

  /// Traduce las excepciones de Postgres a mensajes fáciles de entender por el usuario.
  String _friendlyError(String pgMsg) {
    if (pgMsg.contains('Monedas insuficientes')) {
      return 'No tienes suficientes monedas';
    }
    if (pgMsg.contains('Ya posees')) return 'Ya tienes este objeto';
    if (pgMsg.contains('Objeto no encontrado')) return 'Este objeto no existe';
    return 'Error al procesar la compra';
  }
}
