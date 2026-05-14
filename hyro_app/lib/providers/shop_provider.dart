import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/shop/models/shop_item.dart';
import 'package:hyro/models/user_profile.dart';
import 'package:isar/isar.dart';

/// Manages the shop catalog, user inventory, and purchases via Supabase or Isar.
class ShopProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final Isar isar;

  ShopProvider(this.isar);

  List<ShopItem> catalog = [];
  Set<int> ownedItemIds = {};
  bool isLoading = false;
  String? error;

  // â”€â”€â”€ Load Catalog + Inventory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    ShopItem(id: 201, nombre: 'MonÃ³culo', categoria: 'Cara', precio: 1),
    ShopItem(id: 202, nombre: 'Gafas de Sol', categoria: 'Cara', precio: 1),
    ShopItem(id: 203, nombre: 'Nariz de Payaso', categoria: 'Cara', precio: 1),
    ShopItem(id: 301, nombre: 'Smoking', categoria: 'Traje', precio: 1),
    ShopItem(id: 302, nombre: 'Poncho', categoria: 'Traje', precio: 1),
    ShopItem(id: 303, nombre: 'Traje Payaso', categoria: 'Traje', precio: 1),
  ];

  /// Fetches the full store catalog and the user's owned items.
  Future<void> loadShop(String? userId) async {
    isLoading = true;
    error = null;
    Future.microtask(() => notifyListeners());

    try {
      try {
        // 1. Load catalog from Supabase
        final catalogData =
            await _supabase
                    .from('objetos_tienda')
                    .select('id, nombre, categoria, precio')
                    .order('id')
                as List<dynamic>;

        if (catalogData.isEmpty) {
          throw Exception(
            'CatÃ¡logo vacÃ­o (posible bloqueo de RLS o sin conexiÃ³n)',
          );
        }

        catalog =
            catalogData
                .map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e)))
                .toList();
      } catch (e) {
        debugPrint('Fallback to local catalog due to DB error: $e');
        catalog = List.from(_defaultCatalog);
      }

      if (userId == null) {
        // Local inventory and coins
        final activeUser =
            await isar.userProfiles
                .filter()
                .isActivelyLoggedInEqualTo(true)
                .findFirst();
        if (activeUser != null) {
          ownedItemIds = activeUser.comprasLocales.toSet();
        }
      } else {
        // Cloud inventory
        final inventoryData =
            await _supabase
                    .from('inventario_usuarios')
                    .select('objeto_id')
                    .eq('usuario_id', userId)
                as List<dynamic>;

        ownedItemIds =
            inventoryData.map((e) => (e['objeto_id'] as num).toInt()).toSet();
      }
    } catch (e) {
      error = 'Error cargando tienda: $e';
      debugPrint(error);
    } finally {
      isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  // â”€â”€â”€ Purchase â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Attempts to purchase an item.
  Future<bool> purchaseItem(String? userId, int itemId) async {
    // Local pre-check
    if (ownedItemIds.contains(itemId)) {
      error = 'Ya posees este objeto';
      notifyListeners();
      return false;
    }

    try {
      if (userId == null) {
        // Local purchase
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
      debugPrint('Purchase error: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Error de red al comprar: $e';
      debugPrint(error);
      notifyListeners();
      return false;
    }
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Whether the user owns a given item.
  bool ownsItem(int itemId) => ownedItemIds.contains(itemId);

  /// Get catalog items filtered by category keyword.
  List<ShopItem> itemsByCategory(String category) =>
      catalog
          .where(
            (item) =>
                item.categoria.toLowerCase().contains(category.toLowerCase()),
          )
          .toList();

  /// Translate Postgres exceptions into user-friendly messages.
  String _friendlyError(String pgMsg) {
    if (pgMsg.contains('Monedas insuficientes')) {
      return 'No tienes suficientes monedas';
    }
    if (pgMsg.contains('Ya posees')) return 'Ya tienes este objeto';
    if (pgMsg.contains('Objeto no encontrado')) return 'Este objeto no existe';
    return 'Error al procesar la compra';
  }
}
