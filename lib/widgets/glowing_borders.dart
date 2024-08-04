import 'package:flutter/material.dart';

class GlowingBorders extends StatefulWidget {
  final Color color;

  const GlowingBorders({Key? key, required this.color}) : super(key: key);

  @override
  _GlowingBordersState createState() => _GlowingBordersState();
}

class _GlowingBordersState extends State<GlowingBorders> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: _buildGlowingBorder(true),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: _buildGlowingBorder(false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlowingBorder(bool isLeft) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            widget.color.withOpacity(0),
            widget.color.withOpacity(_animation.value * 0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(_animation.value * 0.7),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }
}
