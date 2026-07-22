// Compose the wide Voltron wordmark logo onto a square, opaque dark canvas
// so it can be used as an app launcher icon (which must be square).
// Usage: dart run tool/generate_app_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logo = img.decodePng(File('assets/images/voltron_logo.png').readAsBytesSync())!;

  const canvasSize = 1024;

  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0x0A, 0x0A, 0x0F, 255));

  const marginRatio = 0.17;
  final maxWidth = (canvasSize * (1 - marginRatio * 2)).round();
  final scale = maxWidth / logo.width;
  final resized = img.copyResize(logo, width: maxWidth, height: (logo.height * scale).round());

  final offsetX = (canvasSize - resized.width) ~/ 2;
  final offsetY = (canvasSize - resized.height) ~/ 2;
  img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);

  File('assets/images/app_icon.png').writeAsBytesSync(img.encodePng(canvas));
  // ignore: avoid_print
  print('Wrote assets/images/app_icon.png (${canvasSize}x$canvasSize)');
}
