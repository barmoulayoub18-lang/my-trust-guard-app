import 'dart:ui';
import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;

  final Gradient? gradient;
  final Color? color;

  final double padding;
  final double borderRadius;

  final EdgeInsets? margin;
  final bool hasShadow;

  const CustomCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.child,
    this.onTap,
    this.gradient,
    this.color,
    this.padding = 16,
    this.borderRadius = 20,
    this.margin,
    this.hasShadow = true,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        widget.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final textPrimary = isDark ? Colors.white : Colors.black87;

    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: widget.margin,
          padding: EdgeInsets.all(widget.padding),
          transform: Matrix4.identity()
            ..scale(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0)),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.gradient == null ? backgroundColor : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: widget.hasShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                      blurRadius: isHovered ? 25 : 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isDark ? 6 : 0,
                sigmaY: isDark ? 6 : 0,
              ),
              child: _buildContent(
                textPrimary,
                textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color textPrimary, Color textSecondary) {
    if (widget.child != null) {
      return widget.child!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.icon != null || widget.title != null)
          Row(
            children: [
              if (widget.icon != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF4A47A3),
                      ],
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              if (widget.icon != null) const SizedBox(width: 12),
              if (widget.title != null)
                Expanded(
                  child: Text(
                    widget.title!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
