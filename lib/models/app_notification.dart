import 'package:flutter/material.dart';

enum NotifyKind {
  salary('Maaş', Icons.payments_outlined, Color(0xFF10B981)),
  bonus('Prim', Icons.card_giftcard, Color(0xFF8B5CF6)),
  penalty('Ceza', Icons.warning_amber_rounded, Color(0xFFF59E0B)),
  contract('Sözleşme', Icons.description_outlined, Color(0xFF3B82F6)),
  risk('Risk', Icons.gpp_maybe_outlined, Color(0xFFEF4444)),
  info('Bilgi', Icons.notifications_none, Color(0xFF64748B));

  final String label;
  final IconData icon;
  final Color color;
  const NotifyKind(this.label, this.icon, this.color);

  static NotifyKind fromName(String? name) {
    for (final k in NotifyKind.values) {
      if (k.name == name) return k;
    }
    return NotifyKind.info;
  }
}

/// Uygulama içi bildirim merkezi kaydı.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotifyKind kind;
  final DateTime date;
  bool isRead;
  final String? userId; // null => tüm yöneticiler

  AppNotification({
    required this.id,
    required this.title,
    this.body = '',
    this.kind = NotifyKind.info,
    required this.date,
    this.isRead = false,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'kind': kind.name,
        'date': date.toIso8601String(),
        'isRead': isRead,
        'userId': userId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? 'ntf-0',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        kind: NotifyKind.fromName(json['kind']?.toString()),
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
        userId: json['userId']?.toString(),
      );
}
