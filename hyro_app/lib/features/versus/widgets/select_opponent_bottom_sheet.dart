import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../friends/providers/friends_provider.dart';
import '../../friends/widgets/static_mascot_widget.dart';
import '../models/versus_models.dart';
import 'create_versus_modal.dart';

/// BottomSheet para buscar y seleccionar a qué amigo retar en Versus.
class SelectOpponentBottomSheet extends StatefulWidget {
  final Function(VersusPlayer opponent) onChallengeSent;

  const SelectOpponentBottomSheet({
    super.key,
    required this.onChallengeSent,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(VersusPlayer opponent) onChallengeSent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectOpponentBottomSheet(
        onChallengeSent: onChallengeSent,
      ),
    );
  }

  @override
  State<SelectOpponentBottomSheet> createState() => _SelectOpponentBottomSheetState();
}

class _SelectOpponentBottomSheetState extends State<SelectOpponentBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearchingGlobal = false;
  List<VersusPlayer> _globalSearchResults = [];
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Realiza una búsqueda global en Supabase de usuarios para retar.
  Future<void> _buscarGlobalmente(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearchingGlobal = true;
      _searchError = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final currentUserId = auth.supabaseUserId;

      if (currentUserId == null) return;

      final response = await Supabase.instance.client
          .from('perfiles')
          .select('id, nombre_usuario, nivel, mascota_cosmeticos(sombrero, cara, traje)')
          .ilike('nombre_usuario', '%$query%')
          .neq('id', currentUserId)
          .limit(10)
          as List<dynamic>;

      final results = response.map((row) {
        return VersusPlayer.fromProfileData(row as Map<String, dynamic>);
      }).toList();

      setState(() {
        _globalSearchResults = results;
        if (results.isEmpty) {
          _searchError = 'No se encontraron usuarios con ese nombre.';
        }
      });
    } catch (e) {
      setState(() {
        _searchError = 'Error al realizar la búsqueda global.';
      });
      debugPrint('❌ [SelectOpponentBottomSheet] Error en búsqueda global: $e');
    } finally {
      setState(() {
        _isSearchingGlobal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.watch<FriendsProvider>();

    // Obtener amigos de la lista local de ranking
    final List<VersusPlayer> friends = friendsProvider.ranking
        .where((entry) => !entry.isCurrentUser)
        .map((entry) => VersusPlayer(
              id: entry.usuarioId,
              username: entry.nombreUsuario,
              sombreroId: entry.sombrero,
              cosmeticoId: entry.cosmetico,
              trajeId: entry.traje,
              level: 1,
            ))
        .toList();

    // Filtrar amigos localmente si no estamos buscando de forma global activa
    final List<VersusPlayer> filteredFriends = friends.where((friend) {
      return friend.username.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título del Modal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iniciar Duelo',
                      style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      'Selecciona un amigo para retar',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              onChanged: (val) {
                setState(() {
                  _query = val;
                  // Si borran la query, limpiamos búsqueda global
                  if (val.trim().isEmpty) {
                    _globalSearchResults.clear();
                    _searchError = null;
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _globalSearchResults.clear();
                            _searchError = null;
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón opcional de búsqueda global
          if (_query.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSearchingGlobal ? null : () => _buscarGlobalmente(_query),
                  icon: _isSearchingGlobal
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.language_rounded, size: 16),
                  label: Text(
                    _isSearchingGlobal ? 'Buscando...' : 'Buscar globalmente en Hyro',
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

          // Listado de Resultados
          Expanded(
            child: _isSearchingGlobal
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _searchError != null
                    ? Center(
                        child: Text(
                          _searchError!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _query.trim().isNotEmpty && _globalSearchResults.isNotEmpty
                        ? _buildOpponentList(_globalSearchResults)
                        : filteredFriends.isEmpty
                            ? Center(
                                child: Text(
                                  _query.isEmpty
                                      ? 'No tienes amigos agregados todavía.'
                                      : 'No se encontraron amigos con ese nombre.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : _buildOpponentList(filteredFriends),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentList(List<VersusPlayer> players) {
    return ListView.separated(
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = players[index];

        return ListTile(
          tileColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          leading: SizedBox(
            width: 44,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              ),
              child: ClipOval(
                child: StaticMascotWidget(
                  sombrero: player.sombreroId,
                  cosmetico: player.cosmeticoId,
                  traje: player.trajeId,
                ),
              ),
            ),
          ),
          title: Text(
            player.username,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Nivel ${player.level}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
          ),
          trailing: ElevatedButton(
            onPressed: () {
              // Cerrar este BottomSheet
              Navigator.pop(context);
              // Abrir CreateVersusModal
              CreateVersusModal.show(
                context: context,
                opponent: player,
                onChallengeSent: (payload) {
                  widget.onChallengeSent(player);
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              'RETAR',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        );
      },
    );
  }
}
