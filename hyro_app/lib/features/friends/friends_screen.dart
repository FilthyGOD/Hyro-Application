import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/friends_service.dart';
import 'models/friends_models.dart';
import 'widgets/static_mascot_widget.dart';
import 'search_friends_screen.dart';
import 'user_profile_preview_screen.dart';


/// Pantalla de Amigos — Ranking semanal, solicitudes pendientes y búsqueda por código.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos de amigos al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUserId;
    if (userId != null) {
      context.read<FriendsProvider>().loadFriendsData(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest;

    if (isGuest) {
      return _buildGuestState();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Consumer<FriendsProvider>(
            builder: (context, friends, _) {
              final auth = context.read<AuthProvider>();
              final userId = auth.supabaseUserId;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // ── Header ──
                  _buildHeader(context),
                  const SizedBox(height: 8),
                  Text(
                    'Conecta con tus amigos y estudien juntos',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buzón de regalos pendientes
                  if (userId != null) ...[
                    _buildGiftsBuzon(context, userId),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // ── Mensaje de acción temporal ──
                  if (friends.actionMessage != null)
                    _buildActionMessage(friends),

                  // ── Solicitudes Pendientes ──
                  if (friends.pendingRequests.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Solicitudes Pendientes',
                      '${friends.pendingRequests.length}',
                    ),
                    const SizedBox(height: 12),
                    ...friends.pendingRequests.map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFriendRequestTile(context, req),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Ranking Semanal ──
                  if (friends.isLoading)
                    _buildLoadingState()
                  else if (friends.error != null)
                    _buildErrorState(friends.error!)
                  else if (friends.ranking.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildWeeklyRanking(friends.ranking),

                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Amigos', style: AppTypography.h1),
        _buildAddFriendButton(context),
      ],
    );
  }

  Widget _buildAddFriendButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 0, 149, 255),
            Color.fromARGB(255, 32, 43, 200),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SearchFriendsScreen(),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Agregar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Diálogo de Búsqueda por Código Exacto (alternativa) ───────────

  // ignore: unused_element
  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUserId;

    if (userId == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: context.read<FriendsProvider>(),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F1528),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Agregar Amigo',
                  style: AppTypography.h3.copyWith(fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Consumer<FriendsProvider>(
                builder: (ctx, friends, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingresa el nombre y código de tu amigo',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Campo de búsqueda
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nombre#Código  (ej: Adal Romero#1234)',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withAlpha(150),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: friends.isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.search_rounded,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      final query = searchController.text.trim();
                                      if (query.isNotEmpty) {
                                        friends.searchUser(query, userId);
                                      }
                                    },
                                  ),
                          ),
                          onSubmitted: (value) {
                            final query = value.trim();
                            if (query.isNotEmpty) {
                              friends.searchUser(query, userId);
                            }
                          },
                        ),
                      ),

                      // Error de búsqueda
                      if (friends.searchError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withAlpha(40)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  friends.searchError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Resultado de búsqueda
                      if (friends.searchResult != null) ...[
                        const SizedBox(height: 16),
                        _buildSearchResultCard(ctx, friends, userId),
                      ],

                      // Mensaje de acción
                      if (friends.actionMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.breakGreen.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.breakGreen.withAlpha(40)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.breakGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  friends.actionMessage!,
                                  style: const TextStyle(
                                    color: AppColors.breakGreenLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<FriendsProvider>().clearSearch();
                  context.read<FriendsProvider>().clearActionMessage();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResultCard(
    BuildContext context,
    FriendsProvider friends,
    String currentUserId,
  ) {
    final result = friends.searchResult!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withAlpha(60),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.nombreUsuario,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${result.codigoAmigo}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Botón de acción
          if (result.alreadyFriends)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.breakGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ya son amigos',
                style: TextStyle(
                  color: AppColors.breakGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (result.requestPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pendiente',
                style: TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 0, 149, 255),
                    Color.fromARGB(255, 32, 43, 200),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: friends.isSendingRequest
                      ? null
                      : () => friends.sendRequest(currentUserId, result.usuarioId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: friends.isSendingRequest
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enviar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Solicitudes Pendientes ─────────────────────────────────────────

  Widget _buildFriendRequestTile(BuildContext context, FriendRequest request) {
    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUserId!;

    // Calcular tiempo relativo
    final elapsed = DateTime.now().difference(request.solicitadoEn);
    String timeAgo;
    if (elapsed.inMinutes < 60) {
      timeAgo = 'hace ${elapsed.inMinutes} min';
    } else if (elapsed.inHours < 24) {
      timeAgo = 'hace ${elapsed.inHours}h';
    } else {
      timeAgo = 'hace ${elapsed.inDays}d';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1840), Color(0xFF131829)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A25F4).withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF6A25F4).withAlpha(100),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Color(0xFFA855F7),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.nombreUsuario,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solicitud de amistad · $timeAgo',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Botones de aceptar/rechazar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.close_rounded,
                color: AppColors.textSecondary,
                bgColor: AppColors.surfaceLight,
                onTap: () {
                  context.read<FriendsProvider>().rejectRequest(request.id, userId);
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.check_rounded,
                color: Colors.white,
                bgColor: const Color(0xFF6A25F4),
                onTap: () {
                  context.read<FriendsProvider>().acceptRequest(request.id, userId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  // ─── Ranking Semanal ────────────────────────────────────────────────

  Widget _buildWeeklyRanking(List<RankingEntry> ranking) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182040), Color(0xFF0F1528)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.leaderboard_rounded,
                color: Color(0xFFFFA726),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Ranking Semanal',
                style: AppTypography.h3.copyWith(fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Esta semana',
                  style: TextStyle(
                    color: Color(0xFFFFA726),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(ranking.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < ranking.length - 1 ? 8 : 0),
              child: _buildRankingItem(
                rank: index + 1,
                entry: ranking[index],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required RankingEntry entry,
  }) {
    final rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    final rankColor = rankColors[rank] ?? AppColors.textSecondary;
    final isMe = entry.isCurrentUser;

    // onTap navega al perfil completo del amigo
    return GestureDetector(
      onTap: isMe
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfilePreviewScreen(
                    targetUserId: entry.usuarioId,
                  ),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              isMe ? Border.all(color: AppColors.primary.withAlpha(40)) : null,
        ),
        child: Row(
          children: [
            // Posición
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Mascota Rive estática con cosméticos
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMe
                        ? AppColors.primary.withAlpha(60)
                        : AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: StaticMascotWidget(
                  sombrero: entry.sombrero,
                  cosmetico: entry.cosmetico,
                  traje: entry.traje,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nombre
            Expanded(
              child: Text(
                isMe ? 'Tú' : entry.nombreUsuario,
                style: TextStyle(
                  color: isMe ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            // Horas
            Text(
              '${entry.horasSemanales.toStringAsFixed(1)}h',
              style: TextStyle(
                color: isMe ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      children: [
        Text(title, style: AppTypography.h3.copyWith(fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6A25F4).withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: Color(0xFFA855F7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mensaje de Acción ──────────────────────────────────────────────

  Widget _buildActionMessage(FriendsProvider friends) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.breakGreen.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.breakGreen.withAlpha(40)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.breakGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                friends.actionMessage!,
                style: const TextStyle(
                  color: AppColors.breakGreenLight,
                  fontSize: 12,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => friends.clearActionMessage(),
              child: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Estados Especiales ─────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Cargando ranking...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Error cargando datos',
              style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Agrega amigos para competir!',
              style: AppTypography.h3.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Busca a tus amigos por su código y compite\nen el ranking semanal de estudio.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 0, 149, 255),
                    Color.fromARGB(255, 32, 43, 200),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SearchFriendsScreen(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Agregar amigo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Inicia sesión para conectar\ncon tus amigos',
                style: AppTypography.h2.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'El sistema de amigos y ranking semanal\nrequiere una cuenta activa.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftsBuzon(BuildContext context, String currentUserId) {
    return StreamBuilder<List<GiftWithDetails>>(
      stream: FriendsService().getPendingGiftsStream(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final pendingGifts = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Regalos Pendientes',
              '${pendingGifts.length}',
            ),
            const SizedBox(height: 12),
            ...pendingGifts.map((gift) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildGiftBanner(context, gift, currentUserId),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildGiftBanner(BuildContext context, GiftWithDetails gift, String currentUserId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2640), Color(0xFF15182B)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.amber.withAlpha(100),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                color: Colors.amber,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(
                        text: gift.remitenteNombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' te envió un regalo: '),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gift.objetoNombre,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.close_rounded,
                color: Colors.redAccent,
                bgColor: AppColors.surfaceLight,
                onTap: () async {
                  try {
                    await FriendsService().rejectGift(gift.id);
                    if (context.mounted) {
                      await context.read<ProfileProvider>().loadProfile(currentUserId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Regalo rechazado y monedas reembolsadas al remitente.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al rechazar regalo: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.check_rounded,
                color: Colors.white,
                bgColor: AppColors.breakGreen,
                onTap: () async {
                  try {
                    await FriendsService().acceptGift(gift.id);
                    if (context.mounted) {
                      await context.read<ProfileProvider>().loadProfile(currentUserId);
                      await context.read<ShopProvider>().loadShop(currentUserId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡Regalo de ${gift.objetoNombre} aceptado con éxito!'),
                            backgroundColor: AppColors.breakGreen,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al aceptar regalo: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
