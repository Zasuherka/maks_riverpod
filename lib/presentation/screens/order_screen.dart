import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maks_riverpod/presentation/providers/cart_provider.dart';
import 'package:maks_riverpod/presentation/providers/order_provider.dart';
import 'package:maks_riverpod/router/app_router.dart';

// =============================================================================
// ДЕМО: ConsumerWidget + StreamProvider (watch на поток данных)
// =============================================================================
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() на StreamProvider — получаем AsyncValue<OrderStatus>.
    // Каждый раз когда поток отдаёт новое значение — виджет перестраивается.
    //
    // orderStatusProvider(orderId) — family вызов:
    // создаёт/возвращает провайдер для конкретного orderId
    final statusAsync = ref.watch(orderStatusProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статус заказа'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
          data: (currentStatus) =>
              _OrderTimeline(currentStatus: currentStatus, orderId: orderId),
        ),
      ),
    );
  }
}

class _OrderTimeline extends ConsumerWidget {
  const _OrderTimeline({required this.currentStatus, required this.orderId});

  final OrderStatus currentStatus;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = OrderStatus.values;
    final currentIndex = statuses.indexOf(currentStatus);
    final isDone = currentStatus == OrderStatus.ready;

    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          'Заказ #$orderId',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 32),

        // Timeline статусов
        ...statuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isPassed = index <= currentIndex;
          final isCurrent = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPassed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: isCurrent && !isDone
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isPassed ? '✓' : status.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isPassed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),

        const Spacer(),

        if (isDone) ...[
          Text(
            '${OrderStatus.ready.emoji} Ваш заказ готов!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // ref.read() в коллбеке — правильно
              ref.read(cartProvider.notifier).clear();
              ref.read(activeOrderIdProvider.notifier).clear();
              // context.go() — переходим на корень, заменяя весь стек.
              // Аналог Navigator.popUntil((r) => r.isFirst), но декларативно.
              context.go(AppRoutes.home);
            },
            child: const Text('Отлично! На главную'),
          ),
        ],
      ],
    );
  }
}
