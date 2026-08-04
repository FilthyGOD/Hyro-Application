import 'package:flutter/material.dart';
import '../models/friends_models.dart';
import '../services/friends_service.dart';

/// Estado reactivo para el sistema de amigos.
/// Gestiona ranking semanal, solicitudes pendientes, búsqueda y acciones de amistad.
class FriendsProvider extends ChangeNotifier {
  final FriendsService _service = FriendsService();

  // ── Estado ──
  List<RankingEntry> ranking = [];
  List<FriendRequest> pendingRequests = [];
  SearchResult? searchResult;

  bool isLoading = false;
  bool isSearching = false;
  bool isSendingRequest = false;
  String? error;
  String? searchError;
  String? actionMessage; // Mensaje temporal de éxito/error para acciones

  // ─── Carga Inicial ──────────────────────────────────────────────────

  /// Carga ranking semanal + solicitudes pendientes en paralelo.
  Future<void> loadFriendsData(String userId) async {
    isLoading = true;
    error = null;
    Future.microtask(() => notifyListeners());

    try {
      // Ejecutar ambas consultas en paralelo
      final results = await Future.wait([
        _service.getFriendsRanking(userId),
        _service.getPendingRequests(userId),
      ]);

      final rankingData = results[0];
      final requestsData = results[1];

      ranking = rankingData
          .map((json) => RankingEntry.fromJson(json, currentUserId: userId))
          .toList();

      pendingRequests = requestsData
          .map((json) => FriendRequest.fromJson(json))
          .toList();
    } catch (e) {
      error = 'Error cargando datos de amigos: $e';
      debugPrint(error);
    } finally {
      isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  // ─── Búsqueda ───────────────────────────────────────────────────────

  /// Busca un usuario por formato "Nombre#Código".
  Future<void> searchUser(String query, String currentUserId) async {
    isSearching = true;
    searchError = null;
    searchResult = null;
    notifyListeners();

    try {
      final data = await _service.searchUserByCode(query);

      if (data == null) {
        searchError = 'No se encontró ningún usuario con ese código';
        return;
      }

      final targetId = data['id'] as String;

      if (targetId == currentUserId) {
        searchError = '¡No puedes agregarte a ti mismo!';
        return;
      }

      // Verificar relación existente
      final existing = await _service.checkExistingRelation(currentUserId, targetId);
      bool alreadyFriends = false;
      bool requestPending = false;

      if (existing != null) {
        final estado = existing['estado'] as String;
        alreadyFriends = estado == 'aceptada';
        requestPending = estado == 'pendiente';
      }

      searchResult = SearchResult(
        usuarioId: targetId,
        nombreUsuario: data['nombre_usuario'] as String? ?? 'Usuario',
        codigoAmigo: (data['codigo_amigo'] as num).toInt(),
        alreadyFriends: alreadyFriends,
        requestPending: requestPending,
      );
    } on ArgumentError catch (e) {
      searchError = e.message;
    } catch (e) {
      searchError = 'Error en la búsqueda: $e';
      debugPrint(searchError);
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  /// Limpia el resultado de búsqueda.
  void clearSearch() {
    searchResult = null;
    searchError = null;
    notifyListeners();
  }

  // ─── Acciones de Amistad ────────────────────────────────────────────

  /// Envía una solicitud de amistad.
  Future<bool> sendRequest(String currentUserId, String targetUserId) async {
    isSendingRequest = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _service.sendFriendRequest(currentUserId, targetUserId);
      actionMessage = '¡Solicitud enviada!';

      // Actualizar el resultado de búsqueda para reflejar el estado
      if (searchResult != null && searchResult!.usuarioId == targetUserId) {
        searchResult = searchResult!.copyWith(requestPending: true);
      }

      return true;
    } catch (e) {
      actionMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSendingRequest = false;
      notifyListeners();
    }
  }

  /// Acepta una solicitud de amistad y recarga los datos.
  Future<void> acceptRequest(String friendshipId, String userId) async {
    try {
      await _service.acceptRequest(friendshipId);
      actionMessage = '¡Solicitud aceptada!';
      notifyListeners();

      // Recargar datos para reflejar el cambio
      await loadFriendsData(userId);
    } catch (e) {
      actionMessage = 'Error al aceptar: $e';
      debugPrint(actionMessage);
      notifyListeners();
    }
  }

  /// Rechaza una solicitud de amistad y recarga los datos.
  Future<void> rejectRequest(String friendshipId, String userId) async {
    try {
      await _service.rejectRequest(friendshipId);
      actionMessage = 'Solicitud rechazada';
      notifyListeners();

      // Recargar datos para reflejar el cambio
      await loadFriendsData(userId);
    } catch (e) {
      actionMessage = 'Error al rechazar: $e';
      debugPrint(actionMessage);
      notifyListeners();
    }
  }

  /// Limpia el mensaje de acción temporal.
  void clearActionMessage() {
    actionMessage = null;
    notifyListeners();
  }

  // ─── Búsqueda por Nombre (Pantalla Dedicada) ──────────────────────

  List<UserSearchResult> nameSearchResults = [];
  bool isSearchingByName = false;
  String? searchByNameError;

  /// Busca usuarios por nombre usando ilike.
  /// Dispara la consulta al servicio y actualiza el estado.
  Future<void> searchUsersByName(String query, String currentUserId) async {
    if (query.trim().isEmpty) {
      nameSearchResults = [];
      searchByNameError = null;
      notifyListeners();
      return;
    }

    isSearchingByName = true;
    searchByNameError = null;
    notifyListeners();

    try {
      final data = await _service.searchUsersByName(query.trim(), currentUserId);
      nameSearchResults = data
          .map((json) => UserSearchResult.fromJson(json))
          .toList();

      if (nameSearchResults.isEmpty) {
        searchByNameError = 'No se encontraron usuarios con ese nombre';
      }
    } catch (e) {
      searchByNameError = 'Error en la búsqueda: $e';
      nameSearchResults = [];
      debugPrint(searchByNameError);
    } finally {
      isSearchingByName = false;
      notifyListeners();
    }
  }

  /// Limpia los resultados de búsqueda por nombre.
  void clearNameSearch() {
    nameSearchResults = [];
    searchByNameError = null;
    isSearchingByName = false;
    notifyListeners();
  }
}
