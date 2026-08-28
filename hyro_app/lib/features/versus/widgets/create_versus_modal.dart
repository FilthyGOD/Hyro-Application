import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/versus_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../../features/tasks/tasks_provider.dart';
import '../../../../data/models/tarea_card_model.dart';
import '../../../../data/models/category_model.dart';
import '../../friends/providers/friends_provider.dart';
import '../../friends/widgets/static_mascot_widget.dart';
import '../models/versus_models.dart';

/// Modal flotante para configurar y enviar un reto de Versus.
/// Muestra 4 botones de colores que abren sub-diálogos para cada selección.
class CreateVersusModal extends StatefulWidget {
  final Function(Map<String, dynamic> payload)? onChallengeSent;

  const CreateVersusModal({super.key, this.onChallengeSent});

  /// Método estático para desplegar el diálogo flotante
  static Future<void> show({
    required BuildContext context,
    Function(Map<String, dynamic> payload)? onChallengeSent,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => CreateVersusModal(onChallengeSent: onChallengeSent),
    );
  }

  @override
  State<CreateVersusModal> createState() => _CreateVersusModalState();
}

class _CreateVersusModalState extends State<CreateVersusModal>
    with SingleTickerProviderStateMixin {
  // ── Estado de selección ──
  VersusPlayer? _selectedOpponent;
  BattleMode _modoSeleccionado = BattleMode.sameSubject;
  String? _tareaSeleccionadaId;
  String? _categoriaSeleccionadaId;
  String? _materiaNombre;
  String? _tareaNombre;
  int _costoMonedas = 50;
  bool _isLanzando = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  static const List<int> _opcionesApuesta = [20, 50, 100];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isReadyToLaunch =>
      _selectedOpponent != null && _tareaSeleccionadaId != null;

  /// Lanza el reto llamando a VersusProvider.crearBatalla
  Future<void> _lanzarReto() async {
    final auth = context.read<AuthProvider>();
    final versus = context.read<VersusProvider>();
    final userId = auth.supabaseUserId;

    if (userId == null) {
      _mostrarError('Debes iniciar sesión para lanzar un reto.');
      return;
    }

    if (_selectedOpponent == null) {
      _mostrarError('Selecciona un amigo para retar.');
      return;
    }

    if (_tareaSeleccionadaId == null) {
      _mostrarError('Selecciona una tarea antes de lanzar el reto.');
      return;
    }

    setState(() => _isLanzando = true);

    final modoBatallaDb = _modoSeleccionado.toDb;

    final exito = await versus.crearBatalla(
      oponenteId: _selectedOpponent!.id,
      modoBatalla: modoBatallaDb,
      tareaRetadorId: _tareaSeleccionadaId!,
      categoriaRetadorId: _categoriaSeleccionadaId,
      apuestaMonedas: _costoMonedas,
    );

    if (!mounted) return;
    setState(() => _isLanzando = false);

    if (exito) {
      context.read<ProfileProvider>().loadProfile(userId);

      widget.onChallengeSent?.call({
        'oponente_id': _selectedOpponent!.id,
        'modo_batalla': modoBatallaDb,
        'tarea_retador_id': _tareaSeleccionadaId,
        'categoria_retador_id': _categoriaSeleccionadaId,
        'apuesta_monedas': _costoMonedas,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          content: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Reto enviado a ${_selectedOpponent!.username}!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _mostrarError(versus.actionMessage ?? 'Error al crear el reto.');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Título ──
                  Text(
                    'Configurar Duelo',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // ── 1. Botón: Selecciona un amigo ──
                  _buildSelectorButton(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4A6CF7),
                        Color.fromARGB(255, 21, 34, 173),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    icon: Icons.person_add_rounded,
                    iconColor: const Color(0xFF4A6CF7),
                    title:
                        _selectedOpponent != null
                            ? _selectedOpponent!.username
                            : 'Selecciona un amigo',
                    subtitle:
                        _selectedOpponent != null
                            ? 'Nivel ${_selectedOpponent!.level}'
                            : 'Nombre del amigo',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                    onTap: _showFriendSelector,
                  ),
                  const SizedBox(height: 25),

                  // ── 2. Fila: Material + Modo de Batalla ──
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Material de estudio
                        Expanded(
                          child: _buildSelectorButton(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 18, 181, 105),
                                Color.fromARGB(255, 1, 112, 60),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.menu_book_rounded,
                            iconColor: const Color.fromARGB(255, 18, 181, 105),
                            title: 'Material de estudio',
                            subtitle:
                                _materiaNombre != null
                                    ? '$_materiaNombre\n$_tareaNombre'
                                    : 'Materia\nActividad, Tarea',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                            onTap: _showMaterialSelector,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 25),
                        // Modo de batalla
                        Expanded(
                          child: _buildSelectorButton(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 242, 93, 12),
                                Color.fromARGB(255, 158, 66, 4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.whatshot_rounded,
                            iconColor: const Color(0xFFEA580C),
                            title: 'Modo de batalla',
                            subtitle: _modoSeleccionado.title,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                            onTap: _showBattleModeSelector,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ── 3. Botón: Selecciona una Apuesta ──
                  _buildSelectorButton(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 130, 34, 248),
                        Color.fromARGB(255, 100, 6, 201),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    icon: Icons.monetization_on_rounded,
                    iconColor: const Color.fromARGB(255, 130, 34, 248),
                    title: 'Selecciona una Apuesta',
                    subtitle: 'Cantidad: $_costoMonedas monedas',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                    onTap: _showBetSelector,
                  ),
                  const SizedBox(height: 50),

                  // ── 4. Botón: Iniciar Reto ──
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          (_isLanzando || !_isReadyToLaunch)
                              ? null
                              : _lanzarReto,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                (_isLanzando || !_isReadyToLaunch)
                                    ? const Color.fromARGB(255, 10, 193, 47)
                                    : const Color.fromARGB(255, 10, 193, 47),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child:
                              _isLanzando
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.flash_on_rounded,
                                        size: 22,
                                        color:
                                            (_isLanzando || !_isReadyToLaunch)
                                                ? const Color.fromARGB(
                                                  95,
                                                  255,
                                                  255,
                                                  255,
                                                )
                                                : Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Iniciar Reto',
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              color:
                                                  (_isLanzando ||
                                                          !_isReadyToLaunch)
                                                      ? const Color.fromARGB(
                                                        97,
                                                        255,
                                                        255,
                                                        255,
                                                      )
                                                      : Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── 5. Botón: Cancelar ──
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 30, 30),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancelar',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTÓN SELECTOR GENÉRICO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSelectorButton({
    required Gradient gradient,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final iconBox = Container(
      width: compact ? 38 : 48,
      height: compact ? 38 : 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
      ),
      child: Icon(icon, color: iconColor, size: compact ? 22 : 26),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (gradient as LinearGradient).colors.first.withValues(
                  alpha: 0.3,
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child:
              compact
                  // ── Layout compacto: icono+chevron arriba, texto abajo ──
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [iconBox, if (trailing != null) trailing],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                  // ── Layout normal: fila horizontal ──
                  : Row(
                    children: [
                      iconBox,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing,
                    ],
                  ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUB-DIÁLOGO 1: SELECCIÓN DE AMIGO
  // ═══════════════════════════════════════════════════════════════════════════

  void _showFriendSelector() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder:
          (dialogContext) => _FriendSelectorDialog(
            onFriendSelected: (player) {
              setState(() {
                _selectedOpponent = player;
              });
            },
          ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUB-DIÁLOGO 2: SELECCIÓN DE MATERIAL DE ESTUDIO
  // ═══════════════════════════════════════════════════════════════════════════

  void _showMaterialSelector() {
    final tasks = context.read<TaskProvider>().tasks;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder:
          (dialogContext) => _MaterialSelectorDialog(
            tasks: tasks,
            onTaskSelected: (taskId, taskTitle, categoryId, categoryName) {
              setState(() {
                _tareaSeleccionadaId = taskId;
                _tareaNombre = taskTitle;
                _categoriaSeleccionadaId = categoryId;
                _materiaNombre = categoryName;
              });
            },
          ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUB-DIÁLOGO 3: SELECCIÓN DE MODO DE BATALLA
  // ═══════════════════════════════════════════════════════════════════════════

  void _showBattleModeSelector() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder:
          (dialogContext) => _BattleModeSelectorDialog(
            currentMode: _modoSeleccionado,
            onModeSelected: (mode) {
              setState(() {
                _modoSeleccionado = mode;
              });
            },
          ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUB-DIÁLOGO 4: SELECCIÓN DE APUESTA
  // ═══════════════════════════════════════════════════════════════════════════

  void _showBetSelector() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder:
          (dialogContext) => _BetSelectorDialog(
            currentBet: _costoMonedas,
            options: _opcionesApuesta,
            onBetSelected: (bet) {
              setState(() {
                _costoMonedas = bet;
              });
            },
          ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIÁLOGO: SELECCIÓN DE AMIGO
// ═════════════════════════════════════════════════════════════════════════════

class _FriendSelectorDialog extends StatefulWidget {
  final Function(VersusPlayer) onFriendSelected;

  const _FriendSelectorDialog({required this.onFriendSelected});

  @override
  State<_FriendSelectorDialog> createState() => _FriendSelectorDialogState();
}

class _FriendSelectorDialogState extends State<_FriendSelectorDialog> {
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

      final response =
          await Supabase.instance.client
                  .from('perfiles')
                  .select(
                    'id, nombre_usuario, nivel, mascota_cosmeticos(sombrero, cara, traje)',
                  )
                  .ilike('nombre_usuario', '%$query%')
                  .neq('id', currentUserId)
                  .limit(10)
              as List<dynamic>;

      final results =
          response.map((row) {
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
      debugPrint('❌ [FriendSelector] Error en búsqueda global: $e');
    } finally {
      setState(() {
        _isSearchingGlobal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.watch<FriendsProvider>();

    final List<VersusPlayer> friends =
        friendsProvider.ranking
            .where((entry) => !entry.isCurrentUser)
            .map(
              (entry) => VersusPlayer(
                id: entry.usuarioId,
                username: entry.nombreUsuario,
                sombreroId: entry.sombrero,
                cosmeticoId: entry.cosmetico,
                trajeId: entry.traje,
                level: 1,
              ),
            )
            .toList();

    final List<VersusPlayer> filteredFriends =
        friends.where((friend) {
          return friend.username.toLowerCase().contains(_query.toLowerCase());
        }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header azul ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A6CF7), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                'Amigos',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // ── Body ──
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona un amigo para retar',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _query = val;
                            if (val.trim().isEmpty) {
                              _globalSearchResults.clear();
                              _searchError = null;
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Global search button
                    if (_query.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isSearchingGlobal
                                    ? null
                                    : () => _buscarGlobalmente(_query),
                            icon:
                                _isSearchingGlobal
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.language_rounded,
                                      size: 16,
                                    ),
                            label: Text(
                              _isSearchingGlobal
                                  ? 'Buscando...'
                                  : 'Buscar globalmente',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Friend list
                    Expanded(
                      child:
                          _isSearchingGlobal
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                              : _searchError != null
                              ? Center(
                                child: Text(
                                  _searchError!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : _query.trim().isNotEmpty &&
                                  _globalSearchResults.isNotEmpty
                              ? _buildFriendList(_globalSearchResults)
                              : filteredFriends.isEmpty
                              ? Center(
                                child: Text(
                                  _query.isEmpty
                                      ? 'No tienes amigos agregados todavía.'
                                      : 'No se encontraron amigos.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : _buildFriendList(filteredFriends),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendList(List<VersusPlayer> players) {
    return ListView.separated(
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = players[index];

        return ListTile(
          tileColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          leading: SizedBox(
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
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
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () {
              widget.onFriendSelected(player);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

// ═════════════════════════════════════════════════════════════════════════════
// DIÁLOGO: SELECCIÓN DE MATERIAL DE ESTUDIO
// ═════════════════════════════════════════════════════════════════════════════

class _MaterialSelectorDialog extends StatefulWidget {
  final List<dynamic> tasks;
  final Function(
    String taskId,
    String taskTitle,
    String? categoryId,
    String categoryName,
  )
  onTaskSelected;

  const _MaterialSelectorDialog({
    required this.tasks,
    required this.onTaskSelected,
  });

  @override
  State<_MaterialSelectorDialog> createState() =>
      _MaterialSelectorDialogState();
}

class _MaterialSelectorDialogState extends State<_MaterialSelectorDialog> {
  CategoryModel? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header naranja ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFF92400E)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                'Material de estudio',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // ── Body ──
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _selectedCategory == null
                        ? _buildCategoryList()
                        : _buildTaskList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categoriesBox = Hive.box<CategoryModel>('categoriesBox');
    final catIds =
        widget.tasks.map((t) => t.categoryId).where((id) => id != null).toSet();
    final categories =
        categoriesBox.values.where((c) => catIds.contains(c.id)).toList();

    return Padding(
      key: const ValueKey('mat_categories'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de materia
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF92400E).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Selecciona una materia',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Text(
              'No tienes materias disponibles.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final color = Color(category.colorValue);
                  final taskCount =
                      widget.tasks
                          .where((t) => t.categoryId == category.id)
                          .length;

                  return ListTile(
                    tileColor: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      radius: 20,
                      child: Icon(
                        category.iconCodePoint != null
                            ? IconData(
                              category.iconCodePoint!,
                              fontFamily: 'MaterialIcons',
                            )
                            : Icons.folder,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$taskCount tareas',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final category = _selectedCategory!;
    final tasks =
        widget.tasks.where((t) => t.categoryId == category.id).toList();
    final cardsBox = Hive.box<TareaCardModel>('cardsBox');

    return Padding(
      key: ValueKey('mat_tasks_${category.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF92400E).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Back button
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = null;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cambiar materia',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tareas',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Text(
              'No tienes tareas en esta materia.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final numCards =
                      cardsBox.values.where((c) => c.tareaId == task.id).length;
                  final color = Color(task.priorityColorValue);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        widget.onTaskSelected(
                          task.id,
                          task.title,
                          task.categoryId,
                          category.name,
                        );
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.radio_button_unchecked,
                              color: AppColors.textTertiary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '$numCards cards',
                                style: AppTypography.bodySmall.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIÁLOGO: SELECCIÓN DE MODO DE BATALLA
// ═════════════════════════════════════════════════════════════════════════════

class _BattleModeSelectorDialog extends StatefulWidget {
  final BattleMode currentMode;
  final Function(BattleMode) onModeSelected;

  const _BattleModeSelectorDialog({
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  State<_BattleModeSelectorDialog> createState() =>
      _BattleModeSelectorDialogState();
}

class _BattleModeSelectorDialogState extends State<_BattleModeSelectorDialog> {
  late BattleMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header rojo/naranja ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                'Modo de Batalla',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...BattleMode.values.map((mode) {
                    final isSelected = _selected == mode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _selected = mode);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(
                                        0xFFEA580C,
                                      ).withValues(alpha: 0.12)
                                      : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFFEA580C)
                                        : AppColors.cardBorder,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color:
                                      isSelected
                                          ? const Color(0xFFEA580C)
                                          : AppColors.textTertiary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mode.title,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color:
                                                  isSelected
                                                      ? const Color(0xFFEA580C)
                                                      : AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        mode.description,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onModeSelected(_selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIÁLOGO: SELECCIÓN DE APUESTA
// ═════════════════════════════════════════════════════════════════════════════

class _BetSelectorDialog extends StatefulWidget {
  final int currentBet;
  final List<int> options;
  final Function(int) onBetSelected;

  const _BetSelectorDialog({
    required this.currentBet,
    required this.options,
    required this.onBetSelected,
  });

  @override
  State<_BetSelectorDialog> createState() => _BetSelectorDialogState();
}

class _BetSelectorDialogState extends State<_BetSelectorDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentBet;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header verde/dorado ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                'Selecciona una Apuesta',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Apuesta de monedas',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children:
                        widget.options.map((monto) {
                          final isSelected = _selected == monto;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap:
                                      () => setState(() => _selected = monto),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(
                                                0xFFF59E0B,
                                              ).withValues(alpha: 0.2)
                                              : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFFF59E0B)
                                                : AppColors.cardBorder,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFF59E0B,
                                                  ).withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Column(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/images/HyroCoins.svg',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$monto',
                                          style: AppTypography.labelLarge
                                              .copyWith(
                                                color:
                                                    isSelected
                                                        ? const Color(
                                                          0xFFF59E0B,
                                                        )
                                                        : AppColors
                                                            .textSecondary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Pozo total
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pozo total: ${_selected * 2} Monedas',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onBetSelected(_selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
