import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

class PointerInputSurface extends PositionComponent
    with DragCallbacks, HoverCallbacks, TapCallbacks, HasVisibility {
  PointerInputSurface({
    required this.onMoveTo,
    required this.onTouchMove,
    required this.onAction,
    required this.touchControlsEnabled,
  }) : super(priority: -1);

  final void Function(Vector2 canvasPosition) onMoveTo;
  final void Function(double horizontalPosition) onTouchMove;
  final void Function() onAction;
  final bool touchControlsEnabled;
  final Vector2 touchAreaPosition = Vector2.zero();
  final Vector2 touchAreaSize = Vector2.zero();
  int? _activeDragPointer;
  bool _activeDragIsMouse = false;

  final Paint _backgroundPaint = Paint()..color = const Color(0xcc111118);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xffff5a1f)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _centerPaint = Paint()
    ..color = const Color(0x88ffffff)
    ..strokeWidth = 2;

  void setTouchArea({required Vector2 position, required Vector2 size}) {
    touchAreaPosition.setFrom(position);
    touchAreaSize.setFrom(size);
  }

  bool acceptsTouchAt(Vector2 canvasPosition) {
    return touchControlsEnabled &&
        touchAreaSize.x > 0 &&
        touchAreaSize.y > 0 &&
        canvasPosition.x >= touchAreaPosition.x &&
        canvasPosition.x <= touchAreaPosition.x + touchAreaSize.x &&
        canvasPosition.y >= touchAreaPosition.y &&
        canvasPosition.y <= touchAreaPosition.y + touchAreaSize.y;
  }

  void _moveTouch(Vector2 canvasPosition) {
    if (touchAreaSize.x <= 0) {
      return;
    }
    final horizontalPosition =
        ((canvasPosition.x - touchAreaPosition.x) / touchAreaSize.x)
            .clamp(0.0, 1.0);
    onTouchMove(horizontalPosition);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!touchControlsEnabled || touchAreaSize.x <= 0 || touchAreaSize.y <= 0) {
      return;
    }
    final rect = Rect.fromLTWH(
      touchAreaPosition.x,
      touchAreaPosition.y,
      touchAreaSize.x,
      touchAreaSize.y,
    );
    final box = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas
      ..drawRRect(box, _backgroundPaint)
      ..drawRRect(box, _borderPaint)
      ..drawLine(
        Offset(rect.center.dx, rect.top + 12),
        Offset(rect.center.dx, rect.bottom - 12),
        _centerPaint,
      );
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    super.onPointerMove(event);
    onMoveTo(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final isMouse = event.deviceKind == PointerDeviceKind.mouse;
    if (_activeDragPointer != null ||
        (!isMouse && !touchControlsEnabled) ||
        (!isMouse && !acceptsTouchAt(event.canvasPosition))) {
      return;
    }
    _activeDragPointer = event.pointerId;
    _activeDragIsMouse = isMouse;
    if (isMouse) {
      onMoveTo(event.canvasPosition);
    } else {
      _moveTouch(event.canvasPosition);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.pointerId == _activeDragPointer) {
      if (_activeDragIsMouse) {
        onMoveTo(event.canvasStartPosition);
      } else {
        _moveTouch(event.canvasStartPosition);
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (event.pointerId == _activeDragPointer) {
      _activeDragPointer = null;
      _activeDragIsMouse = false;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (event.deviceKind == PointerDeviceKind.mouse) {
      onAction();
    } else if (touchControlsEnabled && acceptsTouchAt(event.canvasPosition)) {
      _moveTouch(event.canvasPosition);
    }
  }
}
