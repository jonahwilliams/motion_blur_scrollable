import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:flutter_shaders/flutter_shaders.dart';

final Float64List _identity = Matrix4.identity().storage;

class ScrollableBlur extends StatefulWidget {
  const ScrollableBlur({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ScrollableBlur> createState() => _ScrollableBlurState();
}

class _ScrollableBlurState extends State<ScrollableBlur> {
  ui.Image? image;
  int lastTS = DateTime.now().millisecondsSinceEpoch;
  double lastPixels = 0;

  double blurAmount = 0;
  double blurAngle = pi / 2;

  bool onScrollNotification(ScrollMetricsNotification notification) {
    if (notification.depth != 0) {
      return false;
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final deltaT = ts - lastTS;
    if (deltaT < 12) return false;
    final pixels = notification.metrics.pixels;

    if (notification.metrics.atEdge) {
      setState(() {
        blurAmount = 0.0;
      });
    } else {
      setState(() {
        final deltaPixels = (pixels - lastPixels).abs();
        final velo = deltaPixels / (deltaT * 0.0001);
        blurAmount = velo > 1.0 ? deltaPixels : 0.0;
        blurAngle = notification.metrics.axis == Axis.horizontal ? pi : pi / 2;
      });
    }

    lastTS = ts;
    lastPixels = pixels;

    Timer(
      const Duration(milliseconds: 16),
      afterScrollCheck,
    );

    return false;
  }

  void afterScrollCheck() {
    if (blurAmount == 0.0) {
      return;
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final deltaT = ts - lastTS;

    if (deltaT >= 16) {
      setState(() {
        blurAmount = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: onScrollNotification,
      child: ShaderBuilder(
        (BuildContext context, ui.FragmentShader shader, Widget? child) {
          return AnimatedSampler(
            (ui.Image image, Size size, Offset offset, Canvas canvas) {
            final imageShader = ui.ImageShader(
              image,
              TileMode.clamp,
              TileMode.clamp,
              _identity,
            );
            shader
              ..setFloat(0, blurAmount)
              ..setFloat(1, blurAngle)
              ..setFloat(2, size.width)
              ..setFloat(3, size.height)
              ..setSampler(0, imageShader);
              canvas
                ..translate(offset.dx, offset.dy)
                ..drawRect(
                Offset.zero & size,
                Paint()..shader = shader,
              );
            },
            enabled: blurAmount > 50,
            child: widget.child,
          );
        },
        assetKey: 'shaders/motion_blur.glsl',
      ),
    );
  }
}
