import 'package:flutter/material.dart';
import 'state_widgets.dart';

/// Generic "not built yet" destination for KHATA/PAYMENTS/MORE tiles whose
/// feature module (repository/provider/screen) hasn't been implemented in
/// this build pass. Routed to via [AppRoutes.comingSoon] so every tile on
/// the dashboard has a real, working navigation target instead of a no-op
/// `onTap: () {}`.
///
/// Replace the call site's route with the real feature screen once that
/// module's repository/provider/screen trio is built — no other change
/// needed since navigation always goes through GoRouter.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyState(
        icon: icon,
        title: title,
        subtitle: 'This module is next on the roadmap — coming in the next build pass.',
      ),
    );
  }
}
