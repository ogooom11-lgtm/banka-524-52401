import 'package:intl/intl.dart';

/// Tüm uygulamada kullanılan Türkçe biçimlendirme yardımcıları.
class Fmt {
  Fmt._();

  static final Map<String, NumberFormat> _decimalCache = {};

  static NumberFormat _decimal(int digits) {
    final cached = _decimalCache['d$digits'];
    if (cached != null) return cached;
    NumberFormat format;
    try {
      format = NumberFormat.decimalPatternDigits(
        locale: 'tr_TR',
        decimalDigits: digits,
      );
    } catch (_) {
      // Yerel veri yüklenmemişse (ör. test ortamı) güvenli geri dönüş.
      format = NumberFormat.decimalPatternDigits(
        locale: 'en_US',
        decimalDigits: digits,
      );
    }
    _decimalCache['d$digits'] = format;
    return format;
  }

  /// Türkçe tarih biçimi; yerel veri yoksa İngilizce kalıba düşer.
  static String _pattern(DateTime d, String pattern) {
    try {
      return DateFormat(pattern, 'tr_TR').format(d);
    } catch (_) {
      try {
        return DateFormat(pattern).format(d);
      } catch (_) {
        return d.toIso8601String();
      }
    }
  }

  /// 12345.5 -> "12.345,50 ₺" (para birimi konumu ayarlanabilir)
  static String money(
    double value,
    String currency, {
    int digits = 2,
    bool symbolAfter = true,
    bool signed = false,
    bool compact = false,
  }) {
    final safe = value.isFinite ? value : 0.0;
    String body;
    if (compact && safe.abs() >= 1000000) {
      body = '${(safe / 1000000).toStringAsFixed(2)} Mn';
    } else if (compact && safe.abs() >= 10000) {
      body = '${(safe / 1000).toStringAsFixed(1)} B';
    } else {
      body = _decimal(digits.clamp(0, 4)).format(safe);
    }
    if (signed && safe > 0) body = '+$body';
    return symbolAfter ? '$body $currency' : '$currency $body';
  }

  /// Kısa sayı gösterimi (grafikler ve etiketler için).
  static String short(double value) {
    final v = value.isFinite ? value : 0.0;
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} Mn';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)} B';
    return v.toStringAsFixed(0);
  }

  static String number(num value, {int digits = 0}) =>
      _decimal(digits).format(value);

  static String percent(double value, {int digits = 1}) =>
      '%${value.toStringAsFixed(digits).replaceAll('.', ',')}';

  static String date(DateTime d) => _pattern(d, 'dd.MM.yyyy');

  static String dateTime(DateTime d) => _pattern(d, 'dd.MM.yyyy HH:mm');

  static String dateLong(DateTime d) => _pattern(d, 'd MMMM yyyy, EEEE');

  static String month(DateTime d) => _pattern(d, 'MMMM yyyy');

  static String monthShort(DateTime d) => _pattern(d, 'MMM');

  static String clock(DateTime d) => _pattern(d, 'HH:mm');

  /// "3 gün önce", "12 dakika önce" gibi okunabilir zaman farkı.
  static String ago(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 30) return '${diff.inDays} gün önce';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} ay önce';
    return '${(diff.inDays / 365).floor()} yıl önce';
  }

  static String duration(int days) {
    if (days <= 0) return 'süresi doldu';
    if (days < 31) return '$days gün';
    final months = (days / 30).floor();
    if (months < 12) return '$months ay';
    final years = (days / 365);
    return '${years.toStringAsFixed(1)} yıl'.replaceAll('.', ',');
  }

  /// Kullanıcı girdisini sayıya çevirir: "1.250,75" -> 1250.75
  static double? parseAmount(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(' ', '').replaceAll('₺', '').replaceAll('\u00A0', '');
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      // Son görülen ayırıcı ondalıktır.
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  static int? parseInt(String raw) => int.tryParse(raw.trim());

  static String initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String firstLetter(String word) {
      if (word.isEmpty) return '';
      return String.fromCharCode(word.runes.first);
    }

    if (parts.length == 1) {
      final word = parts.first;
      final take = word.runes.length >= 2 ? 2 : 1;
      return String.fromCharCodes(word.runes.take(take)).toUpperCase();
    }
    return '${firstLetter(parts.first)}${firstLetter(parts.last)}'.toUpperCase();
  }
}
