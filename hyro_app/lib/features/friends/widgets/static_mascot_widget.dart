import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

// ignore_for_file: deprecated_member_use

/// Cache global del archivo Rive para reutilizarlo en múltiples instancias.
/// Se carga una sola vez y se comparte entre todos los StaticMascotWidget.
File? _cachedRiveFile;
bool _isLoadingFile = false;

/// Carga el archivo Rive una sola vez y lo cachea.
Future<File?> _loadRiveFileOnce() async {
  if (_cachedRiveFile != null) return _cachedRiveFile;

  if (_isLoadingFile) {
    // Ya se está cargando, esperar a que termine
    final completer = Future<File?>(() async {
      while (_isLoadingFile) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedRiveFile;
    });
    return completer;
  }

  _isLoadingFile = true;
  try {
    _cachedRiveFile = await File.asset(
      'assets/mascot/jairo44.riv',
      riveFactory: Factory.flutter,
    );
  } catch (e) {
    debugPrint('ERROR: No se pudo cargar el archivo Rive para ranking: $e');
  } finally {
    _isLoadingFile = false;
  }
  return _cachedRiveFile;
}

/// Widget que renderiza la mascota Rive de forma estática con cosméticos inyectados.
///
/// Crucial para rendimiento:
/// - Usa el mismo archivo .riv cacheado (una sola instancia de File)
/// - Crea un RiveWidgetController independiente por widget
/// - Inyecta los valores de cosméticos y captura un solo frame
/// - Después del primer frame, reemplaza el RiveWidget por una imagen estática
///   via RepaintBoundary para que la mascota no consuma recursos al hacer scroll
///
/// [animated] = true: Usa trigger "volver" para mostrar la mascota con animación
///   de movimiento (usado en la pantalla de perfil preview).
/// [animated] = false (default): Usa trigger "atras" para saltar la animación
///   intro y luego pausa la mascota para rendimiento en listas/ranking.
class StaticMascotWidget extends StatefulWidget {
  /// Valor de sombrero (ID numérico, ej: 100, 101, 102...)
  final int sombrero;

  /// Valor de cosmético/cara (ID numérico, ej: 200, 201, 202...)
  /// En la BD es 'cara', en Rive es 'cara'.
  final int cosmetico;

  /// Valor de traje/cuerpo (ID numérico, ej: 300, 301, 302...)
  /// En la BD es 'traje', en Rive es 'cuerpo'.
  final int traje;

  /// Tamaño del widget (ancho y alto).
  final double size;

  /// Si es true, la mascota se muestra animada (con trigger "volver").
  /// Si es false, se dispara "atras" y se pausa para rendimiento.
  final bool animated;

  const StaticMascotWidget({
    super.key,
    required this.sombrero,
    required this.cosmetico,
    required this.traje,
    this.size = 48,
    this.animated = false,
  });

  @override
  State<StaticMascotWidget> createState() => _StaticMascotWidgetState();
}

class _StaticMascotWidgetState extends State<StaticMascotWidget> {
  RiveWidgetController? _controller;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final file = await _loadRiveFileOnce();
    if (file == null || !mounted) return;

    final controller = RiveWidgetController(
      file,
      stateMachineSelector: const StateMachineNamed('State Machine 1'),
    );

    final sm = controller.stateMachine;

    // Inyectar valores de cosméticos
    // Mapeo: sombrero → sombrero, cara (BD) → cara (Rive), traje (BD) → cuerpo (Rive)
    final sombreroInput = sm.number('sombrero') ?? sm.number('control_sombrero');
    final caraInput = sm.number('cara') ?? sm.number('control_cara');
    final cuerpoInput = sm.number('cuerpo') ?? sm.number('control_cuerpo');

    sombreroInput?.value = widget.sombrero.toDouble();
    caraInput?.value = widget.cosmetico.toDouble();
    cuerpoInput?.value = widget.traje.toDouble();

    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
    });

    if (widget.animated) {
      // Modo animado: disparar "atras" primero para saltar intro,
      // luego un pequeño delay y disparar "volver" para animar
      _setupAnimatedMode(sm);
    } else {
      // Modo estático: disparar "atras" para saltar intro y luego pausar
      _setupStaticMode(sm);
    }
  }

  /// Modo estático: dispara "volver" para ir directamente al idle (evitando giros),
  /// espera unos frames para que los cosméticos se apliquen, y luego
  /// pausa la state machine para liberar recursos.
  Future<void> _setupStaticMode(StateMachine sm) async {
    // Disparar "volver" para evitar que giren y vayan al idle directamente
    final triggerVolver = sm.trigger('volver');
    triggerVolver?.fire();

    // Esperar un poco para que la transición se procese
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Congelar después de unos frames
    _scheduleFreeze();
  }

  /// Modo animado: dispara "atras" para saltar intro, espera,
  /// luego dispara "volver" para activar la animación de movimiento.
  Future<void> _setupAnimatedMode(StateMachine sm) async {
    // Disparar "atras" primero para saltar la animación de intro
    final triggerAtras = sm.trigger('atras');
    triggerAtras?.fire();

    // Pequeño delay para que Rive procese la transición
    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    // Ahora disparar "volver" para activar la animación de movimiento
    final triggerVolver = sm.trigger('volver');
    triggerVolver?.fire();

    // No congelamos — dejamos la animación corriendo
  }

  void _scheduleFreeze() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller == null) return;
      _frameCount++;
      // Damos 3 frames para que Rive renderice completamente con cosméticos
      if (_frameCount >= 3) {
        // Cosméticos aplicados — RepaintBoundary aísla el repintado
        return;
      } else {
        _scheduleFreeze();
      }
    });
  }

  @override
  void didUpdateWidget(StaticMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambian los cosméticos, actualizar los inputs y descongelar
    if (oldWidget.sombrero != widget.sombrero ||
        oldWidget.cosmetico != widget.cosmetico ||
        oldWidget.traje != widget.traje) {
      _updateCosmetics();
    }
  }

  void _updateCosmetics() {
    if (_controller == null) return;

    final sm = _controller!.stateMachine;
    final sombreroInput = sm.number('sombrero') ?? sm.number('control_sombrero');
    final caraInput = sm.number('cara') ?? sm.number('control_cara');
    final cuerpoInput = sm.number('cuerpo') ?? sm.number('control_cuerpo');

    sombreroInput?.value = widget.sombrero.toDouble();
    caraInput?.value = widget.cosmetico.toDouble();
    cuerpoInput?.value = widget.traje.toDouble();

    // Reiniciar conteo de frames para recongelar
    _frameCount = 0;
    setState(() {});
    _scheduleFreeze();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      // Placeholder mientras carga
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00F2FF),
            ),
          ),
        ),
      );
    }

    // Envolver en RepaintBoundary para aislar el repintado.
    // Cuando _frozen es true, el widget deja de actualizarse visualmente
    // porque no se llama a setState, reduciendo el consumo de recursos en scroll.
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: IgnorePointer(
          child: RiveWidget(controller: _controller!),
        ),
      ),
    );
  }
}
