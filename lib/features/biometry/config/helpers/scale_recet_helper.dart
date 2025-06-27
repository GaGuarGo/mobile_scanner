import 'dart:ui';

Rect scaleRect({
  required Rect rect,
  required Size imageSize,
  required Size widgetSize,
}) {
  final double scaleX = widgetSize.width / imageSize.width;
  final double scaleY = widgetSize.height / imageSize.height;

  return Rect.fromLTRB(
    rect.left * scaleX,
    rect.top * scaleY,
    rect.right * scaleX,
    rect.bottom * scaleY,
  );
}
