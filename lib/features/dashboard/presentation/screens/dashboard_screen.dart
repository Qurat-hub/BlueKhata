import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/branding_footer.dart';
import '../../../../core/shared/widgets/coming_soon_screen.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../customers/presentation/screens/customer_list_screen.dart';
import '../../../calculator/presentation/screens/calculator_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(activeBusinessProvider);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _DashboardHome(businessName: business?.name ?? 'BlueKhata'),
            const CustomerListScreen(),
            const _PlaceholderTab(title: 'Reports', icon: Icons.bar_chart_rounded),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

/// Home tab body — structured to match DigiKhata's home screen exactly:
/// header row → Team/Staff promo banner → KHATA grid (Party/Cash/Stock/
/// Bills/Staff/Expense) → PAYMENTS tiles (POS/QR) → MORE row, in
/// BlueKhata's blue palette instead of DigiKhata's orange.
class _DashboardHome extends ConsumerWidget {
  final String businessName;
  const _DashboardHome({required this.businessName});

  void _openComingSoon(BuildContext context, {required String title, required IconData icon}) {
    context.push(
      AppRoutes.comingSoon,
      extra: ComingSoonScreen(title: title, icon: icon),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HomeHeader(businessName: businessName),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaffBanner(
                  onManageStaff: () => context.push(AppRoutes.staffBook),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('KHATA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.6,
                            color: AppColors.textSecondary)),
                    InkWell(
                      onTap: () => _openComingSoon(
                        context,
                        title: 'Dashboard Reports',
                        icon: Icons.bar_chart_rounded,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('View Dashboard',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      _KhataTile(
                        icon: Icons.person_rounded,
                        label: 'Party',
                        onTap: () => context.push(AppRoutes.customers),
                      ),
                      _KhataTile(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Cash',
                        onTap: () => context.push(AppRoutes.cashbook),
                      ),
                      _KhataTile(
                        icon: Icons.inventory_2_rounded,
                        label: 'Stock',
                        onTap: () => context.push(AppRoutes.stock),
                      ),
                      _KhataTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Bills',
                        onTap: () => context.push(AppRoutes.billBook),
                      ),
                      _KhataTile(
                        icon: Icons.badge_rounded,
                        label: 'Staff',
                        onTap: () => context.push(AppRoutes.staffBook),
                      ),
                      _KhataTile(
                        icon: Icons.payments_rounded,
                        label: 'Expense',
                        onTap: () => context.push(AppRoutes.expenseBook),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('PAYMENTS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentTile(
                        icon: Icons.point_of_sale_rounded,
                        title: 'POS',
                        subtitle: 'Accept card payments on your phone.',
                        gradient: AppColors.posGradient,
                        onTap: () => _openComingSoon(
                          context,
                          title: 'POS',
                          icon: Icons.point_of_sale_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PaymentTile(
                        icon: Icons.qr_code_rounded,
                        title: 'QR',
                        subtitle: 'Share your QR and get paid.',
                        gradient: AppColors.qrGradient,
                        onTap: () => context.push(AppRoutes.qr),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('MORE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MoreItem(
                          icon: Icons.devices_rounded,
                          label: 'Multi Devices',
                          onTap: () => _openComingSoon(
                            context,
                            title: 'Multi Devices',
                            icon: Icons.devices_rounded,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _MoreItem(
                          icon: Icons.badge_outlined,
                          label: 'Business Card',
                          onTap: () => _openComingSoon(
                            context,
                            title: 'Business Card',
                            icon: Icons.badge_outlined,
                          ),
                        ),
                      ),
                      Expanded(
                        child:_MoreItem(
                          icon: Icons.calculate_rounded,
                          label: 'Calculator',
                          onTap: () => context.push(AppRoutes.calculator),
                        ),
                      ),
                    ],
                  ),
                ),
                const BrandingFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Top header row: hamburger + business name dropdown, then
/// crown (subscription) / bell (notifications) / grid (all apps) icons —
class _HomeHeader extends StatelessWidget {
  final String businessName;
  const _HomeHeader({required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.push(AppRoutes.businessSelection),
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          ),
          Expanded(
            child: InkWell(
              onTap: () => context.push(AppRoutes.businessSelection),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      businessName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Subscription',
            onPressed: () => context.push(
              AppRoutes.comingSoon,
              extra: const ComingSoonScreen(title: 'Subscription', icon: Icons.workspace_premium_rounded),
            ),
            icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.warning),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push(
              AppRoutes.comingSoon,
              extra: const ComingSoonScreen(title: 'Notifications', icon: Icons.notifications_none_rounded),
            ),
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
          ),
          IconButton(
            tooltip: 'All Apps',
            onPressed: () => context.push(
              AppRoutes.comingSoon,
              extra: const ComingSoonScreen(title: 'All Apps', icon: Icons.apps_rounded),
            ),
            icon: const Icon(Icons.apps_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// "Team / Staff Management" promo banner — first section under the header
class _StaffBanner extends StatelessWidget {
  final VoidCallback onManageStaff;
  const _StaffBanner({required this.onManageStaff});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.staffBannerGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Staff Management',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Manage your team & salaries',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onManageStaff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Manage Staff', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Icon(Icons.groups_2_rounded, color: Colors.white24, size: 56),
        ],
      ),
    );
  }
}

/// Single icon tile inside the 2x3 KHATA grid (Party/Cash/Stock/Bills/
/// Staff/Expense).
class _KhataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _KhataTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.khataTileBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Large gradient tile for the PAYMENTS section (POS / QR).
class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Single item in the MORE row (Multi Devices / Business Card / Calculator).
class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MoreItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: 'This module is next on the roadmap — coming in the next build pass.',
    );
  }
}
