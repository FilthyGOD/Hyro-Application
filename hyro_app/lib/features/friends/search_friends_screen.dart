import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import 'models/friends_models.dart';
import 'user_profile_preview_screen.dart';

/// Pantalla dedicada de búsqueda de amigos estilo Duolingo.
/// Permite buscar usuarios por nombre con ilike y muestra resultados
/// en una lista de tarjetas navegables.
class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    // Limpiar resultados al salir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      // No podemos acceder al context aquí, la limpieza la hace el provider
    });
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final auth = context.read<AuthProvider>();
      final userId = auth.supabaseUserId;
      if (userId != null) {
        context.read<FriendsProvider>().searchUsersByName(query, userId);
      }
    });
  }

  void _navigateToProfile(UserSearchResult user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePreviewScreen(targetUserId: user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            context.read<FriendsProvider>().clearNameSearch();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Agregar amigos',
          style: AppTypography.h3.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ──
          _buildSearchBar(),

          // ── Resultados ──
          Expanded(
            child: Consumer<FriendsProvider>(
              builder: (context, friends, _) {
                if (friends.isSearchingByName) {
                  return _buildLoadingState();
                }

                if (_searchController.text.trim().isEmpty) {
                  return _buildInitialState();
                }

                if (friends.searchByNameError != null &&
                    friends.nameSearchResults.isEmpty) {
                  return _buildEmptyState(friends.searchByNameError!);
                }

                if (friends.nameSearchResults.isEmpty) {
                  return _buildEmptyState(
                    'No se encontraron usuarios con ese nombre',
                  );
                }

                return _buildResultsList(friends.nameSearchResults);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Barra de Búsqueda ────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre de usuario...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withAlpha(150),
              fontSize: 14,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            suffixIcon: Consumer<FriendsProvider>(
              builder: (context, friends, _) {
                if (friends.isSearchingByName) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                if (_searchController.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      context.read<FriendsProvider>().clearNameSearch();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  // ─── Estado Inicial ───────────────────────────────────────────────

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Busca amigos por nombre',
              style: AppTypography.h3.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Escribe el nombre de usuario de la persona\nque quieres agregar como amigo.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Estado de Carga ──────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Buscando usuarios...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Estado Vacío / Error ─────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_rounded,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Lista de Resultados ──────────────────────────────────────────

  Widget _buildResultsList(List<UserSearchResult> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = results[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserSearchResult user) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToProfile(user),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // Avatar placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(60),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Nombre y tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombreUsuario,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.displayTag,
                      style: TextStyle(
                        color: AppColors.primary.withAlpha(180),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Flecha de navegación
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
