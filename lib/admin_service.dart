import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupFileInfo {
  const BackupFileInfo({
    required this.path,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
    required this.reason,
  });

  final String path;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
  final String reason;
}

class PersonnelImportResult {
  const PersonnelImportResult({
    required this.rows,
    required this.path,
  });

  final List<Map<String, String>> rows;
  final String path;
}

class AdminService {
  static const String backupFormat = 'c4-harchuvannya-backup-v1';
  static const String importFileName = 'C4_personnel_import.csv';

  Future<Directory> _baseDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}C4 Harchuvannya',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _backupDirectory() async {
    final root = await _baseDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}Backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _exportDirectory() async {
    Directory? downloads;
    try {
      downloads = await getDownloadsDirectory();
    } catch (_) {
      downloads = null;
    }
    if (downloads != null) {
      if (!await downloads.exists()) await downloads.create(recursive: true);
      return downloads;
    }
    final root = await _baseDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}Export');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _editableTemplateFile() async {
    final root = await _baseDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}Шаблони');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}Моя_тестова_сторінка.docx');
  }

  Future<BackupFileInfo> createBackup({
    required Map<String, dynamic> snapshot,
    String reason = 'manual',
  }) async {
    final dir = await _backupDirectory();
    final now = DateTime.now();
    final template = await _editableTemplateFile();
    final prefs = await SharedPreferences.getInstance();

    final templateExists = await template.exists();
    final payload = <String, dynamic>{
      'format': backupFormat,
      'createdAt': now.toIso8601String(),
      'reason': reason,
      'app': snapshot,
      'reportPreferences': <String, dynamic>{
        'report_settings_v08': prefs.getString('report_settings_v08'),
        'report_layout_v084': prefs.getString('report_layout_v084'),
        'report_history_v08': prefs.getString('report_history_v08'),
      },
      'editableTemplatePresent': templateExists,
      'editableTemplateBase64': templateExists
          ? base64Encode(await template.readAsBytes())
          : null,
    };

    final stamp = _stamp(now);
    final file = File('${dir.path}${Platform.pathSeparator}backup_$stamp.json');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload), flush: true);
    return BackupFileInfo(
      path: file.path,
      fileName: file.uri.pathSegments.last,
      createdAt: now,
      sizeBytes: await file.length(),
      reason: reason,
    );
  }

  Future<List<BackupFileInfo>> listBackups() async {
    final dir = await _backupDirectory();
    final result = <BackupFileInfo>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) continue;
      DateTime createdAt = (await entity.stat()).modified;
      var reason = 'manual';
      try {
        final raw = jsonDecode(await entity.readAsString());
        if (raw is Map) {
          createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '') ?? createdAt;
          reason = raw['reason']?.toString() ?? reason;
        }
      } catch (_) {}
      result.add(BackupFileInfo(
        path: entity.path,
        fileName: entity.uri.pathSegments.last,
        createdAt: createdAt,
        sizeBytes: await entity.length(),
        reason: reason,
      ));
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<Map<String, dynamic>> restoreBackup(String path) async {
    final file = File(path);
    if (!await file.exists()) throw StateError('Файл резервної копії не знайдено.');
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) throw FormatException('Некоректний файл резервної копії.');
    final payload = Map<String, dynamic>.from(decoded);
    if (payload['format']?.toString() != backupFormat) {
      throw FormatException('Непідтримуваний формат резервної копії.');
    }

    final reportPrefs = payload['reportPreferences'];
    if (reportPrefs is Map) {
      final prefs = await SharedPreferences.getInstance();
      for (final key in <String>[
        'report_settings_v08',
        'report_layout_v084',
        'report_history_v08',
      ]) {
        final value = reportPrefs[key];
        if (value == null) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, value.toString());
        }
      }
    }

    final template = await _editableTemplateFile();
    final templatePresent = payload['editableTemplatePresent'] == true;
    final template64 = payload['editableTemplateBase64']?.toString() ?? '';
    if (templatePresent && template64.isNotEmpty) {
      await template.writeAsBytes(base64Decode(template64), flush: true);
    } else if (!templatePresent && await template.exists()) {
      await template.delete();
    }

    final app = payload['app'];
    if (app is! Map) throw FormatException('У backup немає даних застосунку.');
    return Map<String, dynamic>.from(app);
  }

  Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<String> openBackupFolder() async {
    final dir = await _backupDirectory();
    if (Platform.isWindows) {
      await Process.start('explorer.exe', <String>[dir.path]);
    } else if (Platform.isMacOS) {
      await Process.start('open', <String>[dir.path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', <String>[dir.path]);
    } else {
      await OpenFilex.open(dir.path);
    }
    return dir.path;
  }

  Future<String> exportPersonnelCsv(List<Map<String, String>> rows) async {
    final dir = await _exportDirectory();
    final now = DateTime.now();
    final file = File(
      '${dir.path}${Platform.pathSeparator}C4_personnel_export_${_stamp(now)}.csv',
    );
    final buffer = StringBuffer('\uFEFFid;rank;name;group\r\n');
    for (final row in rows) {
      buffer
        ..write(_csv(row['id'] ?? ''))
        ..write(';')
        ..write(_csv(row['rank'] ?? ''))
        ..write(';')
        ..write(_csv(row['name'] ?? ''))
        ..write(';')
        ..write(_csv(row['group'] ?? ''))
        ..write('\r\n');
    }
    await file.writeAsString(buffer.toString(), flush: true);
    return file.path;
  }

  Future<String> prepareImportCsv(List<Map<String, String>> rows) async {
    final dir = await _exportDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$importFileName');
    final buffer = StringBuffer('\uFEFFid;rank;name;group\r\n');
    for (final row in rows) {
      buffer
        ..write(_csv(row['id'] ?? ''))
        ..write(';')
        ..write(_csv(row['rank'] ?? ''))
        ..write(';')
        ..write(_csv(row['name'] ?? ''))
        ..write(';')
        ..write(_csv(row['group'] ?? ''))
        ..write('\r\n');
    }
    await file.writeAsString(buffer.toString(), flush: true);
    await OpenFilex.open(file.path);
    return file.path;
  }

  Future<PersonnelImportResult> readImportCsv() async {
    final dir = await _exportDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$importFileName');
    if (!await file.exists()) {
      throw StateError('Не знайдено $importFileName. Спочатку створи файл імпорту.');
    }
    var text = await file.readAsString();
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) throw FormatException('CSV порожній.');
    final header = _parseCsvLine(lines.first).map((e) => e.trim().toLowerCase()).toList();
    const required = <String>['id', 'rank', 'name', 'group'];
    for (final key in required) {
      if (!header.contains(key)) throw FormatException('У CSV немає колонки $key.');
    }

    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final values = _parseCsvLine(lines[i]);
      final row = <String, String>{};
      for (var c = 0; c < header.length; c++) {
        row[header[c]] = c < values.length ? values[c].trim() : '';
      }
      if ((row['name'] ?? '').isNotEmpty) rows.add(row);
    }
    return PersonnelImportResult(rows: rows, path: file.path);
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == ';' && !quoted) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }

  static String _csv(String value) {
    if (!value.contains(';') && !value.contains('"') && !value.contains('\n') && !value.contains('\r')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _stamp(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}_'
      '${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}'
      '${value.second.toString().padLeft(2, '0')}';
}
