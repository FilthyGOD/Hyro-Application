import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_preview_provider.dart';
import '../../shared/widgets/glass_card.dart';
import 'models/friends_models.dart';
import 'widgets/static_mascot_widget.dart';

/// Pantalla de vista previa del perfil de un usuario tercero.
/// Replica la estructura visual del perfil propio con botones de acción
/// dinámicos según el estado de relación.
class UserProfilePreviewScreen extends StatelessWidget {
  final String targetUserId;

  const UserProfilePreviewScreen({
    super.key,
    required this.targetUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = UserProfilePreviewProvider();
        final auth = context.read<AuthProvider>();
        final currentUserId = auth.supabaseUserId;
        if (currentUserId != null) {
          provider.loadUserProfile(targetUserId, currentUserId);
        }
        return provider;
      },
      child: _UserProfilePreviewBody(targetUserId: targetUserId),
    );
  }
}

class _UserProfilePreviewBody extends StatelessWidget {
  final String targetUserId;

  const _UserProfilePreviewBody({required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Perfil',
          style: AppTypography.h3.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProfilePreviewProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          if (provider.profile == null) {
            return _buildErrorState('No se encontró el perfil');
          }

          return _buildProfileContent(context, provider);
        },
      ),
    );
  }

  // ─── Estado de Carga ──────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando perfil...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Estado de Error ──────────────────────────────────────────────

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Contenido del Perfil ─────────────────────────────────────────

  Widget _buildProfileContent(
    BuildContext context,
    UserProfilePreviewProvider provider,
  ) {
    final profile = provider.profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          // ── Mascota Rive estática ──
          Container(
            width: 144,
            height: 144,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
            ),
            clipBehavior: Clip.hardEdge,
            child: StaticMascotWidget(
              sombrero: profile.sombrero,
              cosmetico: profile.cosmetico,
              traje: profile.traje,
              size: 144,
            ),
          ),

          const SizedBox(height: 16),

          // ── Nombre ──
          Text(
            profile.nombreUsuario,
            style: AppTypography.h2,
          ),
          const SizedBox(height: 4),

          // ── Tag: NombreUsuario#Código ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Text(
              profile.displayTag,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Nivel y XP ──
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A25F4), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Nv. ${profile.nivel}',
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${profile.experiencia} / ${profile.xpForNextLevel} XP',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // XP progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: profile.levelProgress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Estadísticas ──
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFFA726),
                  label: 'Racha',
                  value: '${profile.rachaActual}',
                  subtitle: 'días',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFFFD700),
                  label: 'Mejor racha',
                  value: '${profile.rachaMaxima}',
                  subtitle: 'días',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.timer_rounded,
            iconColor: AppColors.primary,
            label: 'Tiempo total de enfoque',
            value: profile.horasTotales.toStringAsFixed(1),
            subtitle: 'horas',
            fullWidth: true,
          ),

          const SizedBox(height: 28),

          // ── Mensaje de acción ──
          if (provider.actionMessage != null) ...[
            _buildActionMessageBanner(provider.actionMessage!),
            const SizedBox(height: 16),
          ],

          // ── Botones de acción dinámicos ──
          _buildActionButtons(context, provider),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Tarjeta de Estadística ───────────────────────────────────────

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
    bool fullWidth = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      width: fullWidth ? double.infinity : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Banner de Mensaje de Acción ──────────────────────────────────

  Widget _buildActionMessageBanner(String message) {
    final isError = message.toLowerCase().contains('error');
    final color = isError ? Colors.redAccent : AppColors.breakGreen;
    final bgColor = isError ? Colors.red.withAlpha(15) : AppColors.breakGreen.withAlpha(15);
    final borderColor = isError ? Colors.red.withAlpha(40) : AppColors.breakGreen.withAlpha(40);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Botones de Acción Dinámicos ──────────────────────────────────

  Widget _buildActionButtons(
    BuildContext context,
    UserProfilePreviewProvider provider,
  ) {
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.supabaseUserId!;
    final relationship = provider.relationship;

    switch (relationship.status) {
      // ── Caso A: Sin relación previa ──
      case RelationshipStatus.none:
        return Column(
          children: [
            _buildPrimaryButton(
              label: 'Agregar amigo',
              icon: Icons.person_add_rounded,
              isLoading: provider.isActioning,
              onPressed: provider.isActioning
                  ? null
                  : () => provider.sendFriendRequest(currentUserId, targetUserId),
            ),
            const SizedBox(height: 10),
            _buildSecondaryButton(
              label: 'Bloquear',
              icon: Icons.block_rounded,
              isDestructive: true,
              isLoading: provider.isActioning,
              onPressed: provider.isActioning
                  ? null
                  : () => _showBlockConfirmation(context, provider, currentUserId),
            ),
          ],
        );

      // ── Caso B: Solicitud enviada ──
      case RelationshipStatus.requestSent:
        return _buildDisabledButton(
          label: 'Solicitud enviada',
          icon: Icons.schedule_rounded,
        );

      // ── Caso C: Solicitud recibida ──
      case RelationshipStatus.requestReceived:
        return Column(
          children: [
            _buildPrimaryButton(
              label: 'Aceptar solicitud',
              icon: Icons.check_rounded,
              isLoading: provider.isActioning,
              onPressed: provider.isActioning
                  ? null
                  : () => provider.acceptRequest(relationship.friendshipId!),
            ),
            const SizedBox(height: 10),
            _buildSecondaryButton(
              label: 'Rechazar',
              icon: Icons.close_rounded,
              isLoading: provider.isActioning,
              onPressed: provider.isActioning
                  ? null
                  : () => provider.rejectRequest(relationship.friendshipId!),
            ),
          ],
        );

      // ── Caso D: Ya son amigos ──
      case RelationshipStatus.friends:
        return Column(
          children: [
            _buildDestructiveButton(
              label: 'Eliminar amigo',
              icon: Icons.person_remove_rounded,
              isLoading: provider.isActioning,
              onPressed: provider.isActioning
                  ? null
                  : () => _showRemoveConfirmation(
                        context,
                        provider,
                        relationship.friendshipId!,
                      ),
            ),
            const SizedBox(height: 10),
            _buildSecondaryButton(
              label: 'Bloquear',
              icon: Icons.block_rounded,
              isDestructive: true,
              isLoading: provider.isActioning,
              onPressed: provider.isActioning
                  ? null
                  : () => _showBlockConfirmation(context, provider, currentUserId),
            ),
          ],
        );

      // ── Bloqueado ──
      case RelationshipStatus.blocked:
        return _buildDisabledButton(
          label: 'Usuario bloqueado',
          icon: Icons.block_rounded,
        );
    }
  }

  // ─── Botón Primario ───────────────────────────────────────────────

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 149, 255),
              Color.fromARGB(255, 32, 43, 200),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Botón Secundario ─────────────────────────────────────────────

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    bool isDestructive = false,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    final color = isDestructive ? Colors.redAccent : AppColors.textSecondary;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(60)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ─── Botón Destructivo ────────────────────────────────────────────

  Widget _buildDestructiveButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withAlpha(60)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.redAccent,
                      ),
                    )
                  else ...[
                    Icon(icon, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Botón Deshabilitado ──────────────────────────────────────────

  Widget _buildDisabledButton({
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textDisabled, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Diálogos de Confirmación ─────────────────────────────────────

  void _showRemoveConfirmation(
    BuildContext context,
    UserProfilePreviewProvider provider,
    String friendshipId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1528),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            '¿Eliminar amigo?',
            style: AppTypography.h3.copyWith(fontSize: 18),
          ),
          content: Text(
            'Esta persona será eliminada de tu lista de amigos. Puedes volver a enviarle una solicitud después.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                provider.removeFriend(friendshipId);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBlockConfirmation(
    BuildContext context,
    UserProfilePreviewProvider provider,
    String currentUserId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1528),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            '¿Bloquear usuario?',
            style: AppTypography.h3.copyWith(fontSize: 18),
          ),
          content: Text(
            'Este usuario no podrá enviarte solicitudes de amistad y será eliminado de tu lista de amigos si aplica.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                provider.blockUser(currentUserId, targetUserId);
              },
              child: const Text(
                'Bloquear',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
