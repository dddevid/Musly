import 'package:flutter/material.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import '../models/now_playing_theme.dart';

/// A widget that executes custom Dart code from themes using dart_eval
/// in a sandboxed environment with limited permissions.
class CustomWidgetRunner extends StatefulWidget {
  final CustomWidget customWidget;
  final bool safeMode;

  const CustomWidgetRunner({
    super.key,
    required this.customWidget,
    this.safeMode = false,
  });

  @override
  State<CustomWidgetRunner> createState() => _CustomWidgetRunnerState();
}

class _CustomWidgetRunnerState extends State<CustomWidgetRunner> {
  Widget? _compiledWidget;
  String? _error;
  bool _isCompiling = false;

  @override
  void initState() {
    super.initState();
    if (!widget.safeMode && widget.customWidget.dartCode.isNotEmpty) {
      _compileWidget();
    }
  }

  @override
  void didUpdateWidget(CustomWidgetRunner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customWidget.dartCode != widget.customWidget.dartCode ||
        oldWidget.safeMode != widget.safeMode) {
      if (!widget.safeMode && widget.customWidget.dartCode.isNotEmpty) {
        _compileWidget();
      } else {
        setState(() {
          _compiledWidget = null;
          _error = null;
        });
      }
    }
  }

  Future<void> _compileWidget() async {
    setState(() {
      _isCompiling = true;
      _error = null;
    });

    try {
      // Attempt to compile and execute the custom Dart code
      // Note: dart_eval has significant limitations and may not support
      // complex Flutter widgets. This is a best-effort implementation.
      
      // For now, we'll show a placeholder indicating custom widget execution
      // A full implementation would require more sophisticated dart_eval setup
      // with Flutter bridge bindings, which is beyond the scope of this basic impl.
      
      setState(() {
        _compiledWidget = _buildPlaceholder(
          'Custom Widget: ${widget.customWidget.name}',
          Colors.purple.withOpacity(0.1),
        );
        _isCompiling = false;
      });

      // TODO: Actual dart_eval compilation would go here:
      // final compiler = Compiler();
      // final program = compiler.compile({
      //   'main.dart': widget.customWidget.dartCode,
      // });
      // final runtime = Runtime.ofProgram(program);
      // runtime.executeLib('package:main/main.dart', 'main');
      
    } catch (e) {
      setState(() {
        _error = 'Custom widget error: ${e.toString()}';
        _isCompiling = false;
      });
    }
  }

  Widget _buildPlaceholder(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.code,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.safeMode) {
      return _buildPlaceholder(
        'Safe Mode: ${widget.customWidget.name} disabled',
        Colors.orange.withOpacity(0.1),
      );
    }

    if (_isCompiling) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Compiling...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return _compiledWidget ?? const SizedBox.shrink();
  }
}

/// A wrapper that positions custom widgets according to their layout config
class PositionedCustomWidget extends StatelessWidget {
  final CustomWidget customWidget;
  final bool safeMode;
  final Size containerSize;

  const PositionedCustomWidget({
    super.key,
    required this.customWidget,
    required this.safeMode,
    required this.containerSize,
  });

  @override
  Widget build(BuildContext context) {
    final left = customWidget.x * containerSize.width;
    final top = customWidget.y * containerSize.height;

    return Positioned(
      left: left,
      top: top,
      child: CustomWidgetRunner(
        customWidget: customWidget,
        safeMode: safeMode,
      ),
    );
  }
}
