import 'dart:async';
import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double pauseDuration;
  final double scrollVelocity;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.pauseDuration = 2.0,
    this.scrollVelocity = 30.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _needsScroll = false;
  double _textWidth = 0;
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNeedScroll());
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _stopScroll();
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkNeedScroll());
    }
  }

  void _checkNeedScroll() {
    if (!mounted) return;

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    _textWidth = textPainter.width;

    if (context.size != null) {
      _containerWidth = context.size!.width;

      setState(() {
        _needsScroll = _textWidth > _containerWidth;
      });

      if (_needsScroll) {
        _startScroll();
      }
    }
  }

  void _startScroll() {
    _stopScroll();

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    _timer = Timer(
        Duration(milliseconds: (widget.pauseDuration * 1000).toInt()), _scroll);
  }

  void _scroll() async {
    if (!mounted || !_scrollController.hasClients || !_needsScroll) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final durationInSeconds = maxScrollExtent / widget.scrollVelocity;

    await _scrollController.animateTo(
      maxScrollExtent,
      duration: Duration(milliseconds: (durationInSeconds * 1000).toInt()),
      curve: Curves.linear,
    );

    if (!mounted) return;

    await Future.delayed(
        Duration(milliseconds: (widget.pauseDuration * 1000).toInt()));

    if (!mounted) return;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
      _startScroll();
    }
  }

  void _stopScroll() {
    _timer?.cancel();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
            ),
            if (_needsScroll) const SizedBox(width: 40),
          ],
        ),
      );
    });
  }
}
