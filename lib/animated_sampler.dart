// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef SamplerBuilder = void Function(ui.Image, Size, Offset offset, ui.Canvas);

class AnimatedSampler extends StatelessWidget {
  const AnimatedSampler(this.builder, {
    required this.child,
    super.key,
    this.enabled = true,
  });

  final SamplerBuilder builder;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _ShaderSamplerImpl(
      builder,
      enabled: enabled,
      child: child,
    );
  }
}

class _ShaderSamplerImpl extends SingleChildRenderObjectWidget {
  const _ShaderSamplerImpl(this.builder, { super.child, required this.enabled });

  final SamplerBuilder builder;
  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderShaderSamplerBuilderWidget(
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      builder: builder,
      enabled: enabled,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderShaderSamplerBuilderWidget)
      ..devicePixelRatio = MediaQuery.of(context).devicePixelRatio
      ..builder = builder
      ..enabled = enabled;
  }
}


// A render object that conditionally converts its child into a [ui.Image]
// and then paints it in place of the child.
class _RenderShaderSamplerBuilderWidget extends RenderProxyBox {
  // Create a new [_RenderSnapshotWidget].
  _RenderShaderSamplerBuilderWidget({
    required double devicePixelRatio,
    required SamplerBuilder builder,
    required bool enabled,
  }) : _devicePixelRatio = devicePixelRatio,
       _builder = builder,
       _enabled = enabled;


  /// The device pixel ratio used to create the child image.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    if (_childRaster == null) {
      return;
    } else {
      _childRaster?.dispose();
      _childRaster = null;
      markNeedsPaint();
    }
  }

  /// The painter used to paint the child snapshot or child widgets.
  SamplerBuilder get builder => _builder;
  SamplerBuilder _builder;
  set builder(SamplerBuilder value) {
    if (value == builder) {
      return;
    }
    _builder = value;
    markNeedsPaint();
  }

  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (value == enabled) {
      return;
    }
    _enabled = value;
    markNeedsPaint();
  }

  ui.Image? _childRaster;

  @override
  void detach() {
    _childRaster?.dispose();
    _childRaster = null;
    super.detach();
  }

  @override
  void dispose() {
    _childRaster?.dispose();
    _childRaster = null;
    super.dispose();
  }

  // Paint [child] with this painting context, then convert to a raster and detach all
  // children from this layer.
  ui.Image? _paintAndDetachToImage() {
    final offsetLayer = OffsetLayer();
    final context = PaintingContext(offsetLayer, Offset.zero & size);
    super.paint(context, Offset.zero);
    // This ignore is here because this method is protected by the `PaintingContext`. Adding a new
    // method that performs the work of `_paintAndDetachToImage` would avoid the need for this, but
    // that would conflict with our goals of minimizing painting context.
    // ignore: invalid_use_of_protected_member
    context.stopRecordingIfNeeded();
    final image = offsetLayer.toImageSync(Offset.zero & size, pixelRatio: devicePixelRatio);
    offsetLayer.dispose();
    return image;
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) {
      _childRaster?.dispose();
      _childRaster = null;
      return;
    }

    if (!enabled) {
      _childRaster?.dispose();
      _childRaster = null;
      return super.paint(context, offset);
    }
    _childRaster?.dispose();
    _childRaster = _paintAndDetachToImage();
    builder(_childRaster!, size, offset, context.canvas);

  }
}
