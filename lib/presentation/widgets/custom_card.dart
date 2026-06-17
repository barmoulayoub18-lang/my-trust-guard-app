import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

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
    this.borderRadius = 12,
    this.margin,
    this.hasShadow = true,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> with SingleTickerProviderStateMixin {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.color ?? AppColors.surface;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          margin: widget.margin,
          padding: EdgeInsets.all(widget.padding),
          transform: Matrix4.identity()
            ..scale(isPressed ? 0.95 : (isHovered ? 1.03 : 1.0)),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.gradient == null ? backgroundColor : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isHovered 
                  ? AppColors.primary.withOpacity(0.2)
                  : const Color(0xFFF1F5F9),
              width: isHovered ? 1.5 : 1.0,
            ),
            boxShadow: widget.hasShadow
                ? [
                    BoxShadow(
                      color: isHovered 
                          ? const Color(0xFF0F172A).withOpacity(0.07)
                          : const Color(0xFF0F172A).withOpacity(0.03),
                      blurRadius: isHovered ? 24 : 14,
                      offset: isHovered ? const Offset(0, 8) : const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 0,
                sigmaY: 0,
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(isHovered ? 0.15 : 0.08),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              if (widget.icon != null) const SizedBox(width: 12),
              if (widget.title != null)
                Expanded(
                  child: Text(
                    widget.title!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
            ],
          ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}