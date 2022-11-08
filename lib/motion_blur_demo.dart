import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:scroll_experiments/shader_builder.dart';

final Float64List _identity = Matrix4.identity().storage;


class MotionBlurDemoWidget extends StatefulWidget {
  const MotionBlurDemoWidget({super.key});

  @override
  State<MotionBlurDemoWidget> createState() => _GlowWidgetState();
}

class _GlowWidgetState extends State<MotionBlurDemoWidget> {
  ui.Image? barcelos;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    getBarcelos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getBarcelos() async {
    const assetImage = AssetImage('assets/image.jpg');
    final key = await assetImage.obtainKey(ImageConfiguration.empty);
    final completer = assetImage
      .loadBuffer(key, PaintingBinding.instance.instantiateImageCodecFromBuffer);
    completer.addListener(ImageStreamListener((image, synchronousCall) {
      setState(() {
        barcelos = image.image;
      });
    }));
  }

  double delta = 0;

  void handleVerticalDragUpdate(DragUpdateDetails details, double height) {
    final exp = details.localPosition.dy / height;
    final exx = 10 ^ (1000 * exp).ceil();

    setState(() {
      delta= 1 / exx;
    });
  }

  @override
  Widget build(BuildContext context) {
    final barcelos = this.barcelos;

    if (barcelos == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AspectRatio(
        aspectRatio: barcelos.width/ barcelos.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onVerticalDragUpdate: (details) => handleVerticalDragUpdate(details, constraints.maxHeight),
              child: ShaderBuilder(
                builder: (BuildContext context, ui.FragmentShader shader, Widget? child) {
                shader
                  ..setFloat(0, delta)
                  ..setFloat(1, pi / 2)
                  ..setFloat(2, barcelos.width.toDouble())
                  ..setFloat(3, barcelos.height.toDouble())
                ..setSampler(0, ui.ImageShader(barcelos, TileMode.clamp, TileMode.clamp, _identity));
                  return CustomPaint(
                    painter: ImagePainter(shader),
                  );
                },
                assetKey: 'shaders/motion_blur.glsl',
              ),
            );
          }
        ),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  ImagePainter(this.shader);

  final ui.FragmentShader shader;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
