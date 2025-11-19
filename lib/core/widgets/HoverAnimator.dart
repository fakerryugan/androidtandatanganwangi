import 'package:flutter/material.dart';

class HoverAnimator extends StatefulWidget {
  final Widget child;

  const HoverAnimator({Key? key, required this.child}) : super(key: key);

  @override
  _HoverAnimatorState createState() => _HoverAnimatorState();
}

class _HoverAnimatorState extends State<HoverAnimator> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0, // Sedikit membesar saat hover
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
