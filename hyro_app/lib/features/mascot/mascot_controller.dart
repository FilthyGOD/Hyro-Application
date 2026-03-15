import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Centralized controller for the Rive mascot animation.
/// Shared between FocusScreen (idle/studying) and ShopScreen (purchase/equip).
class MascotController extends ChangeNotifier {
  RiveWidgetController? _riveWidgetController;
  
  // Triggers
  TriggerInput? _triggerSaludo;
  TriggerInput? _triggerEstudiando;
  TriggerInput? _triggerCompra;
  TriggerInput? _triggerVolver;

  // Inputs
  NumberInput? _shopItemId;
  NumberInput? _sombrero;

  Timer? _idleTimer;
  final _random = Random();
  bool _isStudying = false;

  RiveWidgetController? get riveWidgetController => _riveWidgetController;
  bool get isLoaded => _riveWidgetController != null;

  MascotController() {
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    final file = (await File.asset('assets/mascot/jairo16.riv', riveFactory: Factory.rive));
    if (file == null) return;
    
    _riveWidgetController = RiveWidgetController(
      file,
      stateMachineSelector: StateMachineSelector.byName('State Machine 1'),
    );

    final stateMachine = _riveWidgetController!.stateMachine;

    // Resolve triggers
    _triggerSaludo = stateMachine.trigger('trigger_saludo');
    _triggerEstudiando = stateMachine.trigger('trigger_estudiando');
    _triggerCompra = stateMachine.trigger('trigger_compra');
    _triggerVolver = stateMachine.trigger('volver');

    // Resolve number inputs
    _shopItemId = stateMachine.number('shop_item_id');
    _sombrero = stateMachine.number('sombrero');

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
    _sombrero?.value = id.toDouble();
  }

  @override
  void dispose() {
    _cancelIdleLoop();
    _riveWidgetController?.dispose();
    super.dispose();
  }
}
