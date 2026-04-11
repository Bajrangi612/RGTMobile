import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/network/api_service.dart';

// Repository
class NotificationRepository {
  final Dio _dio = ApiService().dio;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      final data = response.data['data']['notifications'] as List;
      return data.map((n) => NotificationModel.fromJson(n)).toList();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> markAsRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.put('/notifications/read-all');
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.post('/notifications/token', data: {'token': token});
  }
}

// Provider
final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return await ref.watch(notificationRepositoryProvider).getNotifications();
});

// Unread Count Provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
