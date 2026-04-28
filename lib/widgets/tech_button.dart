import 'package:flutter/material.dart';
import 'package:workflow_app/config/theme.dart';

/// 科技风按钮
class TechButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final TechButtonStyle style;
  final bool isLoading;
  final double? width;
  final double height;

  const TechButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.style = TechButtonStyle.primary,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  State<TechButton> createState() => _TechButtonState();
}

enum TechButtonStyle {
  primary,   // 电光青
  success,   // 矩阵绿
  warning,   // 能量黄
  danger,    // 警示红
  secondary, // 次级
  sakura,    // 霓虹紫（sakura专属）
}

class _TechButtonState extends State<TechButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    if (widget.onPressed == null) {
      return TechTheme.starGrayBlue.withOpacity(0.5);
    }
    switch (widget.style) {
      case TechButtonStyle.primary:
        return TechTheme.electricCyan;
      case TechButtonStyle.success:
        return TechTheme.matrixGreen;
      case TechButtonStyle.warning:
        return TechTheme.energyYellow;
      case TechButtonStyle.danger:
        return TechTheme.warningRed;
      case TechButtonStyle.secondary:
        return Colors.transparent;
      case TechButtonStyle.sakura:
        return TechTheme.neonPurple;
    }
  }

  Color get _foregroundColor {
    if (widget.onPressed == null) {
      return TechTheme.silverGray;
    }
    switch (widget.style) {
      case TechButtonStyle.primary:
      case TechButtonStyle.success:
      case TechButtonStyle.warning:
      case TechButtonStyle.sakura:
        return TechTheme.deepSpaceBlue;
      case TechButtonStyle.danger:
        return Colors.white;
      case TechButtonStyle.secondary:
        return TechTheme.electricCyan;
    }
  }

  Color get _borderColor {
    if (widget.onPressed == null) {
      return TechTheme.starGrayBlue;
    }
    switch (widget.style) {
      case TechButtonStyle.primary:
        return TechTheme.electricCyan;
      case TechButtonStyle.success:
        return TechTheme.matrixGreen;
      case TechButtonStyle.warning:
        return TechTheme.energyYellow;
      case TechButtonStyle.danger:
        return TechTheme.warningRed;
      case TechButtonStyle.secondary:
        return TechTheme.electricCyan;
      case TechButtonStyle.sakura:
        return TechTheme.neonPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _borderColor,
            width: widget.style == TechButtonStyle.secondary ? 1.5 : 0,
          ),
          boxShadow: widget.onPressed != null && !_isPressed
              ? [
                  BoxShadow(
                    color: _borderColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        transform: _isPressed
            ? (Matrix4.identity()..scale(0.98))
            : Matrix4.identity(),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: _foregroundColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: _foregroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 科技风图标按钮
class TechIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final bool showGlow;

  const TechIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? TechTheme.electricCyan;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: showGlow && onPressed != null
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          color: onPressed != null ? iconColor : TechTheme.starGrayBlue,
          size: size,
        ),
      ),
    );
  }
}
