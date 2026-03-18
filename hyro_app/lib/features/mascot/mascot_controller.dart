import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

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

  // Inputs
  NumberInput? _shopItemId;
  NumberInput? _sombrero;
  NumberInput? _cara;
  NumberInput? _cuerpo;

  Timer? _idleTimer;
  final _random = Random();
  bool _isStudying = false;

  // Track the genuinely equipped items
  int equippedSombrero = 100;
  int equippedCara = 200;
  int equippedCuerpo = 300;

  RiveWidgetController? get controller => _riveController;
  bool get isLoaded => _riveController != null;

  MascotController() {
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    final file = await File.asset(
      'assets/mascot/jairo33.riv',
      riveFactory: Factory.flutter,
    );

    if (file == null) {
      print('ERROR: Could not load Rive file jairo33.riv');
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

    // Resolve number inputs
    _shopItemId = sm.number('shop_item_id');
    _sombrero = sm.number('sombrero') ?? sm.number('control_sombrero');
    _cara = sm.number('cara') ?? sm.number('control_cara');
    _cuerpo = sm.number('cuerpo') ?? sm.number('control_cuerpo');

    if (_sombrero == null) print('WARNING: Rive input "sombrero" not found!');
    if (_cara == null) print('WARNING: Rive input "cara" not found!');
    if (_cuerpo == null) print('WARNING: Rive input "cuerpo" not found!');

    notifyListeners();

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
    _triggerEstudiando?.fire();
  }

  void triggerHueva() {
    _isStudying = true;
    _cancelIdleLoop();
    _triggerHueva?.fire();
  }

  void triggerVolver() {
    _isStudying = false;
    _triggerVolver?.fire();
    restoreEquippedState(); // Restore original items
    _startIdleLoop();
  }

  void triggerCompra(int itemId) {
    _shopItemId?.value = itemId.toDouble();
    _triggerCompra?.fire();
  }

  void setSombrero(int id) {
    print('Sending sombrero ID $id to Rive');
    equippedSombrero = id;
    _sombrero?.value = id.toDouble();
  }

  void previewSombrero(int id) {
    _sombrero?.value = id.toDouble();
  }

  void setCara(int id) {
    print('Sending cara ID $id to Rive');
    equippedCara = id;
    _cara?.value = id.toDouble();
  }

  void previewCara(int id) {
    _cara?.value = id.toDouble();
  }

  void setCuerpo(int id) {
    print('Sending cuerpo ID $id to Rive');
    equippedCuerpo = id;
    _cuerpo?.value = id.toDouble();
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
    _shopItemId?.dispose();
    _sombrero?.dispose();
    _cara?.dispose();
    _cuerpo?.dispose();
    _riveController?.dispose();
    _file?.dispose();
    super.dispose();
  }
}
