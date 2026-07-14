import 'package:flutter/material.dart';
import '../features/friends/models/friends_models.dart';
import '../services/friends_service.dart';

/// Estado reactivo para la pantalla de vista previa de perfil de terceros.
/// Gestiona la carga del perfil, el estado de relación y las acciones
/// (agregar, aceptar, rechazar, eliminar, bloquear).
class UserProfilePreviewProvider extends ChangeNotifier {
  final FriendsService _service = FriendsService();

  // ── Estado ──
  UserProfilePreview? profile;
  RelationshipInfo relationship = const RelationshipInfo.none();

  bool isLoading = false;
  bool isActioning = false;
  String? error;
  String? actionMessage;

  // ─── Carga del Perfil ──────────────────────────────────────────────

  /// Carga el perfil del usuario visitado y el estado de relación en paralelo.
  Future<void> loadUserProfile(String targetUserId, String currentUserId) async {
    isLoading = true;
    error = null;
    profile = null;
    relationship = const RelationshipInfo.none();
    Future.microtask(() => notifyListeners());

    try {
      // Ejecutar ambas consultas en paralelo
      final results = await Future.wait([
        _service.getUserProfileById(targetUserId),
        _service.getRelationshipStatus(currentUserId, targetUserId),
      ]);

      final profileData = results[0];
      final relationData = results[1]!;

      if (profileData == null) {
        error = 'Usuario no encontrado';
        return;
      }

      profile = UserProfilePreview.fromJson(profileData);
      relationship = _parseRelationship(relationData);
    } catch (e) {
      error = 'Error cargando perfil: $e';
      debugPrint(error);
    } finally {
      isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Parsea la respuesta del servicio a un RelationshipInfo.
  RelationshipInfo _parseRelationship(Map<String, dynamic> data) {
    final status = data['status'] as String;
    final friendshipId = data['friendshipId'] as String?;

    switch (status) {
      case 'friends':
        return RelationshipInfo(
          status: RelationshipStatus.friends,
          friendshipId: friendshipId,
        );
      case 'requestSent':
        return RelationshipInfo(
          status: RelationshipStatus.requestSent,
          friendshipId: friendshipId,
        );
      case 'requestReceived':
        return RelationshipInfo(
          status: RelationshipStatus.requestReceived,
          friendshipId: friendshipId,
        );
      case 'blocked':
        return RelationshipInfo(
          status: RelationshipStatus.blocked,
          blockerId: data['blockerId'] as String?,
        );
      default:
        return const RelationshipInfo.none();
    }
  }

  // ─── Acciones ──────────────────────────────────────────────────────

  /// Envía una solicitud de amistad.
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    isActioning = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _service.sendFriendRequest(currentUserId, targetUserId);
      actionMessage = '¡Solicitud enviada!';
      relationship = const RelationshipInfo(
        status: RelationshipStatus.requestSent,
      );
    } catch (e) {
      actionMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isActioning = false;
      notifyListeners();
    }
  }

  /// Acepta una solicitud de amistad recibida.
  Future<void> acceptRequest(String friendshipId) async {
    isActioning = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _service.acceptRequest(friendshipId);
      actionMessage = '¡Solicitud aceptada! Ahora son amigos.';
      relationship = RelationshipInfo(
        status: RelationshipStatus.friends,
        friendshipId: friendshipId,
      );
    } catch (e) {
      actionMessage = 'Error al aceptar: $e';
    } finally {
      isActioning = false;
      notifyListeners();
    }
  }

  /// Rechaza una solicitud de amistad recibida.
  Future<void> rejectRequest(String friendshipId) async {
    isActioning = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _service.rejectRequest(friendshipId);
      actionMessage = 'Solicitud rechazada.';
      relationship = const RelationshipInfo.none();
    } catch (e) {
      actionMessage = 'Error al rechazar: $e';
    } finally {
      isActioning = false;
      notifyListeners();
    }
  }

  /// Elimina una amistad confirmada.
  Future<void> removeFriend(String friendshipId) async {
    isActioning = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _service.removeFriend(friendshipId);
      actionMessage = 'Amigo eliminado.';
      relationship = const RelationshipInfo.none();
    } catch (e) {
      actionMessage = 'Error al eliminar: $e';
    } finally {
      isActioning = false;
      notifyListeners();
    }
  }

  /// Bloquea a un usuario.
  Future<void> blockUser(String blockerId, String blockedId) async {
    isActioning = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _service.blockUser(blockerId, blockedId);
      actionMessage = 'Usuario bloqueado.';
      relationship = RelationshipInfo(
        status: RelationshipStatus.blocked,
        blockerId: blockerId,
      );
    } catch (e) {
      actionMessage = 'Error al bloquear: $e';
    } finally {
      isActioning = false;
      notifyListeners();
    }
  }

  /// Desbloquea a un usuario.
  Future<void> unblockUser(String blockerId, String blockedId) async {
    isActioning = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _service.unblockUser(blockerId, blockedId);
      actionMessage = 'Usuario desbloqueado.';
      relationship = const RelationshipInfo.none();
    } catch (e) {
      actionMessage = 'Error al desbloquear: $e';
    } finally {
      isActioning = false;
      notifyListeners();
    }
  }

  /// Limpia el mensaje de acción temporal.
  void clearActionMessage() {
    actionMessage = null;
    notifyListeners();
  }
}
