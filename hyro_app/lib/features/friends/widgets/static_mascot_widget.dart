import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rive/rive.dart';

// ignore_for_file: deprecated_member_use

/// Cache global del archivo Rive para reutilizarlo en multiples instancias.
/// Se carga una sola vez y se comparte entre todos los StaticMascotWidget.
File? _cachedRiveFile;
bool _isLoadingFile = false;

/// Carga el archivo Rive una sola vez y lo cachea.
Future<File?> _loadRiveFileOnce() async {
  if (_cachedRiveFile != null) return _cachedRiveFile;

  if (_isLoadingFile) {
    // Ya se esta cargando, esperar a que termine
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
      'assets/mascot/jairo50.riv',
      riveFactory: kIsWeb ? Factory.rive : Factory.flutter,
    );
  } catch (e) {
    debugPrint('ERROR: No se pudo cargar el archivo Rive para ranking: $e');
  } finally {
    _isLoadingFile = false;
  }
  return _cachedRiveFile;
}

/// Widget que renderiza la mascota Rive con cosmeticos inyectados.
///
/// Crucial para rendimiento en listas (pantalla de amigos):
/// - Usa el mismo archivo .riv cacheado (una sola instancia de File)
/// - Crea un RiveWidgetController independiente por widget
/// - Inyecta los valores de cosmeticos al controlador
/// - La State Machine arranca en el estado "estatico"
///
/// [animated] = false (default): Inyecta cosmeticos y pausa el controlador
///   (_controller.active = false) para que Rive dibuje un solo frame
///   estatico y libere recursos. Ideal para listas de amigos / ranking.
///
/// [animated] = true: Dispara "trigger_continuar" para que la mascota entre
///   en movimiento_suave. Ideal para la pantalla de perfil preview.
class StaticMascotWidget extends StatefulWidget {
  /// Valor de sombrero (ID numerico, ej: 100, 101, 102...)
  final int sombrero;

  /// Valor de cosmetico/cara (ID numerico, ej: 200, 201, 202...)
  /// En la BD es 'cara', en Rive es 'cara'.
  final int cosmetico;

  /// Valor de traje/cuerpo (ID numerico, ej: 300, 301, 302...)
  /// En la BD es 'traje', en Rive es 'cuerpo'.
  final int traje;

  /// Tamano del widget (ancho y alto).
  final double size;

  /// Factor de escala/zoom para hacer al personaje mas grande dentro de su contenedor (default: 1.5).
  final double scale;

  /// Desplazamiento X, Y para centrar la mascota visualmente (default: Offset(0, -2)).
  final Offset offset;

  /// Si es true, la mascota se muestra animada (con trigger "trigger_continuar").
  /// Si es false, se inyectan cosmeticos, se dibuja el frame y se pausa el
  /// controlador para ahorrar recursos.
  final bool animated;

  const StaticMascotWidget({
    super.key,
    required this.sombrero,
    required this.cosmetico,
    required this.traje,
    this.size = 52,
    this.scale = 1.5,
    this.offset = const Offset(0, -2),
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

    // Inyectar valores de cosmeticos.
    // Mapeo: sombrero -> sombrero, cara (BD) -> cara (Rive), traje (BD) -> cuerpo (Rive)
    final sombreroInput =
        sm.number('sombrero') ?? sm.number('control_sombrero');
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

    // La State Machine arranca en "estatico" por defecto.
    if (widget.animated) {
      // Modo animado: dispara trigger_continuar para entrar en movimiento_suave
      _setupAnimatedMode(sm);
    } else {
      // Modo estatico: dispara volver_estatico, espera unos frames para que Rive
      // renderice los cosmeticos en el estado "estatico" y luego pausa el controlador.
      _setupStaticMode(sm);
    }
  }

  /// Modo estatico:
  /// Dispara "volver_estatico" para asegurar que la mascota este en la animacion
  /// estatica. Esperamos unos frames para que Rive aplique los cosmeticos y dibuje
  /// el frame correctamente, luego pausamos el controlador para liberar
  /// recursos del motor de Rive.
  Future<void> _setupStaticMode(StateMachine sm) async {
    final triggerVolverEstatico =
        sm.trigger('volver_estatico') ??
        sm.trigger('trigger_volver_estatico') ??
        sm.trigger('volver');
    triggerVolverEstatico?.fire();

    // Dar tiempo al motor de Rive para procesar el primer frame con cosmeticos y trigger
    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    // Congelar la animacion frame a frame de forma segura
    _scheduleFreeze();
  }

  /// Modo animado:
  /// Dispara "trigger_continuar" para salir de "estatico" y entrar en
  /// "movimiento_suave". La animacion queda corriendo sin pausar.
  Future<void> _setupAnimatedMode(StateMachine sm) async {
    // Pequeno delay para que Rive procese el estado inicial "estatico"
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Disparar trigger_continuar para activar la animacion de movimiento
    final triggerContinuar = sm.trigger('trigger_continuar');
    triggerContinuar?.fire();

    // No pausamos -- dejamos la animacion corriendo
  }

  /// Pausa el controlador de Rive despues de [_frameCount] frames para
  /// asegurar que los cosmeticos esten renderizados antes de detener el motor.
  void _scheduleFreeze() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller == null) return;
      _frameCount++;
      // Esperamos 3 frames para que Rive renderice completamente con cosmeticos
      if (_frameCount >= 3) {
        // Pausar el controlador: el motor de Rive deja de actualizar este widget
        _controller!.active = false;
      } else {
        _scheduleFreeze();
      }
    });
  }

  @override
  void didUpdateWidget(StaticMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambian los cosmeticos, actualizar los inputs y recongelar
    if (oldWidget.sombrero != widget.sombrero ||
        oldWidget.cosmetico != widget.cosmetico ||
        oldWidget.traje != widget.traje) {
      _updateCosmetics();
    }
  }

  void _updateCosmetics() {
    if (_controller == null) return;

    final sm = _controller!.stateMachine;
    final sombreroInput =
        sm.number('sombrero') ?? sm.number('control_sombrero');
    final caraInput = sm.number('cara') ?? sm.number('control_cara');
    final cuerpoInput = sm.number('cuerpo') ?? sm.number('control_cuerpo');

    sombreroInput?.value = widget.sombrero.toDouble();
    caraInput?.value = widget.cosmetico.toDouble();
    cuerpoInput?.value = widget.traje.toDouble();

    final triggerVolverEstatico =
        sm.trigger('volver_estatico') ??
        sm.trigger('trigger_volver_estatico') ??
        sm.trigger('volver');
    triggerVolverEstatico?.fire();

    // Reactivar el controlador para que Rive aplique los nuevos cosmeticos
    _controller!.active = true;

    // Reiniciar conteo de frames para recongelar despues de renderizar
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

    // RepaintBoundary aisla el repintado de cada instancia.
    // Cuando el controlador esta pausado (active = false), el motor de Rive
    // deja de actualizar este subtree, reduciendo el consumo en scroll.
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: IgnorePointer(
          child: Transform.scale(
            scale: widget.scale,
            child: Transform.translate(
              offset: widget.offset,
              child: RiveWidget(controller: _controller!),
            ),
          ),
        ),
      ),
    );
  }
}
