import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Dosya kaydetme / açma sonucu.
class FileOutcome {
  final bool ok;
  final bool cancelled;
  final String? path;
  final String? message;

  const FileOutcome({
    required this.ok,
    this.cancelled = false,
    this.path,
    this.message,
  });

  static const FileOutcome cancel =
      FileOutcome(ok: false, cancelled: true, message: 'İşlem iptal edildi.');
}

/// Metin dosyası yükleme sonucu.
class TextFileOutcome extends FileOutcome {
  final String? content;
  final String? fileName;

  const TextFileOutcome({
    required super.ok,
    super.cancelled,
    super.path,
    super.message,
    this.content,
    this.fileName,
  });
}

/// CSV / JSON / TXT içe-dışa aktarma yardımcıları (dart:io kullanmaz, web + Windows uyumlu).
class ExportService {
  ExportService._();

  // ------------------------------------------------------------------ CSV
  static String csvEncode(List<List<String>> rows, {String separator = ';'}) {
    return rows.map((row) => row.map((cell) => _escape(cell, separator)).join(separator)).join('\r\n');
  }

  static String _escape(String value, String separator) {
    final needsQuote = value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    final clean = value.replaceAll('"', '""');
    return needsQuote ? '"$clean"' : clean;
  }

  static List<List<String>> csvDecode(String input) {
    if (input.isEmpty) return [];
    final separator = _detectSeparator(input);
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == separator) {
        row.add(cell.toString().trim());
        cell.clear();
      } else if (ch == '\n') {
        row.add(cell.toString().trim());
        cell.clear();
        if (row.any((c) => c.isNotEmpty)) rows.add(row);
        row = <String>[];
      } else if (ch != '\r') {
        cell.write(ch);
      }
    }
    row.add(cell.toString().trim());
    if (row.any((c) => c.isNotEmpty)) rows.add(row);
    return rows;
  }

  static String _detectSeparator(String input) {
    final firstLine = input.split('\n').first;
    final semicolons = ';'.allMatches(firstLine).length;
    final commas = ','.allMatches(firstLine).length;
    final tabs = '\t'.allMatches(firstLine).length;
    if (tabs > semicolons && tabs > commas) return '\t';
    return semicolons >= commas ? ';' : ',';
  }

  /// TXT içeriğini satır listesine çevirir (boş satırlar ayıklanır).
  static List<String> txtToLines(String input) => input
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  static String jsonPretty(Object? data) =>
      const JsonEncoder.withIndent('  ').convert(data);

  // -------------------------------------------------------------- Dosya IO
  static const List<String> jsonExtensions = ['json'];
  static const List<String> csvExtensions = ['csv'];
  static const List<String> txtExtensions = ['txt'];

  /// Metni kullanıcıya dosya olarak kaydettirir.
  static Future<FileOutcome> saveText({
    required String fileName,
    required String content,
    required List<String> extensions,
    String dialogTitle = 'Dosyayı Kaydet',
  }) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: extensions,
        bytes: bytes,
      );
      if (path == null) return FileOutcome.cancel;
      return FileOutcome(ok: true, path: path, message: 'Dosya kaydedildi.');
    } catch (e) {
      return FileOutcome(
        ok: false,
        message: 'Dosya kaydedilemedi: ${_cleanError(e)}',
      );
    }
  }

  /// Kullanıcıdan metin dosyası seçmesini ister ve içeriğini döndürür.
  static Future<TextFileOutcome> pickText({
    List<String>? extensions,
    bool allowAny = false,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowAny || extensions == null
            ? FileType.any
            : FileType.custom,
        allowedExtensions: allowAny ? null : extensions,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        return const TextFileOutcome(ok: false, cancelled: true, message: 'Seçim iptal edildi.');
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        return TextFileOutcome(
          ok: false,
          fileName: file.name,
          message:
              'Dosya okunamadı (içerik yüklenemedi). Lütfen tekrar deneyin.',
        );
      }
      final content = _decodeBytes(bytes);
      return TextFileOutcome(
        ok: true,
        path: file.path,
        fileName: file.name,
        content: content,
        message: 'Dosya yüklendi: ${file.name}',
      );
    } catch (e) {
      return TextFileOutcome(
        ok: false,
        message: 'Dosya açılamadı: ${_cleanError(e)}',
      );
    }
  }

  static String _decodeBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      // UTF-8 değilse: Türkçe karakterler için Windows-1254 yaklaşımı
      final buffer = StringBuffer();
      for (final b in bytes) {
        buffer.writeCharCode(b);
      }
      return buffer.toString();
    }
  }

  static String _cleanError(Object e) => kIsWeb
      ? 'Tarayıcı dosya işlemini engelledi.'
      : e.toString().replaceAll('Exception: ', '');
}
