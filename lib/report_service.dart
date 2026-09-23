import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportPersonProfile {
  const ReportPersonProfile({
    required this.shortName,
    required this.fullName,
    required this.fullNameDative,
    required this.fullNameDativeStyled,
    required this.position,
    required this.positionDative,
    required this.rank,
    required this.rankDative,
    required this.rankGenitive,
    required this.surnameGenitiveInitials,
    required this.signatureName,
    required this.group,
  });

  final String shortName;
  final String fullName;
  final String fullNameDative;
  final String fullNameDativeStyled;
  final String position;
  final String positionDative;
  final String rank;
  final String rankDative;
  final String rankGenitive;
  final String surnameGenitiveInitials;
  final String signatureName;
  final String group;

  static ReportPersonProfile fromJson(Map<String, dynamic> map) {
    String s(String key) => map[key]?.toString().trim() ?? '';
    return ReportPersonProfile(
      shortName: s('shortName'),
      fullName: s('fullName'),
      fullNameDative: s('fullNameDative'),
      fullNameDativeStyled: s('fullNameDativeStyled'),
      position: s('position'),
      positionDative: s('positionDative'),
      rank: s('rank'),
      rankDative: s('rankDative'),
      rankGenitive: s('rankGenitive'),
      surnameGenitiveInitials: s('surnameGenitiveInitials'),
      signatureName: s('signatureName'),
      group: s('group'),
    );
  }
}

class ReportSettings {
  const ReportSettings({
    required this.r1Line1,
    required this.r1Line2,
    required this.r2Line1,
    required this.r2Line2,
    required this.r2Line3,
    required this.r2Line4,
    required this.ccPosition,
    required this.ccInstitution,
    required this.ccRank,
    required this.ccName,
    required this.r3Line1,
    required this.r3Line2,
    required this.r3Petition,
    required this.r3Position1,
    required this.r3Position2,
    required this.r3Position3,
    required this.r3Rank,
    required this.r3Name,
    required this.doctorPosition1,
    required this.doctorPosition2,
    required this.doctorRank,
    required this.doctorName,
  });

  final String r1Line1;
  final String r1Line2;
  final String r2Line1;
  final String r2Line2;
  final String r2Line3;
  final String r2Line4;
  final String ccPosition;
  final String ccInstitution;
  final String ccRank;
  final String ccName;
  final String r3Line1;
  final String r3Line2;
  final String r3Petition;
  final String r3Position1;
  final String r3Position2;
  final String r3Position3;
  final String r3Rank;
  final String r3Name;
  final String doctorPosition1;
  final String doctorPosition2;
  final String doctorRank;
  final String doctorName;

  static const defaults = ReportSettings(
    r1Line1: 'Начальнику С4 курсу',
    r1Line2: 'ІСЗЗІ КПІ ім. Ігоря Сікорського',
    r2Line1: 'Першому заступнику начальника',
    r2Line2: 'ІСЗЗІ КПІ ім. Ігоря Сікорського',
    r2Line3: '',
    r2Line4: '',
    ccPosition: 'Начальник С4 курсу',
    ccInstitution: 'ІСЗЗІ КПІ ім. Ігоря Сікорського',
    ccRank: 'підполковник',
    ccName: 'Назар КОРНІЙЧУК',
    r3Line1: 'Начальнику ІСЗЗІ КПІ',
    r3Line2: 'ім. Ігоря Сікорського',
    r3Petition: 'Клопочу по суті рапорту підполковника КОРНІЙЧУКА Н.П.',
    r3Position1: 'Перший заступник начальника',
    r3Position2: 'ІСЗЗІ КПІ ім. Ігоря Сікорського',
    r3Position3: '',
    r3Rank: 'полковник',
    r3Name: 'Олександр ВАСИЛЬЄВ',
    doctorPosition1: 'Лікар 2 кваліфікаційної категорії Амбулаторії',
    doctorPosition2: '',
    doctorRank: 'капітан медичної служби',
    doctorName: 'Анна ВИННИК',
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'r1Line1': r1Line1,
        'r1Line2': r1Line2,
        'r2Line1': r2Line1,
        'r2Line2': r2Line2,
        'r2Line3': r2Line3,
        'r2Line4': r2Line4,
        'ccPosition': ccPosition,
        'ccInstitution': ccInstitution,
        'ccRank': ccRank,
        'ccName': ccName,
        'r3Line1': r3Line1,
        'r3Line2': r3Line2,
        'r3Petition': r3Petition,
        'r3Position1': r3Position1,
        'r3Position2': r3Position2,
        'r3Position3': r3Position3,
        'r3Rank': r3Rank,
        'r3Name': r3Name,
        'doctorPosition1': doctorPosition1,
        'doctorPosition2': doctorPosition2,
        'doctorRank': doctorRank,
        'doctorName': doctorName,
      };

  factory ReportSettings.fromJson(Map<String, dynamic> map) {
    String s(String key, String fallback) =>
        map.containsKey(key) ? map[key]?.toString() ?? '' : fallback;
    const d = defaults;
    return ReportSettings(
      r1Line1: s('r1Line1', d.r1Line1),
      r1Line2: s('r1Line2', d.r1Line2),
      r2Line1: s('r2Line1', d.r2Line1),
      r2Line2: s('r2Line2', d.r2Line2),
      r2Line3: s('r2Line3', d.r2Line3),
      r2Line4: s('r2Line4', d.r2Line4),
      ccPosition: s('ccPosition', d.ccPosition),
      ccInstitution: s('ccInstitution', d.ccInstitution),
      ccRank: s('ccRank', d.ccRank),
      ccName: s('ccName', d.ccName),
      r3Line1: s('r3Line1', d.r3Line1),
      r3Line2: s('r3Line2', d.r3Line2),
      r3Petition: s('r3Petition', d.r3Petition),
      r3Position1: s('r3Position1', d.r3Position1),
      r3Position2: s('r3Position2', d.r3Position2),
      r3Position3: s('r3Position3', d.r3Position3),
      r3Rank: s('r3Rank', d.r3Rank),
      r3Name: s('r3Name', d.r3Name),
      doctorPosition1: s('doctorPosition1', d.doctorPosition1),
      doctorPosition2: s('doctorPosition2', d.doctorPosition2),
      doctorRank: s('doctorRank', d.doctorRank),
      doctorName: s('doctorName', d.doctorName),
    );
  }
}

class MealCompensationDay {
  const MealCompensationDay({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });
  final DateTime day;
  final bool breakfast;
  final bool lunch;
  final bool dinner;

  bool get any => breakfast || lunch || dinner;
  bool get all => breakfast && lunch && dinner;

  List<String> get mealWords => <String>[
        if (breakfast) 'сніданок',
        if (lunch) 'обід',
        if (dinner) 'вечерю',
      ];
}

class CompensationReportPerson {
  const CompensationReportPerson({
    required this.personId,
    required this.group,
    required this.profile,
    required this.days,
  });

  final String personId;
  final String group;
  final ReportPersonProfile profile;
  final List<MealCompensationDay> days;

  int get mealCount => days.fold<int>(
        0,
        (sum, item) =>
            sum + (item.breakfast ? 1 : 0) + (item.lunch ? 1 : 0) + (item.dinner ? 1 : 0),
      );

  String get compensationText => ReportService.formatCompensation(days);
}

class GeneratedReport {
  const GeneratedReport({
    required this.group,
    required this.fileName,
    required this.path,
    required this.personCount,
  });
  final String group;
  final String fileName;
  final String path;
  final int personCount;
}

class ReportHistoryEntry {
  const ReportHistoryEntry({
    required this.time,
    required this.action,
    required this.fileName,
    required this.detail,
  });
  final DateTime time;
  final String action;
  final String fileName;
  final String detail;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'time': time.toIso8601String(),
        'action': action,
        'fileName': fileName,
        'detail': detail,
      };

  factory ReportHistoryEntry.fromJson(Map<String, dynamic> map) =>
      ReportHistoryEntry(
        time: DateTime.tryParse(map['time']?.toString() ?? '') ?? DateTime.now(),
        action: map['action']?.toString() ?? '',
        fileName: map['fileName']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
      );
}

class ReportService {
  ReportService._(this._prefs, this.profiles, this.settings, this.history);

  static const _settingsKey = 'report_settings_v08';
  static const _historyKey = 'report_history_v08';
  static const _templateAsset =
      'assets/templates/report_template.docx';
  static const _profilesAsset = 'assets/data/report_people.json';

  final SharedPreferences _prefs;
  final List<ReportPersonProfile> profiles;
  ReportSettings settings;
  final List<ReportHistoryEntry> history;

  static Future<ReportService> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfiles = jsonDecode(await rootBundle.loadString(_profilesAsset)) as List;
    final profiles = rawProfiles
        .map((dynamic item) =>
            ReportPersonProfile.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    var settings = ReportSettings.defaults;
    final rawSettings = prefs.getString(_settingsKey);
    if (rawSettings != null && rawSettings.isNotEmpty) {
      try {
        settings = ReportSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawSettings) as Map),
        );
      } catch (_) {}
    }

    final history = <ReportHistoryEntry>[];
    final rawHistory = prefs.getString(_historyKey);
    if (rawHistory != null && rawHistory.isNotEmpty) {
      try {
        final list = jsonDecode(rawHistory) as List;
        history.addAll(list.map((dynamic item) => ReportHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            )));
      } catch (_) {}
    }

    return ReportService._(prefs, profiles, settings, history);
  }

  Future<void> saveSettings(ReportSettings value) async {
    settings = value;
    await _prefs.setString(_settingsKey, jsonEncode(value.toJson()));
  }

  ReportPersonProfile? profileFor(String name) {
    final key = normalizeName(name);
    for (final profile in profiles) {
      if (normalizeName(profile.shortName) == key ||
          normalizeName(profile.fullName) == key) {
        return profile;
      }
    }

    final compact = key.replaceAll(' ', '');
    for (final profile in profiles) {
      final shortCompact = normalizeName(profile.shortName).replaceAll(' ', '');
      if (shortCompact == compact) return profile;
    }
    return null;
  }

  static String normalizeName(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('ʼ', "'")
      .replaceAll('`', "'")
      .replaceAll(RegExp(r'\s+'), ' ');

  static const _monthGenitive = <String>[
    '',
    'січня',
    'лютого',
    'березня',
    'квітня',
    'травня',
    'червня',
    'липня',
    'серпня',
    'вересня',
    'жовтня',
    'листопада',
    'грудня',
  ];

  static String formatCompensation(List<MealCompensationDay> source) {
    final days = source.where((item) => item.any).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    if (days.isEmpty) return '';

    final sameYear = days.every((item) => item.day.year == days.first.day.year);
    final everyDayAllMeals = days.every((item) => item.all);
    var continuous = true;
    for (var i = 1; i < days.length; i++) {
      if (days[i].day.difference(days[i - 1].day).inDays != 1) {
        continuous = false;
        break;
      }
    }

    if (everyDayAllMeals && continuous && days.length > 1 && sameYear) {
      return 'сніданок, обід, вечерю у період з '
          '${_dateWords(days.first.day, includeYear: false)} по '
          '${_dateWords(days.last.day, includeYear: false)} '
          '${days.first.day.year} року';
    }

    final blocks = <String>[];
    for (final item in days) {
      final meals = item.mealWords.join(', ');
      final includeYear = !sameYear;
      blocks.add('$meals ${_dateWords(item.day, includeYear: includeYear)}');
    }
    return '${blocks.join(', ')}${sameYear ? ' ${days.first.day.year} року' : ''}';
  }

  static String _dateWords(DateTime day, {required bool includeYear}) {
    final text = '${day.day.toString().padLeft(2, '0')} ${_monthGenitive[day.month]}';
    return includeYear ? '$text ${day.year} року' : text;
  }

  Future<List<GeneratedReport>> generateReports({
    required List<CompensationReportPerson> persons,
    required DateTime start,
    required DateTime end,
    required bool separateByGroup,
  }) async {
    if (persons.isEmpty) {
      throw StateError('Немає вибраних осіб із позначкою К за цей період.');
    }

    final groups = <String, List<CompensationReportPerson>>{};
    if (separateByGroup) {
      for (final person in persons) {
        groups.putIfAbsent(person.group, () => <CompensationReportPerson>[]).add(person);
      }
    } else {
      groups['С4'] = List<CompensationReportPerson>.from(persons);
    }

    final root = await _reportDirectory();
    final generated = <GeneratedReport>[];
    for (final entry in groups.entries) {
      final list = entry.value
        ..sort((a, b) => a.profile.fullName.compareTo(b.profile.fullName));
      final bytes = await _buildDocx(list);
      final period = '${_compactDate(start)}-${_compactDate(end)}';
      final groupPart = _safeName(entry.key.isEmpty ? 'С4' : entry.key);
      final fileName = 'Компенсація_${groupPart}_$period.docx';
      final file = File('${root.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      generated.add(GeneratedReport(
        group: entry.key,
        fileName: fileName,
        path: file.path,
        personCount: list.length,
      ));
      await _log('GENERATED', fileName, '${list.length} осіб');
    }
    return generated;
  }

  Future<Uint8List> _buildDocx(List<CompensationReportPerson> persons) async {
    final data = await rootBundle.load(_templateAsset);
    final templateBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final templateArchive = ZipDecoder().decodeBytes(templateBytes);
    final xmlFile = templateArchive.findFile('word/document.xml');
    if (xmlFile == null) throw StateError('У Word-шаблоні не знайдено document.xml.');
    final templateXml = utf8.decode(xmlFile.content as List<int>);

    final bodyMatch = RegExp(
      r'<w:body>([\s\S]*?)(<w:sectPr[\s\S]*?</w:sectPr>)\s*</w:body>',
    ).firstMatch(templateXml);
    if (bodyMatch == null) throw StateError('Не вдалося прочитати структуру Word-шаблону.');

    final bodyTemplate = bodyMatch.group(1)!;
    final section = bodyMatch.group(2)!;
    final pages = <String>[];
    for (final person in persons) {
      pages.add(_fillPersonPage(bodyTemplate, person));
    }
    const pageBreak = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';
    final combinedBody = pages.join(pageBreak);
    final newXml = templateXml.replaceRange(
      bodyMatch.start,
      bodyMatch.end,
      '<w:body>$combinedBody$section</w:body>',
    );

    final out = Archive();
    for (final file in templateArchive.files) {
      if (!file.isFile || file.name == 'word/document.xml') continue;
      final content = file.content as List<int>;
      out.addFile(ArchiveFile(file.name, content.length, content));
    }
    final xmlBytes = utf8.encode(newXml);
    out.addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));
    final encoded = ZipEncoder().encode(out);
    if (encoded == null) throw StateError('Не вдалося зібрати DOCX.');
    return Uint8List.fromList(encoded);
  }

  String _fillPersonPage(String source, CompensationReportPerson person) {
    final p = person.profile;
    final values = <String, String>{
      '{{H1}}': '',
      '{{H2}}': '',
      '{{H3}}': '',
      '{{H4}}': '',
      '{{H_RANK}}': '',
      '{{H_PERSON}}': '',
      '{{H_DATE}}': '',
      '{{YEAR}}': '',
      '{{R1_1}}': settings.r1Line1,
      '{{R1_2}}': settings.r1Line2,
      '{{КОМПЕНСАЦІЇ}}': person.compensationText,
      '{{ПОСАДА_ДАВ}}': p.positionDative,
      '{{ЗВАННЯ_ДАВ}}': p.rankDative,
      '{{ПІБ_ДАВ}}': p.fullNameDativeStyled,
      '{{ПОСАДА_НАЗ}}': _upperFirst(p.position),
      '{{ЗВАННЯ_НАЗ}}': p.rank,
      '{{ПІДПИС}}': p.signatureName,
      '{{РІК}}': person.days.first.day.year.toString(),
      '{{R2_1}}': settings.r2Line1,
      '{{R2_2}}': settings.r2Line2,
      '{{R2_3}}': settings.r2Line3,
      '{{R2_4}}': settings.r2Line4,
      '{{ЗВАННЯ_РОД}}': p.rankGenitive,
      '{{ПРІЗВИЩЕ_РОД_ІНІЦІАЛИ}}': p.surnameGenitiveInitials,
      '{{CC_POS}}': settings.ccPosition,
      '{{CC_INST}}': settings.ccInstitution,
      '{{CC_RANK}}': settings.ccRank,
      '{{CC_NAME}}': settings.ccName,
      '{{R3_1}}': settings.r3Line1,
      '{{R3_2}}': settings.r3Line2,
      '{{R3_PETITION}}': settings.r3Petition,
      '{{R3_POS1}}': settings.r3Position1,
      '{{R3_POS2}}': settings.r3Position2,
      '{{R3_POS3}}': settings.r3Position3,
      '{{R3_RANK}}': settings.r3Rank,
      '{{R3_NAME}}': settings.r3Name,
      '{{DOC_POS1}}': settings.doctorPosition1,
      '{{DOC_POS2}}': settings.doctorPosition2,
      '{{DOC_RANK}}': settings.doctorRank,
      '{{DOC_NAME}}': settings.doctorName,
    };

    var xml = source
        .replaceAll(RegExp(r'\s+w14:paraId="[^"]*"'), '')
        .replaceAll(RegExp(r'\s+w14:textId="[^"]*"'), '')
        .replaceAll(RegExp(r'<w:bookmarkStart[^>]*/>'), '')
        .replaceAll(RegExp(r'<w:bookmarkEnd[^>]*/>'), '');
    for (final entry in values.entries) {
      xml = xml.replaceAll(entry.key, _xmlEscape(entry.value));
    }
    return xml;
  }

  Future<void> openReport(GeneratedReport report) async {
    final result = await OpenFilex.open(report.path);
    await _log('OPEN', report.fileName, result.message);
  }

  Future<String> copyToDownloads(GeneratedReport report) async {
    Directory? downloads;
    try {
      downloads = await getDownloadsDirectory();
    } catch (_) {
      downloads = null;
    }
    final targetRoot = downloads ?? await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${targetRoot.path}${Platform.pathSeparator}C4 Harchuvannya',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final target = File('${dir.path}${Platform.pathSeparator}${report.fileName}');
    await File(report.path).copy(target.path);
    await _log('SAVED', report.fileName, target.path);
    return target.path;
  }

  Future<ShareResult> shareReports(List<GeneratedReport> reports) async {
    if (reports.isEmpty) throw StateError('Спочатку сформуйте документ.');
    final result = await Share.shareXFiles(
      reports.map((item) => XFile(item.path)).toList(),
      text: 'Рапорт на компенсацію С4',
      subject: 'Рапорт на компенсацію С4',
    );
    await _log(
      'SHARE',
      reports.map((e) => e.fileName).join(', '),
      result.status.name,
    );
    return result;
  }

  Future<void> _log(String action, String fileName, String detail) async {
    history.insert(
      0,
      ReportHistoryEntry(
        time: DateTime.now(),
        action: action,
        fileName: fileName,
        detail: detail,
      ),
    );
    if (history.length > 100) history.removeRange(100, history.length);
    await _prefs.setString(
      _historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  Future<Directory> _reportDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}C4 Harchuvannya${Platform.pathSeparator}Рапорти',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _compactDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  static String _safeName(String value) => value
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(' ', '_');

  static String _upperFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
