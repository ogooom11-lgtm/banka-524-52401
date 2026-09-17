import 'package:flutter/material.dart';

enum LogLevel {
  info('Bilgi', Icons.info_outline, Color(0xFF3B82F6)),
  success('Başarılı', Icons.check_circle_outline, Color(0xFF10B981)),
  warning('Uyarı', Icons.warning_amber_rounded, Color(0xFFF59E0B)),
  danger('Kritik', Icons.error_outline, Color(0xFFEF4444));

  final String label;
  final IconData icon;
  final Color color;
  const LogLevel(this.label, this.icon, this.color);

  static LogLevel fromName(String? name) {
    for (final l in LogLevel.values) {
      if (l.name == name) return l;
    }
    return LogLevel.info;
  }
}

/// Sistem günlüğü — kim, ne zaman, ne yaptı?
class AuditEntry {
  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String detail;
  final LogLevel level;
  final DateTime date;

  AuditEntry({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    this.detail = '',
    this.level = LogLevel.info,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'detail': detail,
        'level': level.name,
        'date': date.toIso8601String(),
      };

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id']?.toString() ?? 'log-0',
        actorId: json['actorId']?.toString() ?? '',
        actorName: json['actorName']?.toString() ?? 'Sistem',
        action: json['action']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        level: LogLevel.fromName(json['level']?.toString()),
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
      );
}
