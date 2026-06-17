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
    this.height = 50,
    this.borderRadius = 12,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.fastOutSlowIn,
        height: widget.height,
        width: double.infinity,
        transform: Matrix4.identity()..scale(isPressed ? 0.97 : 1.0),
        decoration: BoxDecoration(
          gradient: widget.type == ButtonType.primary
              ? AppColors.primaryGradient
              : null,
          color: widget.type == ButtonType.outline
              ? Colors.transparent
              : widget.type == ButtonType.ghost
                  ? AppColors.textSecondary.withOpacity(0.06)
                  : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.type == ButtonType.outline
              ? Border.all(color: AppColors.border, width: 1.5)
              : null,
          boxShadow: widget.type == ButtonType.primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: isPressed ? 8 : 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: isDisabled ? null : widget.onPressed,
            child: Center(child: buildContent()),
          ),
        ),
      ),
    );
  }

  Widget buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
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
        : widget.type == ButtonType.outline
            ? AppColors.textPrimary
            : AppColors.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Row(
        key: ValueKey(widget.text),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 18,
              color: textColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}