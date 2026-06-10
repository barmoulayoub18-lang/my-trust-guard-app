import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

enum ButtonType { primary, outline, ghost }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
    this.height = 52,
    this.borderRadius = 16,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: widget.height,
        width: double.infinity,

        transform: Matrix4.identity()
          ..scale(isPressed ? 0.96 : 1.0),

        decoration: BoxDecoration(
          gradient: widget.type == ButtonType.primary
              ? AppColors.primaryGradient
              : null,

          color: widget.type == ButtonType.outline
              ? Colors.transparent
              : widget.type == ButtonType.ghost
                  ? (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04))
                  : null,

          borderRadius: BorderRadius.circular(widget.borderRadius),

          border: widget.type == ButtonType.outline
              ? Border.all(color: AppColors.primary, width: 1.2)
              : null,

          boxShadow: widget.type == ButtonType.primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: isPressed ? 10 : 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),

        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: isDisabled ? null : widget.onPressed,
            child: Center(child: buildContent(isDark)),
          ),
        ),
      ),
    );
  }

  Widget buildContent(bool isDark) {
    if (widget.isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.type == ButtonType.primary
                ? Colors.white
                : AppColors.primary,
          ),
        ),
      );
    }

    final textColor = widget.type == ButtonType.primary
        ? Colors.white
        : AppColors.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Row(
        key: ValueKey(widget.text),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 20,
              color: textColor,
            ),
            const SizedBox(width: 10),
          ],
          Text(
            widget.text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}