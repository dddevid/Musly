import 'dart:math';
import 'package:flutter/material.dart';

class FantasyScreen extends StatefulWidget {
  const FantasyScreen({super.key});

  @override
  State<FantasyScreen> createState() => _FantasyScreenState();
}

class _FantasyScreenState extends State<FantasyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Position of the top-left corner of the image
  double _x = 100;
  double _y = 100;

  // Speed in logical pixels per frame (at 60 fps ≈ 2.5 px/frame)
  double _dx = 2.8;
  double _dy = 2.1;

  // Current rotation angle in radians
  double _angle = 0;

  // Size of the bouncing image
  static const double _imgSize = 120;

  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _dx = (rng.nextDouble() * 2 + 2) * (rng.nextBool() ? 1 : -1);
    _dy = (rng.nextDouble() * 2 + 1.5) * (rng.nextBool() ? 1 : -1);
    _angle = rng.nextDouble() * 2 * pi;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // effectively infinite
    )..addListener(_onTick);

    _controller.forward();
  }

  void _onTick() {
    final now = DateTime.now();
    final dt =
        now.difference(_lastTick).inMicroseconds /
        16666.0; // relative to 60 fps
    _lastTick = now;

    final size = context.size;
    if (size == null) return;

    final maxX = size.width - _imgSize;
    final maxY = size.height - _imgSize;

    double nx = _x + _dx * dt;
    double ny = _y + _dy * dt;
    double ndx = _dx;
    double ndy = _dy;
    double na = _angle;
    bool bounced = false;

    if (nx <= 0) {
      nx = 0;
      ndx = _dx.abs();
      bounced = true;
    } else if (nx >= maxX) {
      nx = maxX;
      ndx = -_dx.abs();
      bounced = true;
    }

    if (ny <= 0) {
      ny = 0;
      ndy = _dy.abs();
      bounced = true;
    } else if (ny >= maxY) {
      ny = maxY;
      ndy = -_dy.abs();
      bounced = true;
    }

    if (bounced) {
      // Rotate on bounce: pick a snappy increment (90–150°)
      final rng = Random();
      final increment = (pi / 2) + rng.nextDouble() * (pi / 3);
      na = na + increment * (rng.nextBool() ? 1 : -1);
    }

    setState(() {
      _x = nx;
      _y = ny;
      _dx = ndx;
      _dy = ndy;
      _angle = na;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            left: _x,
            top: _y,
            child: Transform.rotate(
              angle: _angle,
              child: Image.asset(
                'assets/fanta-sy.png',
                width: _imgSize,
                height: _imgSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
