import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;

class PointerInputSurface extends PositionComponent
    with DragCallbacks, HoverCallbacks, TapCallbacks {
  PointerInputSurface({
    required this.onMoveTo,
    required this.onAction,
    required this.acceptsTouchAt,
  }) : super(priority: -1);

  final void Function(Vector2 canvasPosition) onMoveTo;
  final void Function() onAction;
  final bool Function(Vector2 canvasPosition) acceptsTouchAt;
  int? _activeDragPointer;

  @override
  void onPointerMove(PointerMoveEvent event) {
    super.onPointerMove(event);
    onMoveTo(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_activeDragPointer != null ||
        (event.deviceKind != PointerDeviceKind.mouse &&
            !acceptsTouchAt(event.canvasPosition))) {
      return;
    }
    _activeDragPointer = event.pointerId;
    onMoveTo(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.pointerId == _activeDragPointer) {
      onMoveTo(event.canvasStartPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (event.pointerId == _activeDragPointer) {
      _activeDragPointer = null;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (event.deviceKind == PointerDeviceKind.mouse) {
      onAction();
    } else if (acceptsTouchAt(event.canvasPosition)) {
      onMoveTo(event.canvasPosition);
    }
  }
}
