import 'dart:convert';
import 'dart:io';

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
    required this.headerLine1,
    required this.headerLine2,
    required this.headerLine3,
    required this.headerLine4,
    required this.headerRank,
    required this.headerName,
    required this.headerDate,
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
    required this.r3Line3,
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

  final String headerLine1;
  final String headerLine2;
  final String headerLine3;
  final String headerLine4;
  final String headerRank;
  final String headerName;
  final String headerDate;
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
  final String r3Line3;
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
    headerLine1: 'Начальнику ВМЗ',
    headerLine2: 'До наказу',
    headerLine3: 'Начальник ІСЗЗІ КПІ ім. Ігоря Сікорського',
    headerLine4: '',
    headerRank: 'бригадний генерал',
    headerName: 'Олександр ЛУЧКОВ',
    headerDate: '____.____.',
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
    r3Line3: '',
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
        'headerLine1': headerLine1,
        'headerLine2': headerLine2,
        'headerLine3': headerLine3,
        'headerLine4': headerLine4,
        'headerRank': headerRank,
        'headerName': headerName,
        'headerDate': headerDate,
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
        'r3Line3': r3Line3,
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
      headerLine1: s('headerLine1', d.headerLine1),
      headerLine2: s('headerLine2', d.headerLine2),
      headerLine3: s('headerLine3', d.headerLine3),
      headerLine4: s('headerLine4', d.headerLine4),
      headerRank: s('headerRank', d.headerRank),
      headerName: s('headerName', d.headerName),
      headerDate: s('headerDate', d.headerDate),
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
      r3Line3: s('r3Line3', d.r3Line3),
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

class ReportLayoutSettings {
  const ReportLayoutSettings({
    required this.pageTopMm,
    required this.pageRightMm,
    required this.pageBottomMm,
    required this.pageLeftMm,
    required this.headerColumnWidthMm,
    required this.headerWidthMm,
    required this.headerHeightMm,
    required this.headerPaddingMm,
    required this.headerOffsetXmm,
    required this.headerOffsetYmm,
    required this.headerFontPt,
    required this.bodyFontPt,
    required this.firstLineIndentMm,
    required this.lineSpacing,
    required this.gapBeforeFirstReportMm,
    required this.gapBeforePetitionMm,
    required this.gapBeforeThirdReportMm,
    required this.gapBeforeApprovalMm,
    required this.gapBeforeOrderMm,
  });

  final double pageTopMm;
  final double pageRightMm;
  final double pageBottomMm;
  final double pageLeftMm;
  final double headerColumnWidthMm;
  final double headerWidthMm;
  final double headerHeightMm;
  final double headerPaddingMm;
  final double headerOffsetXmm;
  final double headerOffsetYmm;
  final double headerFontPt;
  final double bodyFontPt;
  final double firstLineIndentMm;
  final double lineSpacing;
  final double gapBeforeFirstReportMm;
  final double gapBeforePetitionMm;
  final double gapBeforeThirdReportMm;
  final double gapBeforeApprovalMm;
  final double gapBeforeOrderMm;

  static const defaults = ReportLayoutSettings(
    pageTopMm: 7.5,
    pageRightMm: 15.0,
    pageBottomMm: 7.5,
    pageLeftMm: 30.0,
    headerColumnWidthMm: 76.2,
    headerWidthMm: 89.1,
    headerHeightMm: 29.2,
    headerPaddingMm: 0.0,
    headerOffsetXmm: 0.0,
    headerOffsetYmm: 0.0,
    headerFontPt: 10.0,
    bodyFontPt: 12.0,
    firstLineIndentMm: 12.7,
    lineSpacing: 1.0,
    gapBeforeFirstReportMm: 0.0,
    gapBeforePetitionMm: 2.0,
    gapBeforeThirdReportMm: 2.0,
    gapBeforeApprovalMm: 2.0,
    gapBeforeOrderMm: 1.0,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pageTopMm': pageTopMm,
        'pageRightMm': pageRightMm,
        'pageBottomMm': pageBottomMm,
        'pageLeftMm': pageLeftMm,
        'headerColumnWidthMm': headerColumnWidthMm,
        'headerWidthMm': headerWidthMm,
        'headerHeightMm': headerHeightMm,
        'headerPaddingMm': headerPaddingMm,
        'headerOffsetXmm': headerOffsetXmm,
        'headerOffsetYmm': headerOffsetYmm,
        'headerFontPt': headerFontPt,
        'bodyFontPt': bodyFontPt,
        'firstLineIndentMm': firstLineIndentMm,
        'lineSpacing': lineSpacing,
        'gapBeforeFirstReportMm': gapBeforeFirstReportMm,
        'gapBeforePetitionMm': gapBeforePetitionMm,
        'gapBeforeThirdReportMm': gapBeforeThirdReportMm,
        'gapBeforeApprovalMm': gapBeforeApprovalMm,
        'gapBeforeOrderMm': gapBeforeOrderMm,
      };

  factory ReportLayoutSettings.fromJson(Map<String, dynamic> map) {
    double n(String key, double fallback) {
      final raw = map[key];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString().replaceAll(',', '.') ?? '') ?? fallback;
    }

    const d = defaults;
    return ReportLayoutSettings(
      pageTopMm: n('pageTopMm', d.pageTopMm),
      pageRightMm: n('pageRightMm', d.pageRightMm),
      pageBottomMm: n('pageBottomMm', d.pageBottomMm),
      pageLeftMm: n('pageLeftMm', d.pageLeftMm),
      headerColumnWidthMm: n('headerColumnWidthMm', d.headerColumnWidthMm),
      headerWidthMm: n('headerWidthMm', d.headerWidthMm),
      headerHeightMm: n('headerHeightMm', d.headerHeightMm),
      headerPaddingMm: n('headerPaddingMm', d.headerPaddingMm),
      headerOffsetXmm: n('headerOffsetXmm', d.headerOffsetXmm),
      headerOffsetYmm: n('headerOffsetYmm', d.headerOffsetYmm),
      headerFontPt: n('headerFontPt', d.headerFontPt),
      bodyFontPt: n('bodyFontPt', d.bodyFontPt),
      firstLineIndentMm: n('firstLineIndentMm', d.firstLineIndentMm),
      lineSpacing: n('lineSpacing', d.lineSpacing),
      gapBeforeFirstReportMm: n('gapBeforeFirstReportMm', d.gapBeforeFirstReportMm),
      gapBeforePetitionMm: n('gapBeforePetitionMm', d.gapBeforePetitionMm),
      gapBeforeThirdReportMm: n('gapBeforeThirdReportMm', d.gapBeforeThirdReportMm),
      gapBeforeApprovalMm: n('gapBeforeApprovalMm', d.gapBeforeApprovalMm),
      gapBeforeOrderMm: n('gapBeforeOrderMm', d.gapBeforeOrderMm),
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
  ReportService._(this._prefs, this.profiles, this.settings, this.layout, this.history);

  static const _settingsKey = 'report_settings_v08';
  static const _historyKey = 'report_history_v08';
  static const _layoutKey = 'report_layout_v084';
  static const _templateAsset =
      'assets/templates/report_template.docx';
  static const _editableTemplateAsset =
      'assets/templates/report_editable_template.docx';
  static const _profilesAsset = 'assets/data/report_people.json';

  final SharedPreferences _prefs;
  final List<ReportPersonProfile> profiles;
  ReportSettings settings;
  ReportLayoutSettings layout;
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

    var layout = ReportLayoutSettings.defaults;
    final rawLayout = prefs.getString(_layoutKey);
    if (rawLayout != null && rawLayout.isNotEmpty) {
      try {
        layout = ReportLayoutSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawLayout) as Map),
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

    return ReportService._(prefs, profiles, settings, layout, history);
  }

  Future<void> saveSettings(ReportSettings value) async {
    settings = value;
    await _prefs.setString(_settingsKey, jsonEncode(value.toJson()));
  }

  Future<void> saveLayoutSettings(ReportLayoutSettings value) async {
    layout = value;
    await _prefs.setString(_layoutKey, jsonEncode(value.toJson()));
  }

  Future<void> resetLayoutSettings() async {
    layout = ReportLayoutSettings.defaults;
    await _prefs.remove(_layoutKey);
  }

  Future<bool> hasEditableTemplate() async {
    final file = await _editableTemplateFile();
    return file.exists();
  }

  Future<String> editableTemplatePath() async {
    final file = await _editableTemplateFile();
    return file.path;
  }

  Future<GeneratedReport> openEditableTemplate({bool reset = false}) async {
    final file = await _editableTemplateFile();
    if (reset || !await file.exists()) {
      final data = await rootBundle.load(_editableTemplateAsset);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes, flush: true);
    }

    final result = await OpenFilex.open(file.path);
    await _log(
      reset ? 'TEMPLATE_RESET' : 'TEMPLATE_OPEN',
      file.uri.pathSegments.last,
      result.message,
    );
    return GeneratedReport(
      group: 'TEMPLATE',
      fileName: file.uri.pathSegments.last,
      path: file.path,
      personCount: 1,
    );
  }

  Future<void> removeEditableTemplate() async {
    final file = await _editableTemplateFile();
    if (await file.exists()) {
      await file.delete();
      await _log('TEMPLATE_REMOVE', file.uri.pathSegments.last, 'Повернення до стандартного шаблону');
    }
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

  Future<GeneratedReport> generateTestReport() async {
    if (profiles.isEmpty) {
      throw StateError('Довідник осіб порожній.');
    }
    final day = DateTime.now();
    final profile = profiles.first;
    final person = CompensationReportPerson(
      personId: 'layout-test',
      group: profile.group.isEmpty ? 'С4' : profile.group,
      profile: profile,
      days: <MealCompensationDay>[
        MealCompensationDay(
          day: day,
          breakfast: true,
          lunch: true,
          dinner: true,
        ),
      ],
    );
    final bytes = await _buildDocx(<CompensationReportPerson>[person]);
    final root = await _reportDirectory();
    const fileName = 'Тест_оформлення_DOCX.docx';
    final file = File('${root.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await _log('TEST', fileName, 'Перевірка налаштувань документа');
    return GeneratedReport(
      group: person.group,
      fileName: fileName,
      path: file.path,
      personCount: 1,
    );
  }

  Future<Uint8List> _buildDocx(List<CompensationReportPerson> persons) async {
    final editableFile = await _editableTemplateFile();
    final useEditableTemplate = await editableFile.exists();
    final Uint8List templateBytes;
    if (useEditableTemplate) {
      templateBytes = await editableFile.readAsBytes();
    } else {
      final data = await rootBundle.load(_templateAsset);
      templateBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    final templateArchive = ZipDecoder().decodeBytes(templateBytes);
    final xmlFile = templateArchive.findFile('word/document.xml');
    if (xmlFile == null) throw StateError('У Word-шаблоні не знайдено document.xml.');
    final templateXml = utf8.decode(xmlFile.content as List<int>);
    if (useEditableTemplate) {
      _validateEditableTemplate(templateXml);
    }

    final bodyMatch = RegExp(
      r'<w:body>([\s\S]*?)(<w:sectPr[\s\S]*?</w:sectPr>)\s*</w:body>',
    ).firstMatch(templateXml);
    if (bodyMatch == null) throw StateError('Не вдалося прочитати структуру Word-шаблону.');

    // Keep the real TextBox in the MASTER, but sanitize paragraph metadata.
    // Each duplicated page receives its own TextBox IDs in _fillPersonPage,
    // which prevents Microsoft Word from reporting duplicate drawing IDs.
    final sanitizedBody = _sanitizeTemplateBody(bodyMatch.group(1)!);
    final bodyTemplate = useEditableTemplate
        ? sanitizedBody
        : _applyDocumentLayout(sanitizedBody);
    final section = useEditableTemplate
        ? bodyMatch.group(2)!
        : _applyPageMargins(bodyMatch.group(2)!);
    final pages = <String>[];
    for (var index = 0; index < persons.length; index++) {
      pages.add(_fillPersonPage(bodyTemplate, persons[index], index));
    }

    // Exactly one explicit page break between people. Never append a break
    // after the last person; this prevents an extra blank page.
    const pageBreak = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';
    final combinedBody = pages.join(pageBreak);
    final newXml = templateXml.replaceRange(
      bodyMatch.start,
      bodyMatch.end,
      '<w:body>$combinedBody$section</w:body>',
    );
    _validateGeneratedXml(newXml, persons.length);

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

  String _applyPageMargins(String source) {
    final top = _mmToTwips(_clamp(layout.pageTopMm, 0, 60));
    final right = _mmToTwips(_clamp(layout.pageRightMm, 0, 60));
    final bottom = _mmToTwips(_clamp(layout.pageBottomMm, 0, 60));
    final left = _mmToTwips(_clamp(layout.pageLeftMm, 0, 60));
    final pgMar = RegExp(r'<w:pgMar\b[^>]*/>');
    final match = pgMar.firstMatch(source);
    if (match == null) return source;
    var tag = match.group(0)!;
    tag = _setXmlAttribute(tag, 'w:top', top.toString());
    tag = _setXmlAttribute(tag, 'w:right', right.toString());
    tag = _setXmlAttribute(tag, 'w:bottom', bottom.toString());
    tag = _setXmlAttribute(tag, 'w:left', left.toString());
    return source.replaceRange(match.start, match.end, tag);
  }

  String _applyDocumentLayout(String source) {
    var xml = source;
    xml = _applyHeaderLayout(xml);
    xml = _applyMainParagraphLayout(xml);
    xml = _setFirstExactParagraphBefore(xml, 'РАПОРТ', layout.gapBeforeFirstReportMm);
    xml = _setParagraphBeforeContaining(xml, '{{R2_1}}', layout.gapBeforePetitionMm);
    xml = _setParagraphBeforeContaining(xml, '{{R3_1}}', layout.gapBeforeThirdReportMm);
    xml = _setParagraphBeforeContaining(xml, 'ПОГОДЖЕНО', layout.gapBeforeApprovalMm);
    xml = _setParagraphBeforeContaining(xml, 'Наказ начальника ІСЗЗІ', layout.gapBeforeOrderMm);
    return xml;
  }

  String _applyHeaderLayout(String source) {
    var xml = source;
    final widthMm = _clamp(layout.headerWidthMm, 45, 130);
    final heightMm = _clamp(layout.headerHeightMm, 15, 70);
    final widthEmu = (widthMm * 36000).round();
    final heightEmu = (heightMm * 36000).round();
    final widthPt = widthMm * 72 / 25.4;
    final heightPt = heightMm * 72 / 25.4;
    final insetPt = _clamp(layout.headerPaddingMm, 0, 10) * 72 / 25.4;
    final headerHalfPoints = (_clamp(layout.headerFontPt, 7, 18) * 2).round();

    xml = xml.replaceFirst(
      RegExp(r'<wp:extent\s+cx="\d+"\s+cy="\d+"\s*/>'),
      '<wp:extent cx="$widthEmu" cy="$heightEmu"/>',
    );
    xml = xml.replaceFirst(
      RegExp(r'<a:ext\s+cx="\d+"\s+cy="\d+"\s*/>'),
      '<a:ext cx="$widthEmu" cy="$heightEmu"/>',
    );
    xml = xml.replaceFirstMapped(
      RegExp(r'<v:rect\b([^>]*)style="[^"]*"([^>]*)>'),
      (match) => '<v:rect${match.group(1)}style="width:${widthPt.toStringAsFixed(1)}pt;height:${heightPt.toStringAsFixed(1)}pt"${match.group(2)}>',
    );
    xml = xml.replaceFirstMapped(
      RegExp(r'<wps:bodyPr\b[^>]*>'),
      (match) {
        var tag = match.group(0)!;
        final insetEmu = (_clamp(layout.headerPaddingMm, 0, 10) * 36000).round();
        tag = _setXmlAttribute(tag, 'lIns', insetEmu.toString());
        tag = _setXmlAttribute(tag, 'tIns', insetEmu.toString());
        tag = _setXmlAttribute(tag, 'rIns', insetEmu.toString());
        tag = _setXmlAttribute(tag, 'bIns', insetEmu.toString());
        return tag;
      },
    );
    xml = xml.replaceFirstMapped(
      RegExp(r'<v:textbox\b[^>]*>'),
      (match) {
        var tag = match.group(0)!;
        tag = _setXmlAttribute(
          tag,
          'inset',
          '${insetPt.toStringAsFixed(1)}pt,${insetPt.toStringAsFixed(1)}pt,${insetPt.toStringAsFixed(1)}pt,${insetPt.toStringAsFixed(1)}pt',
        );
        return tag;
      },
    );

    final txbx = RegExp(r'<w:txbxContent>[\s\S]*?</w:txbxContent>');
    xml = xml.replaceAllMapped(txbx, (match) {
      var block = match.group(0)!;
      block = block
          .replaceAll(RegExp(r'<w:sz\s+w:val="\d+"\s*/>'), '<w:sz w:val="$headerHalfPoints"/>')
          .replaceAll(RegExp(r'<w:szCs\s+w:val="\d+"\s*/>'), '<w:szCs w:val="$headerHalfPoints"/>');
      return block;
    });

    xml = _offsetTextBoxParagraph(
      xml,
      _mmToTwips(_clamp(layout.headerOffsetXmm, 0, 30)),
      _mmToTwips(_clamp(layout.headerOffsetYmm, 0, 30)),
    );

    // The first table is the two-column top block: TextBox on the left,
    // first-report addressee on the right. Changing the first column lets
    // the user move the split without editing Word XML manually.
    final topTable = RegExp(r'<w:tbl>[\s\S]*?</w:tbl>');
    xml = xml.replaceFirstMapped(topTable, (match) {
      var table = match.group(0)!;
      const tableTotalMm = 152.4;
      final leftMm = _clamp(layout.headerColumnWidthMm, 45, 110);
      final rightMm = _clamp(tableTotalMm - leftMm, 35, 107.4);
      final widths = <int>[_mmToTwips(leftMm), _mmToTwips(rightMm)];
      var gridIndex = 0;
      table = table.replaceAllMapped(RegExp(r'<w:gridCol\s+w:w="\d+"\s*/>'), (m) {
        if (gridIndex >= 2) return m.group(0)!;
        return '<w:gridCol w:w="${widths[gridIndex++]}"/>';
      });
      var cellIndex = 0;
      table = table.replaceAllMapped(RegExp(r'<w:tcW\s+w:type="dxa"\s+w:w="\d+"\s*/>'), (m) {
        if (cellIndex >= 2) return m.group(0)!;
        return '<w:tcW w:type="dxa" w:w="${widths[cellIndex++]}"/>';
      });
      return table;
    });
    return xml;
  }

  static String _offsetTextBoxParagraph(
    String source,
    int leftTwips,
    int beforeTwips,
  ) {
    final altStart = source.indexOf('<mc:AlternateContent');
    if (altStart < 0) return source;
    final altClose = source.indexOf('</mc:AlternateContent>', altStart);
    if (altClose < 0) return source;
    final start = source.lastIndexOf('<w:p', altStart);
    final close = source.indexOf('</w:p>', altClose);
    if (start < 0 || close < 0) return source;
    final end = close + '</w:p>'.length;
    var paragraph = source.substring(start, end);
    paragraph = _patchParagraphProperties(paragraph, (pPr) {
      var result = pPr;
      final indent = RegExp(r'<w:ind\b[^>]*/>');
      final indentMatch = indent.firstMatch(result);
      if (indentMatch == null) {
        result = result.replaceFirst(
          '<w:pPr>',
          '<w:pPr><w:ind w:left="$leftTwips"/>',
        );
      } else {
        final tag = _setXmlAttribute(
          indentMatch.group(0)!,
          'w:left',
          leftTwips.toString(),
        );
        result = result.replaceRange(indentMatch.start, indentMatch.end, tag);
      }

      final spacing = RegExp(r'<w:spacing\b[^>]*/>');
      final spacingMatch = spacing.firstMatch(result);
      if (spacingMatch == null) {
        result = result.replaceFirst(
          '<w:pPr>',
          '<w:pPr><w:spacing w:before="$beforeTwips"/>',
        );
      } else {
        final tag = _setXmlAttribute(
          spacingMatch.group(0)!,
          'w:before',
          beforeTwips.toString(),
        );
        result = result.replaceRange(spacingMatch.start, spacingMatch.end, tag);
      }
      return result;
    });
    return source.replaceRange(start, end, paragraph);
  }

  String _applyMainParagraphLayout(String source) {
    const needle = 'Відповідно до постанови';
    final textIndex = source.indexOf(needle);
    if (textIndex < 0) return source;
    final start = source.lastIndexOf('<w:p', textIndex);
    final close = source.indexOf('</w:p>', textIndex);
    if (start < 0 || close < 0) return source;
    final end = close + '</w:p>'.length;
    var value = source.substring(start, end);
    final halfPoints = (_clamp(layout.bodyFontPt, 9, 16) * 2).round();
    value = value
        .replaceAll(RegExp(r'<w:sz\s+w:val="\d+"\s*/>'), '<w:sz w:val="$halfPoints"/>')
        .replaceAll(RegExp(r'<w:szCs\s+w:val="\d+"\s*/>'), '<w:szCs w:val="$halfPoints"/>');
    value = _setParagraphIndent(
      value,
      _mmToTwips(_clamp(layout.firstLineIndentMm, 0, 30)),
    );
    value = _setParagraphLineSpacing(
      value,
      (_clamp(layout.lineSpacing, 0.8, 2.0) * 240).round(),
    );
    return source.replaceRange(start, end, value);
  }

  static String _setFirstExactParagraphBefore(String source, String text, double mm) {
    final tokenIndex = source.indexOf('>$text<');
    if (tokenIndex < 0) return source;
    return _patchParagraphAroundIndex(
      source,
      tokenIndex,
      (paragraph) => _setParagraphBefore(
        paragraph,
        _mmToTwips(_clamp(mm, 0, 30)),
      ),
    );
  }

  static String _setParagraphBeforeContaining(String source, String token, double mm) {
    final tokenIndex = source.indexOf(token);
    if (tokenIndex < 0) return source;
    return _patchParagraphAroundIndex(
      source,
      tokenIndex,
      (paragraph) => _setParagraphBefore(
        paragraph,
        _mmToTwips(_clamp(mm, 0, 30)),
      ),
    );
  }

  static String _patchParagraphAroundIndex(
    String source,
    int index,
    String Function(String paragraph) patch,
  ) {
    final start = source.lastIndexOf('<w:p', index);
    final close = source.indexOf('</w:p>', index);
    if (start < 0 || close < 0) return source;
    final end = close + '</w:p>'.length;
    final paragraph = source.substring(start, end);
    return source.replaceRange(start, end, patch(paragraph));
  }

  static String _setParagraphBefore(String paragraph, int before) {
    return _patchParagraphProperties(paragraph, (pPr) {
      final spacing = RegExp(r'<w:spacing\b[^>]*/>');
      final match = spacing.firstMatch(pPr);
      if (match == null) {
        return pPr.replaceFirst('<w:pPr>', '<w:pPr><w:spacing w:before="$before"/>');
      }
      final tag = _setXmlAttribute(match.group(0)!, 'w:before', before.toString());
      return pPr.replaceRange(match.start, match.end, tag);
    });
  }

  static String _setParagraphIndent(String paragraph, int firstLine) {
    return _patchParagraphProperties(paragraph, (pPr) {
      final indent = RegExp(r'<w:ind\b[^>]*/>');
      final match = indent.firstMatch(pPr);
      if (match == null) {
        return pPr.replaceFirst('<w:pPr>', '<w:pPr><w:ind w:firstLine="$firstLine"/>');
      }
      final tag = _setXmlAttribute(match.group(0)!, 'w:firstLine', firstLine.toString());
      return pPr.replaceRange(match.start, match.end, tag);
    });
  }

  static String _setParagraphLineSpacing(String paragraph, int line) {
    return _patchParagraphProperties(paragraph, (pPr) {
      final spacing = RegExp(r'<w:spacing\b[^>]*/>');
      final match = spacing.firstMatch(pPr);
      if (match == null) {
        return pPr.replaceFirst(
          '<w:pPr>',
          '<w:pPr><w:spacing w:line="$line" w:lineRule="auto"/>',
        );
      }
      var tag = match.group(0)!;
      tag = _setXmlAttribute(tag, 'w:line', line.toString());
      tag = _setXmlAttribute(tag, 'w:lineRule', 'auto');
      return pPr.replaceRange(match.start, match.end, tag);
    });
  }

  static String _patchParagraphProperties(
    String paragraph,
    String Function(String pPr) patch,
  ) {
    final pPr = RegExp(r'<w:pPr>[\s\S]*?</w:pPr>');
    final match = pPr.firstMatch(paragraph);
    if (match != null) {
      final updated = patch(match.group(0)!);
      return paragraph.replaceRange(match.start, match.end, updated);
    }
    final open = RegExp(r'<w:p\b[^>]*>').firstMatch(paragraph);
    if (open == null) return paragraph;
    final created = patch('<w:pPr></w:pPr>');
    return paragraph.replaceRange(open.end, open.end, created);
  }

  static String _setXmlAttribute(String tag, String name, String value) {
    final attr = RegExp('${RegExp.escape(name)}="[^"]*"');
    if (attr.hasMatch(tag)) {
      return tag.replaceFirst(attr, '$name="$value"');
    }
    final end = tag.endsWith('/>') ? '/>' : '>';
    return tag.substring(0, tag.length - end.length) + ' $name="$value"' + end;
  }

  static int _mmToTwips(double mm) => (mm * 56.6929133858).round();

  static double _clamp(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  String _fillPersonPage(
    String source,
    CompensationReportPerson person,
    int pageIndex,
  ) {
    final values = _pageValues(person, pageIndex);
    var xml = _sanitizeTemplateBody(source);

    // In the user-editable MASTER every dynamic value is stored in a Word
    // content control (SDT). Empty optional values remove their whole
    // paragraph only in the generated copy; the saved MASTER remains intact.
    for (final entry in values.entries) {
      if (entry.value.trim().isEmpty) {
        xml = _removeParagraphContaining(xml, '{{${entry.key}}}');
        xml = _removeParagraphContainingSdtTag(xml, entry.key);
      }
    }

    xml = _fillContentControls(xml, values);

    // Factory MASTER still uses {{TOKEN}} placeholders. Keep this fallback so
    // both the built-in and the manually edited SDT template are supported.
    for (final entry in values.entries) {
      xml = xml.replaceAll('{{${entry.key}}}', _xmlEscape(entry.value));
    }

    xml = _rekeyTextBoxIds(xml, pageIndex);
    xml = _removeEmptyParagraphs(xml);
    return xml.trim();
  }

  Map<String, String> _pageValues(
    CompensationReportPerson person,
    int pageIndex,
  ) {
    final p = person.profile;
    return <String, String>{
      'H1': settings.headerLine1,
      'H2': settings.headerLine2,
      'H3': settings.headerLine3,
      'H4': settings.headerLine4,
      'H_RANK': settings.headerRank,
      'H_PERSON': settings.headerName,
      'H_DATE': settings.headerDate,
      'TB_DOCPR': (pageIndex + 1).toString(),
      'TB_ID': (pageIndex + 1).toString(),
      'TB_SPID': (1026 + pageIndex).toString(),
      'YEAR': person.days.first.day.year.toString(),
      'R1_1': settings.r1Line1,
      'R1_2': settings.r1Line2,
      'КОМПЕНСАЦІЇ': person.compensationText,
      'ПОСАДА_ДАВ': p.positionDative,
      'ЗВАННЯ_ДАВ': p.rankDative,
      'ПІБ_ДАВ': p.fullNameDativeStyled,
      'ПОСАДА_НАЗ': _upperFirst(p.position),
      'ЗВАННЯ_НАЗ': p.rank,
      'ПІДПИС': p.signatureName,
      'РІК': person.days.first.day.year.toString(),
      'R2_1': settings.r2Line1,
      'R2_2': settings.r2Line2,
      'R2_3': settings.r2Line3,
      'R2_4': settings.r2Line4,
      'ЗВАННЯ_РОД': p.rankGenitive,
      'ПРІЗВИЩЕ_РОД_ІНІЦІАЛИ': p.surnameGenitiveInitials,
      'CC_POS': settings.ccPosition,
      'CC_INST': settings.ccInstitution,
      'CC_RANK': settings.ccRank,
      'CC_NAME': settings.ccName,
      'R3_1': settings.r3Line1,
      'R3_2': settings.r3Line2,
      'R3_3': settings.r3Line3,
      'R3_PETITION': settings.r3Petition,
      'R3_POS1': settings.r3Position1,
      'R3_POS2': settings.r3Position2,
      'R3_POS3': settings.r3Position3,
      'R3_RANK': settings.r3Rank,
      'R3_NAME': settings.r3Name,
      'DOC_POS1': settings.doctorPosition1,
      'DOC_POS2': settings.doctorPosition2,
      'DOC_RANK': settings.doctorRank,
      'DOC_NAME': settings.doctorName,
    };
  }

  static String _fillContentControls(
    String source,
    Map<String, String> values,
  ) {
    final sdt = RegExp(r'<w:sdt\b[\s\S]*?</w:sdt>');
    final tagPattern = RegExp(r'<w:tag\b[^>]*w:val="([^"]+)"[^>]*/?>');
    final contentPattern = RegExp(r'<w:sdtContent>([\s\S]*?)</w:sdtContent>');
    final textPattern = RegExp(r'<w:t\b([^>]*)>[\s\S]*?</w:t>');

    return source.replaceAllMapped(sdt, (match) {
      final block = match.group(0)!;
      final tagMatch = tagPattern.firstMatch(block);
      if (tagMatch == null) return block;
      final tag = tagMatch.group(1)!;
      if (!values.containsKey(tag)) return block;

      final contentMatch = contentPattern.firstMatch(block);
      if (contentMatch == null) return block;
      final content = contentMatch.group(1)!;
      final textMatches = textPattern.allMatches(content).toList();
      final escaped = _xmlEscape(values[tag]!);

      String newContent;
      if (textMatches.isEmpty) {
        newContent = '<w:r><w:t>$escaped</w:t></w:r>';
      } else {
        var cursor = 0;
        final buffer = StringBuffer();
        for (var i = 0; i < textMatches.length; i++) {
          final item = textMatches[i];
          buffer.write(content.substring(cursor, item.start));
          final attrs = item.group(1) ?? '';
          buffer.write('<w:t$attrs>${i == 0 ? escaped : ''}</w:t>');
          cursor = item.end;
        }
        buffer.write(content.substring(cursor));
        newContent = buffer.toString();
      }

      final replacement = '<w:sdtContent>$newContent</w:sdtContent>';
      return block.replaceRange(contentMatch.start, contentMatch.end, replacement);
    });
  }

  static String _removeParagraphContainingSdtTag(
    String source,
    String tag,
  ) {
    final paragraph = RegExp(r'<w:p\b[^>]*>[\s\S]*?</w:p>');
    final marker = RegExp(
      '<w:tag\\b[^>]*w:val="${RegExp.escape(tag)}"[^>]*/?>',
    );
    return source.replaceAllMapped(paragraph, (match) {
      final value = match.group(0)!;
      return marker.hasMatch(value) ? '' : value;
    });
  }

  static String _rekeyTextBoxIds(String source, int pageIndex) {
    final docPrId = pageIndex + 1;
    final spid = 1026 + pageIndex;
    final anchorId = (0xC4000000 + docPrId)
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    final editId = (0xD4000000 + docPrId)
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    var xml = source;
    xml = xml.replaceFirstMapped(
      RegExp(r'<wp:docPr\b[^>]*>'),
      (match) {
        var tag = match.group(0)!;
        tag = _setXmlAttribute(tag, 'id', docPrId.toString());
        tag = _setXmlAttribute(tag, 'name', 'Шапка до наказу $docPrId');
        return tag;
      },
    );
    xml = xml.replaceFirstMapped(
      RegExp(r'<wp:anchor\b[^>]*>'),
      (match) {
        var tag = match.group(0)!;
        if (tag.contains('wp14:anchorId=')) {
          tag = _setXmlAttribute(tag, 'wp14:anchorId', anchorId);
        }
        if (tag.contains('wp14:editId=')) {
          tag = _setXmlAttribute(tag, 'wp14:editId', editId);
        }
        return tag;
      },
    );
    xml = xml.replaceFirstMapped(
      RegExp(r'<v:(?:rect|shape)\b[^>]*>'),
      (match) {
        var tag = match.group(0)!;
        tag = _setXmlAttribute(tag, 'id', 'HeaderTextBox_$docPrId');
        tag = _setXmlAttribute(tag, 'o:spid', '_x0000_s$spid');
        return tag;
      },
    );
    return xml;
  }

  static void _validateEditableTemplate(String xml) {
    const requiredTags = <String>{
      'H1', 'H2', 'H3', 'H4', 'H_RANK', 'H_PERSON', 'H_DATE', 'YEAR',
      'R1_1', 'R1_2', 'КОМПЕНСАЦІЇ', 'ПОСАДА_ДАВ', 'ЗВАННЯ_ДАВ',
      'ПІБ_ДАВ', 'ПОСАДА_НАЗ', 'ЗВАННЯ_НАЗ', 'ПІДПИС', 'РІК',
      'R2_1', 'R2_2', 'R2_3', 'R2_4', 'ЗВАННЯ_РОД',
      'ПРІЗВИЩЕ_РОД_ІНІЦІАЛИ', 'CC_POS', 'CC_INST', 'CC_RANK', 'CC_NAME',
      'R3_1', 'R3_2', 'R3_3', 'R3_PETITION', 'R3_POS1', 'R3_POS2',
      'R3_POS3', 'R3_RANK', 'R3_NAME', 'DOC_POS1', 'DOC_POS2', 'DOC_RANK',
      'DOC_NAME',
    };
    final missing = <String>[];
    for (final tag in requiredTags) {
      final pattern = RegExp(
        '<w:tag\\b[^>]*w:val="${RegExp.escape(tag)}"[^>]*/?>',
      );
      if (!pattern.hasMatch(xml)) missing.add(tag);
    }
    if (missing.isNotEmpty) {
      throw StateError(
        'У «Моїй тестовій сторінці» видалено службові поля: '
        '${missing.take(6).join(', ')}${missing.length > 6 ? '…' : ''}. '
        'Відновіть стандартну тестову сторінку і повторіть оформлення.',
      );
    }
  }

  static String _sanitizeTemplateBody(String source) {
    var xml = source
        // Keep the header as a real Word TextBox. The template uses a safe
        // non-WordArt text box; per-page drawing/shape IDs are filled later
        // so duplicated report pages remain valid in Microsoft Word.
        .replaceAll(RegExp(r'\s+w14:paraId="[^"]*"'), '')
        .replaceAll(RegExp(r'\s+w14:textId="[^"]*"'), '')
        .replaceAll(RegExp(r'<w:bookmarkStart[^>]*/>'), '')
        .replaceAll(RegExp(r'<w:bookmarkEnd[^>]*/>'), '');
    xml = _removeEmptyParagraphs(xml);
    return xml;
  }

  static String _removeParagraphContaining(String source, String token) {
    final paragraph = RegExp(r'<w:p\b[^>]*>[\s\S]*?</w:p>');
    return source.replaceAllMapped(paragraph, (match) {
      final value = match.group(0)!;
      return value.contains(token) ? '' : value;
    });
  }

  static String _removeEmptyParagraphs(String source) {
    final paragraph = RegExp(r'<w:p\b[^>]*>[\s\S]*?</w:p>');
    final textNode = RegExp(r'<w:t\b[^>]*>([\s\S]*?)</w:t>');

    return source.replaceAllMapped(paragraph, (match) {
      final value = match.group(0)!;
      if (value.contains('<w:br') ||
          value.contains('<w:tab') ||
          value.contains('<w:drawing') ||
          value.contains('<w:pict') ||
          value.contains('<w:object') ||
          value.contains('<w:sdt')) {
        return value;
      }

      final text = textNode
          .allMatches(value)
          .map((item) => item.group(1) ?? '')
          .join()
          .trim();
      return text.isEmpty ? '' : value;
    });
  }

  static void _validateGeneratedXml(String xml, int personCount) {
    final unresolved = RegExp(r'\{\{[^{}]+\}\}').firstMatch(xml);
    if (unresolved != null) {
      throw StateError(
        'У DOCX залишився незаповнений маркер ${unresolved.group(0)}.',
      );
    }

    // The header is intentionally a real Word TextBox. Verify that every
    // duplicated page has its own drawing and VML shape identifiers.
    final docPrIds = RegExp(r'<wp:docPr\b[^>]*\bid="([^"]+)"')
        .allMatches(xml)
        .map((match) => match.group(1)!)
        .toList();
    final shapeIds = RegExp(r'<v:(?:rect|shape)\b[^>]*\bid="([^"]+)"')
        .allMatches(xml)
        .map((match) => match.group(1)!)
        .toList();
    final anchorIds = RegExp(r'<wp:anchor\b[^>]*wp14:anchorId="([^"]+)"')
        .allMatches(xml)
        .map((match) => match.group(1)!)
        .toList();
    final editIds = RegExp(r'<wp:anchor\b[^>]*wp14:editId="([^"]+)"')
        .allMatches(xml)
        .map((match) => match.group(1)!)
        .toList();

    if (docPrIds.length != personCount ||
        docPrIds.toSet().length != docPrIds.length) {
      throw StateError(
        'Некоректні або дубльовані ID TextBox у DrawingML.',
      );
    }
    if (shapeIds.length != personCount ||
        shapeIds.toSet().length != shapeIds.length) {
      throw StateError(
        'Некоректні або дубльовані ID TextBox у VML.',
      );
    }
    if (anchorIds.isNotEmpty &&
        (anchorIds.length != personCount ||
            anchorIds.toSet().length != anchorIds.length)) {
      throw StateError('Некоректні або дубльовані anchorId плаваючого TextBox.');
    }
    if (editIds.isNotEmpty &&
        (editIds.length != personCount || editIds.toSet().length != editIds.length)) {
      throw StateError('Некоректні або дубльовані editId плаваючого TextBox.');
    }
    if (xml.contains('<v:textpath') || xml.contains('<w14:textOutline')) {
      throw StateError(
        'У DOCX залишився WordArt замість звичайного TextBox.',
      );
    }

    final pageBreaks = RegExp(
      r'<w:br\b[^>]*w:type="page"[^>]*/?>',
    ).allMatches(xml).length;
    final expectedBreaks = personCount > 0 ? personCount - 1 : 0;
    if (pageBreaks != expectedBreaks) {
      throw StateError(
        'Некоректна кількість розривів сторінки: '
        '$pageBreaks замість $expectedBreaks.',
      );
    }
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

  Future<File> _editableTemplateFile() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}C4 Harchuvannya${Platform.pathSeparator}Шаблони',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(
      '${dir.path}${Platform.pathSeparator}Моя_тестова_сторінка.docx',
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
