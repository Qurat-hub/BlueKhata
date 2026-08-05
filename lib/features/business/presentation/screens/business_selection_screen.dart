import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/business_providers.dart';

class BusinessSelectionScreen extends ConsumerWidget {
  const BusinessSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(myBusinessesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Businesses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createBusiness),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('New Business'),
      ),
      body: businessesAsync.when(
        loading: () => const AppLoading(),
        error: (e, st) => AppErrorState(
          message: 'Could not load your businesses.\n$e',
          onRetry: () => ref.invalidate(myBusinessesProvider),
        ),
        data: (businesses) {
          if (businesses.isEmpty) {
            return AppEmptyState(
              icon: Icons.store_mall_directory_rounded,
              title: 'No businesses yet',
              subtitle: 'Create your first business to start tracking your ledger.',
              actionLabel: 'Create Business',
              onAction: () => context.push(AppRoutes.createBusiness),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myBusinessesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: businesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = businesses[i];
                return AppCard(
                  onTap: () {
                    ref.read(activeBusinessProvider.notifier).state = b;
                    context.go(AppRoutes.dashboard);
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: b.logoUrl != null ? NetworkImage(b.logoUrl!) : null,
                        child: b.logoUrl == null
                            ? Text(b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('${b.businessType} • ${b.currency}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
