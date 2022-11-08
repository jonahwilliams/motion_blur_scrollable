import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'animated_sampler.dart';
import 'shader_builder.dart';

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
  double blueAngle = pi / 2;

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
        blurAmount = velo > 1.0 ? (deltaPixels / 800) : 0.0;
        blueAngle = notification.metrics.axis == Axis.horizontal ? pi : pi / 2;
      });
    }

    lastTS = ts;
    lastPixels = pixels;

    Timer(
      const Duration(milliseconds: 60),
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

    if (deltaT >= 60) {
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
        builder: (BuildContext context, ui.FragmentShader shader, Widget? child) {
          return AnimatedSampler(
            (ui.Image image, Size size, Canvas canvas) {
              shader
              ..setFloat(0, blurAmount)
              ..setFloat(1, pi / 2)
              ..setFloat(2, size.width)
              ..setFloat(3, size.height)
              ..setSampler(0, ui.ImageShader(image, TileMode.clamp, TileMode.clamp, _identity));
              canvas.drawImage(image, Offset.zero, Paint()..shader = shader);
            },
            child: widget.child,
          );
        },
        assetKey: 'shaders/motion_blur.glsl',
      ),
    );
  }
}
