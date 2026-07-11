import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Pantalla placeholder de Amigos — solo visual, sin funcionalidad aún.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amigos', style: AppTypography.h1),
                _buildAddFriendButton(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Conecta con tus amigos y estudien juntos',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Barra de búsqueda ──
            _buildSearchBar(),
            const SizedBox(height: 24),

            // ── Ranking semanal ──
            _buildWeeklyRanking(),
            const SizedBox(height: 100),

            // ── Amigos en línea ──
            _buildSectionHeader('En Línea', '3'),
            const SizedBox(height: 12),
            _buildFriendTile(
              name: 'Carlos Mendoza',
              status: 'Estudiando — 45 min',
              avatar: '🧑‍💻',
              isOnline: true,
              streakDays: 12,
              xp: 1250,
            ),
            const SizedBox(height: 8),
            _buildFriendTile(
              name: 'Ana García',
              status: 'En sesión de enfoque',
              avatar: '👩‍🎓',
              isOnline: true,
              streakDays: 7,
              xp: 890,
            ),
            const SizedBox(height: 8),
            _buildFriendTile(
              name: 'Miguel Torres',
              status: 'Completando tareas',
              avatar: '🧑‍🔬',
              isOnline: true,
              streakDays: 21,
              xp: 2100,
            ),
            const SizedBox(height: 24),

            // ── Amigos sin conexión ──
            _buildSectionHeader('Sin Conexión', '2'),
            const SizedBox(height: 12),
            _buildFriendTile(
              name: 'Laura Sánchez',
              status: 'Última vez: hace 2 horas',
              avatar: '👩‍💼',
              isOnline: false,
              streakDays: 5,
              xp: 670,
            ),
            const SizedBox(height: 8),
            _buildFriendTile(
              name: 'Diego Ramírez',
              status: 'Última vez: ayer',
              avatar: '🧑‍🎨',
              isOnline: false,
              streakDays: 3,
              xp: 420,
            ),
            const SizedBox(height: 24),

            // ── Solicitudes pendientes ──
            _buildSectionHeader('Solicitudes', '1'),
            const SizedBox(height: 12),
            _buildFriendRequestTile(
              name: 'Sofía López',
              avatar: '👩‍🏫',
              mutualFriends: 3,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFriendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6A25F4)],
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
          onTap: () {}, // Sin funcionalidad aún
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              enabled: false, // Sin funcionalidad aún
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar amigos...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withAlpha(150),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      children: [
        Text(title, style: AppTypography.h3.copyWith(fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendTile({
    required String name,
    required String status,
    required String avatar,
    required bool isOnline,
    required int streakDays,
    required int xp,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar con indicador de estado
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isOnline
                            ? AppColors.breakGreen.withAlpha(100)
                            : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 24)),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color:
                        isOnline
                            ? AppColors.breakGreen
                            : AppColors.textTertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Info del amigo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isOnline)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.breakGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        status,
                        style: TextStyle(
                          color:
                              isOnline
                                  ? AppColors.breakGreenLight
                                  : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats compactos
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFFA726),
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$streakDays',
                    style: const TextStyle(
                      color: Color(0xFFFFA726),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$xp XP',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestTile({
    required String name,
    required String avatar,
    required int mutualFriends,
  }) {
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
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$mutualFriends amigos en común',
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
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.check_rounded,
                color: Colors.white,
                bgColor: const Color(0xFF6A25F4),
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {}, // Sin funcionalidad aún
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

  Widget _buildWeeklyRanking() {
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
          _buildRankingItem(
            rank: 1,
            name: 'Miguel Torres',
            avatar: '🧑‍🔬',
            hours: 14.5,
            isMe: false,
          ),
          const SizedBox(height: 8),
          _buildRankingItem(
            rank: 2,
            name: 'Tú',
            avatar: '🐻',
            hours: 12.0,
            isMe: true,
          ),
          const SizedBox(height: 8),
          _buildRankingItem(
            rank: 3,
            name: 'Carlos Mendoza',
            avatar: '🧑‍💻',
            hours: 10.2,
            isMe: false,
          ),
          const SizedBox(height: 8),
          _buildRankingItem(
            rank: 4,
            name: 'Ana García',
            avatar: '👩‍🎓',
            hours: 8.7,
            isMe: false,
          ),
          const SizedBox(height: 8),
          _buildRankingItem(
            rank: 5,
            name: 'Laura Sánchez',
            avatar: '👩‍💼',
            hours: 6.3,
            isMe: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String name,
    required String avatar,
    required double hours,
    required bool isMe,
  }) {
    final rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    final rankColor = rankColors[rank] ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withAlpha(15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isMe ? Border.all(color: AppColors.primary.withAlpha(40)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(avatar, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isMe ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${hours}h',
            style: TextStyle(
              color: isMe ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
