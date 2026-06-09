import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures an on-screen [RepaintBoundary] (identified by [boundaryKey]) to a
/// high-resolution PNG and hands it to the Android share sheet.
abstract class ShareService {
  static Future<void> shareBoundary(
    GlobalKey boundaryKey, {
    String text = '',
  }) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) return;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/aura_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
