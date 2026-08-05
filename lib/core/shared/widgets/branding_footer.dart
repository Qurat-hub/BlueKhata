import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';

/// "Powered by Zenvyro Labs" footer.
///
/// Required on the Splash Screen and Dashboard footer per branding
/// guidelines — see BRANDING.md. Do not remove.
class BrandingFooter extends StatelessWidget {
  final bool light;
  const BrandingFooter({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white70 : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            AppConfig.poweredByLabel,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
