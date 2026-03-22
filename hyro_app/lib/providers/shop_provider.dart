import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/shop/models/shop_item.dart';

/// Manages the shop catalog, user inventory, and purchases via Supabase.
class ShopProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<ShopItem> catalog = [];
  Set<int> ownedItemIds = {};
  bool isLoading = false;
  String? error;

  // ─── Load Catalog + Inventory ─────────────────────────────────────

  /// Fetches the full store catalog and the user's owned items in parallel.
  Future<void> loadShop(String userId) async {
    isLoading = true;
    error = null;
    Future.microtask(() => notifyListeners());

    try {
      // Parallel fetch: catalog + user inventory
      final results = await Future.wait([
        _supabase
            .from('objetos_tienda')
            .select('id, nombre, categoria, precio')
            .order('id'),
        _supabase
            .from('inventario_usuarios')
            .select('objeto_id')
            .eq('usuario_id', userId),
      ]);

      final catalogData = results[0] as List<dynamic>;
      final inventoryData = results[1] as List<dynamic>;

      catalog = catalogData
          .map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      ownedItemIds = inventoryData
          .map((e) => (e['objeto_id'] as num).toInt())
          .toSet();
    } catch (e) {
      error = 'Error cargando tienda: $e';
      debugPrint(error);
    } finally {
      isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  // ─── Purchase ─────────────────────────────────────────────────────

  /// Attempts to purchase an item via the `comprar_objeto` RPC.
  /// Returns `true` on success, `false` on failure (sets [error]).
  Future<bool> purchaseItem(String userId, int itemId) async {
    // Local pre-check (the RPC also validates server-side)
    if (ownedItemIds.contains(itemId)) {
      error = 'Ya posees este objeto';
      notifyListeners();
      return false;
    }

    try {
      await _supabase.rpc(
        'comprar_objeto',
        params: {'p_usuario_id': userId, 'p_objeto_id': itemId},
      );

      // Optimistic update — add to local owned set immediately
      ownedItemIds.add(itemId);
      error = null;
      notifyListeners();
      return true;
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

  // ─── Helpers ──────────────────────────────────────────────────────

  /// Whether the user owns a given item.
  bool ownsItem(int itemId) => ownedItemIds.contains(itemId);

  /// Get catalog items filtered by category keyword.
  List<ShopItem> itemsByCategory(String category) =>
      catalog.where((item) => item.categoria.toLowerCase().contains(category.toLowerCase())).toList();

  /// Translate Postgres exceptions into user-friendly messages.
  String _friendlyError(String pgMsg) {
    if (pgMsg.contains('Monedas insuficientes')) return 'No tienes suficientes monedas';
    if (pgMsg.contains('Ya posees')) return 'Ya tienes este objeto';
    if (pgMsg.contains('Objeto no encontrado')) return 'Este objeto no existe';
    return 'Error al procesar la compra';
  }
}
