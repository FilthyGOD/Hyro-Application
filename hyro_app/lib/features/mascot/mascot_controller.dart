import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: deprecated_member_use

/// Centralized controller for the Rive mascot animation.
/// Shared between FocusScreen (idle/studying) and ShopScreen (purchase/equip).
class MascotController extends ChangeNotifier {
  File? _file;
  RiveWidgetController? _riveController;

  // Triggers
  TriggerInput? _triggerSaludo;
  TriggerInput? _triggerEstudiando;
  TriggerInput? _triggerHueva;
  TriggerInput? _triggerCompra;
  TriggerInput? _triggerVolver;
  TriggerInput? _triggerCargando;
  TriggerInput? _triggerRacha;
  TriggerInput? _triggerFestejo;
  TriggerInput? _triggerPensando;

  // Inputs
  NumberInput? _shopItemId;
  NumberInput? _sombrero;
  NumberInput? _cara;
  NumberInput? _cuerpo;
  NumberInput? _unidades;
  NumberInput? _decenas;

  Timer? _idleTimer;
  final _random = Random();
  bool _isStudying = false;
  bool _isInitialLoad = true;

  bool get isInitialLoad => _isInitialLoad;

  // Track the genuinely equipped items
  int equippedSombrero = 100;
  int equippedCara = 200;
  int equippedCuerpo = 300;

  RiveWidgetController? get controller => _riveController;
  bool get isLoaded => _riveController != null;

  MascotController() {
    _initPrefsAndLoadRive();
  }

  Future<void> _initPrefsAndLoadRive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      equippedSombrero = prefs.getInt('equipped_sombrero') ?? 100;
      equippedCara = prefs.getInt('equipped_cara') ?? 200;
      equippedCuerpo = prefs.getInt('equipped_cuerpo') ?? 300;
    } catch (e) {
      debugPrint('Error loading prefs: $e');
    }
    await _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    final file = await File.asset(
      'assets/mascot/jairo44.riv',
      riveFactory: Factory.flutter,
    );

    if (file == null) {
      debugPrint('ERROR: Could not load Rive file jairo44.riv');
      return;
    }

    _file = file;

    final riveController = RiveWidgetController(
      file,
      stateMachineSelector: const StateMachineNamed('State Machine 1'),
    );

    _riveController = riveController;
    final sm = riveController.stateMachine;

    // Resolve triggers
    _triggerSaludo = sm.trigger('trigger_saludo');
    _triggerEstudiando = sm.trigger('trigger_estudiando');
    _triggerHueva = sm.trigger('trigger_hueva');
    _triggerCompra = sm.trigger('trigger_compra');
    _triggerVolver = sm.trigger('volver');
    _triggerCargando = sm.trigger('trigger_cargando');
    _triggerRacha = sm.trigger('trigger_racha');
    _triggerFestejo = sm.trigger('trigger_festejo');
    _triggerPensando = sm.trigger('trigger_pensando');

    // Resolve number inputs
    _shopItemId = sm.number('shop_item_id');
    _sombrero = sm.number('sombrero') ?? sm.number('control_sombrero');
    _cara = sm.number('cara') ?? sm.number('control_cara');
    _cuerpo = sm.number('cuerpo') ?? sm.number('control_cuerpo');
    _unidades = sm.number('unidades');
    _decenas = sm.number('decenas');

    if (_sombrero == null)
      debugPrint('WARNING: Rive input "sombrero" not found!');
    if (_cara == null) debugPrint('WARNING: Rive input "cara" not found!');
    if (_cuerpo == null) debugPrint('WARNING: Rive input "cuerpo" not found!');
    if (_unidades == null)
      debugPrint('WARNING: Rive input "unidades" not found!');
    if (_decenas == null)
      debugPrint('WARNING: Rive input "decenas" not found!');

    notifyListeners();

    // No restauramos el equipamiento aquí para que la animación inicial 'cargando'
    // se mantenga sin cosméticos. Se restaurarán al llamar a triggerVolver().

    // Start the idle greeting loop
    _startIdleLoop();
  }

  // ── Idle Loop ──────────────────────────────────────────
  void _startIdleLoop() {
    _cancelIdleLoop();
    if (_isStudying) return;

    final delay = Duration(seconds: 15 + _random.nextInt(11)); // 15-25s
    _idleTimer = Timer(delay, () {
      if (!_isStudying) {
        triggerSaludo();
        _startIdleLoop(); // schedule next
      }
    });
  }

  void _cancelIdleLoop() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  // ── Public API ─────────────────────────────────────────
  void triggerSaludo() {
    _triggerSaludo?.fire();
  }

  void triggerEstudiando() {
    _isStudying = true;
    _cancelIdleLoop();
    // Restablecer contadores antes de estudiar
    _unidades?.value = 0;
    _decenas?.value = 0;
    _triggerEstudiando?.fire();
  }

  Future<void> triggerPensando() async {
    _cancelIdleLoop();
    _triggerVolver?.fire();
    await Future.delayed(const Duration(milliseconds: 550));
    _isStudying = true;
    _triggerPensando?.fire();
  }

  Future<void> resumeEstudio() async {
    _triggerVolver?.fire();
    await Future.delayed(const Duration(milliseconds: 50));
    triggerEstudiando();
  }

  Future<void> triggerHueva() async {
    _isStudying = true;
    _cancelIdleLoop();
    await Future.delayed(const Duration(milliseconds: 50));
    _triggerHueva?.fire();
  }

  Future<void> triggerVolver() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _isStudying = false;
    _unidades?.value = 0;
    _decenas?.value = 0;
    _triggerVolver?.fire();

    // Al volver al estado idle, nos aseguramos de que los cosméticos estén puestos
    restoreEquippedState();
    _startIdleLoop();
  }

  void triggerCargando() {
    _cancelIdleLoop();
    // Clear cosmetics for cargando animation
    _sombrero?.value = 0;
    _cara?.value = 0;
    _cuerpo?.value = 0;
    _triggerCargando?.fire();
  }

  // CORRECCIÓN CLAVE: Usar async/await para dar tiempo a la máquina de estados
  Future<void> triggerRacha(int streak) async {
    debugPrint(
      '🔥 [MascotController] triggerRacha iniciado con streak: $streak',
    );
    //await Future.delayed(const Duration(milliseconds: 200));
    _triggerVolver?.fire(); // Return to movimiento_suave first

    // Damos un pequeño respiro de 50ms para que Rive procese la transición 'volver'
    // antes de inyectarle la nueva animación.
    //await Future.delayed(const Duration(milliseconds: 50));

    final valUnidades = (streak % 10).toDouble();
    final valDecenas = (streak ~/ 10).toDouble();

    debugPrint(
      '🔥 [MascotController] Rive Inputs -> Unidades: $valUnidades, Decenas: $valDecenas',
    );

    _unidades?.value = valUnidades;
    _decenas?.value = valDecenas;

    _triggerRacha?.fire();
    debugPrint('🔥 [MascotController] Animación de Racha disparada!');
  }

  // CORRECCIÓN CLAVE: Igual que en triggerRacha
  Future<void> triggerFestejo() async {
    //_cancelIdleLoop();
    _triggerVolver?.fire();

    await Future.delayed(const Duration(milliseconds: 550));
    _triggerFestejo?.fire();
  }

  void markInitialLoadComplete() {
    _isInitialLoad = false;
  }

  void triggerCompra(int itemId) {
    _shopItemId?.value = itemId.toDouble();
    _triggerCompra?.fire();
  }

  Future<void> setSombrero(int id) async {
    debugPrint('Sending sombrero ID $id to Rive');
    equippedSombrero = id;
    _sombrero?.value = id.toDouble();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('equipped_sombrero', id);
    } catch (_) {}
  }

  void previewSombrero(int id) {
    _sombrero?.value = id.toDouble();
  }

  Future<void> setCara(int id) async {
    debugPrint('Sending cara ID $id to Rive');
    equippedCara = id;
    _cara?.value = id.toDouble();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('equipped_cara', id);
    } catch (_) {}
  }

  void previewCara(int id) {
    _cara?.value = id.toDouble();
  }

  Future<void> setCuerpo(int id) async {
    debugPrint('Sending cuerpo ID $id to Rive');
    equippedCuerpo = id;
    _cuerpo?.value = id.toDouble();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('equipped_cuerpo', id);
    } catch (_) {}
  }

  void previewCuerpo(int id) {
    _cuerpo?.value = id.toDouble();
  }

  void restoreEquippedState() {
    _sombrero?.value = equippedSombrero.toDouble();
    _cara?.value = equippedCara.toDouble();
    _cuerpo?.value = equippedCuerpo.toDouble();
  }

  @override
  void dispose() {
    _cancelIdleLoop();
    _triggerSaludo?.dispose();
    _triggerEstudiando?.dispose();
    _triggerHueva?.dispose();
    _triggerCompra?.dispose();
    _triggerVolver?.dispose();
    _triggerCargando?.dispose();
    _triggerRacha?.dispose();
    _triggerFestejo?.dispose();
    _triggerPensando?.dispose();
    _shopItemId?.dispose();
    _sombrero?.dispose();
    _cara?.dispose();
    _cuerpo?.dispose();
    _unidades?.dispose();
    _decenas?.dispose();
    _riveController?.dispose();
    _file?.dispose();
    super.dispose();
  }
}
