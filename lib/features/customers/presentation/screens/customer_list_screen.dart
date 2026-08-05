import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_card.dart';
import '../../../../core/shared/widgets/state_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_providers.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addEditCustomer),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => ref.read(customerSearchQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const AppLoading(),
              error: (e, st) => AppErrorState(
                message: 'Failed to load customers.\n$e',
                onRetry: () => ref.invalidate(customerListProvider),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No customers yet',
                    subtitle: 'Add your first customer to start recording transactions.',
                    actionLabel: 'Add Customer',
                    onAction: () => context.push(AppRoutes.addEditCustomer),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(customerListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _CustomerTile(customer: customers[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final balanceColor = customer.currentBalance == 0
        ? AppColors.textSecondary
        : (customer.owesYou ? AppColors.danger : AppColors.success);

    return AppCard(
      onTap: () => context.push('/customers/${customer.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: customer.imageUrl != null ? NetworkImage(customer.imageUrl!) : null,
            child: customer.imageUrl == null
                ? Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                        child: Text(customer.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                    if (customer.isFavorite) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                    ],
                  ],
                ),
                if (customer.phone != null)
                  Text(customer.phone!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                customer.currentBalance.abs().toStringAsFixed(0),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: balanceColor),
              ),
              Text(
                customer.currentBalance == 0
                    ? 'Settled'
                    : (customer.owesYou ? 'To Receive' : 'To Pay'),
                style: TextStyle(fontSize: 10, color: balanceColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
