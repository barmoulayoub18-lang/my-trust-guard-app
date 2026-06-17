import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class LoadingWidget extends StatefulWidget {
  final String? text;
  final bool isFullScreen;

  const LoadingWidget({
    super.key,
    this.text,
    this.isFullScreen = false,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildLoader() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: _controller.value,
                strokeWidth: 3.5,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE2E8F0)),
              ),
            ),
            Transform.rotate(
              angle: _controller.value * 2 * pi,
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircularProgressIndicator(
                    value: 0.3,
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            ),
            ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0)
                  .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildLoader(),
        if (widget.text != null) ...[
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.text!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A).withOpacity(0.3),
        body: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.9, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 28,
              ),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
              child: buildContent(),
            ),
          ),
        ),
      );
    }

    return Center(child: buildContent());
  }
}