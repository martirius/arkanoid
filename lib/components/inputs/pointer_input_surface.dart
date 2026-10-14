import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;

class PointerInputSurface extends PositionComponent
    with DragCallbacks, HoverCallbacks, TapCallbacks {
  PointerInputSurface({
    required this.onMoveTo,
    required this.onAction,
  }) : super(priority: -1);

  final void Function(Vector2 canvasPosition) onMoveTo;
  final void Function() onAction;

  @override
  void onPointerMove(PointerMoveEvent event) {
    super.onPointerMove(event);
    onMoveTo(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    onMoveTo(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    onMoveTo(event.canvasEndPosition);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (event.deviceKind == PointerDeviceKind.mouse) {
      onAction();
    } else {
      onMoveTo(event.canvasPosition);
    }
  }
}
