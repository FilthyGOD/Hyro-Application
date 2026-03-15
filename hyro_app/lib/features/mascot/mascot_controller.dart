import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

/// Centralized controller for the Rive mascot animation.
/// Shared between FocusScreen (idle/studying) and ShopScreen (purchase/equip).
class MascotController extends ChangeNotifier {
  Artboard? _artboard;
  StateMachineController? _smController;

  // Triggers
  SMITrigger? _triggerSaludo;
  SMITrigger? _triggerEstudiando;
  SMITrigger? _triggerCompra;
  SMITrigger? _triggerVolver;

  // Inputs
  SMINumber? _shopItemId;
  SMINumber? _sombrero;
  SMINumber? _cara;
  SMINumber? _cuerpo;

  Timer? _idleTimer;
  final _random = Random();
  bool _isStudying = false;

  Artboard? get artboard => _artboard;
  bool get isLoaded => _artboard != null;

  MascotController() {
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    await RiveFile.initialize();

    final data = await rootBundle.load('assets/mascot/jairo20.riv');
    final file = RiveFile.import(data);
    final artboard = file.mainArtboard.instance();

    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );

    if (controller != null) {
      artboard.addController(controller);
      _smController = controller;

      // Resolve triggers
      _triggerSaludo =
          controller.findInput<bool>('trigger_saludo') as SMITrigger?;
      _triggerEstudiando =
          controller.findInput<bool>('trigger_estudiando') as SMITrigger?;
      _triggerCompra =
          controller.findInput<bool>('trigger_compra') as SMITrigger?;
      _triggerVolver = controller.findInput<bool>('volver') as SMITrigger?;

      // Resolve number inputs (with fallback names just in case)
      _shopItemId = controller.findInput<double>('shop_item_id') as SMINumber?;
      _sombrero =
          (controller.findInput<double>('sombrero') ??
                  controller.findInput<double>('control_sombrero'))
              as SMINumber?;
      _cara =
          (controller.findInput<double>('cara') ??
                  controller.findInput<double>('control_cara'))
              as SMINumber?;
      _cuerpo =
          (controller.findInput<double>('cuerpo') ??
                  controller.findInput<double>('control_cuerpo'))
              as SMINumber?;

      if (_sombrero == null) print('WARNING: Rive input "sombrero" not found!');
      if (_cara == null) print('WARNING: Rive input "cara" not found!');
      if (_cuerpo == null) print('WARNING: Rive input "cuerpo" not found!');
    }

    _artboard = artboard;
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

  void triggerVolver() {
    _isStudying = false;
    _triggerVolver?.fire();
    _startIdleLoop();
  }

  void triggerCompra(int itemId) {
    _shopItemId?.value = itemId.toDouble();
    _triggerCompra?.fire();
  }

  void setSombrero(int id) {
    print('Sending sombrero ID $id to Rive');
    _sombrero?.value = id.toDouble();
  }

  void setCara(int id) {
    print('Sending cara ID $id to Rive');
    _cara?.value = id.toDouble();
  }

  void setCuerpo(int id) {
    print('Sending cuerpo ID $id to Rive');
    _cuerpo?.value = id.toDouble();
  }

  @override
  void dispose() {
    _cancelIdleLoop();
    _smController?.dispose();
    super.dispose();
  }
}
