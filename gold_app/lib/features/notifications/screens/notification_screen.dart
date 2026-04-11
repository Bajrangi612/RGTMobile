import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/shimmer_loader.dart';
import '../presentation/providers/notification_provider.dart';
import '../data/models/notification_model.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: AppColors.royalGold),
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.darkGrey),
                    ),
                    const SizedBox(height: 16),
                    Text('No new notifications', style: AppTextStyles.h4.copyWith(color: AppColors.grey)),
                    const SizedBox(height: 8),
                    Text('We\'ll alert you here for any updates', style: AppTextStyles.caption),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(notificationsProvider),
              color: AppColors.royalGold,
              backgroundColor: AppColors.cardDark,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationItem(notification: notification)
                      .animate(delay: (index * 50).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.05);
                },
              ),
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 8,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerLoader.orderCard(),
            ),
          ),
          error: (err, __) => Center(
            child: Text('Error loading notifications: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'ORDER_STATUS':
        icon = Icons.local_shipping_rounded;
        color = AppColors.info;
        break;
      case 'PRICE_ALERT':
        icon = Icons.trending_up_rounded;
        color = AppColors.royalGold;
        break;
      case 'REWARD':
        icon = Icons.card_giftcard_rounded;
        color = AppColors.success;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.royalGold;
    }

    return GoldCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      hasGoldBorder: !notification.isRead,
      onTap: () async {
        if (!notification.isRead) {
          await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          ref.invalidate(notificationsProvider);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: notification.isRead ? AppColors.pureWhite.withValues(alpha: 0.7) : AppColors.pureWhite,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.royalGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: notification.isRead ? AppColors.grey : AppColors.pureWhite.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.relativeTime(notification.createdAt.toIso8601String()),
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
