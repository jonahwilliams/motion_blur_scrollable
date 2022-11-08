import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

typedef ShaderBuilderCallback = Widget Function(BuildContext, ui.FragmentShader, Widget?);

class ShaderBuilder extends StatefulWidget {
  const ShaderBuilder({
    super.key,
    required this.builder,
    required this.assetKey,
    this.child,
  });

  final String assetKey;
  final Widget? child;
  final ShaderBuilderCallback builder;

  @override
  State<StatefulWidget> createState() {
    return _ShaderBuilderState();
  }

  static Future<void> precacheShader(String assetKey) {
    return ui.FragmentProgram.fromAsset(assetKey).then((ui.FragmentProgram program) {
     _ShaderBuilderState._shaderCache[assetKey] = program;
    }, onError: (Object error, StackTrace stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace));
    });
  }
}

class _ShaderBuilderState extends State<ShaderBuilder> {
  ui.FragmentProgram? program;
  ui.FragmentShader? shader;

  static final Map<String, ui.FragmentProgram> _shaderCache = <String, ui.FragmentProgram>{};

  @override
  void initState() {
    super.initState();
    _loadShader(widget.assetKey);
  }

  @override
  void didUpdateWidget(covariant ShaderBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetKey != widget.assetKey) {
      _loadShader(widget.assetKey);
    }
  }

  void _loadShader(String assetKey) {
    if (_shaderCache.containsKey(assetKey)) {
      program = _shaderCache[assetKey];
      shader = program!.fragmentShader();
      return;
    }

    StackTrace? debugStack;
    assert(() {
      debugStack = StackTrace.current;
      return true;
    }());

    ui.FragmentProgram.fromAsset(assetKey).then((ui.FragmentProgram program) {
      if (!mounted) {
        return;
      }
      setState(() {
        this.program = program;
        shader = program.fragmentShader();
        _shaderCache[assetKey] = program;
      });
    }, onError: (Object error, StackTrace stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: debugStack ?? stackTrace));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (shader == null) {
      return widget.child ?? const SizedBox.shrink();
    }
    return widget.builder(context, shader!, widget.child);
  }
}
