import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A missing or expired shop image never hides the goal itself.
class GoalProductThumbnail extends StatelessWidget {
  const GoalProductThumbnail({super.key, this.url, this.size = 40});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: AppColors.tealSoft,
      child: Center(
        child: Icon(
          Icons.flag_outlined,
          color: AppColors.tealInk,
          size: size * .6,
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? fallback
            : Image.network(
                url!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (_, child, loading) =>
                    loading == null ? child : fallback,
              ),
      ),
    );
  }
}
