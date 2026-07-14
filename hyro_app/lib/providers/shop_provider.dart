import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/shop/models/shop_item.dart';
import 'package:hyro/models/user_profile.dart';
import 'package:isar/isar.dart';

/// Administra el catálogo de la tienda, el inventario del usuario y las compras a través de Supabase o Isar.
class ShopProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final Isar isar;

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

      if (userId == null) {
        // Inventario local y monedas
        final activeUser =
            await isar.userProfiles
                .filter()
                .isActivelyLoggedInEqualTo(true)
                .findFirst();
        if (activeUser != null) {
          ownedItemIds = activeUser.comprasLocales.toSet();
          ownedQuantities = {for (var id in activeUser.comprasLocales) id: 1};
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
        // Compra local
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
