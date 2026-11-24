import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Carte arrondie avec ombre douce (claire) et ripple au toucher.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = 20,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final shape = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x143B3FA0),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: color ?? AppColors.card(context),
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
