import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_api.dart';
import 'update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.initialize();
  runApp(C4FoodApp(controller: controller));
}

enum UserRole { admin, editor, duty }
enum Meal { breakfast, lunch, dinner }
enum Mark { none, k, v, sh, vd }

typedef StatusMap = Map<String, Map<String, String>>;

String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
String longDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

String roleTitle(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Адміністратор';
    case UserRole.editor:
      return 'Редактор';
    case UserRole.duty:
      return 'Черговий курсу';
  }
}

String mealTitle(Meal meal) {
  switch (meal) {
    case Meal.breakfast:
      return 'Сніданок';
    case Meal.lunch:
      return 'Обід';
    case Meal.dinner:
      return 'Вечеря';
  }
}

String mealShort(Meal meal) {
  switch (meal) {
    case Meal.breakfast:
      return 'Снід.';
    case Meal.lunch:
      return 'Обід';
    case Meal.dinner:
      return 'Веч.';
  }
}

String markText(Mark mark) {
  switch (mark) {
    case Mark.none:
      return '';
    case Mark.k:
      return 'К';
    case Mark.v:
      return 'В';
    case Mark.sh:
      return 'Ш';
    case Mark.vd:
      return 'Вд';
  }
}

Mark markFromText(String value) {
  switch (value) {
    case 'К':
      return Mark.k;
    case 'В':
      return Mark.v;
    case 'Ш':
      return Mark.sh;
    case 'Вд':
      return Mark.vd;
    default:
      return Mark.none;
  }
}

String mealKey(Meal meal) => meal.name;

const Duration appNoticeDuration = Duration(seconds: 5);

void showAppNotice(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: appNoticeDuration,
      backgroundColor: backgroundColor,
      action: action,
    ),
  );
}

class AppUser {
  AppUser({
    required this.login,
    required this.displayName,
    required this.role,
    required this.groups,
  });

  final String login;
  final String displayName;
  final UserRole role;
  final List<String> groups;
}

class ManagedUser {
  ManagedUser({
    required this.login,
    required this.displayName,
    required this.role,
    required this.groups,
    required this.disabled,
    required this.activeSessions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String login;
  final String displayName;
  final UserRole role;
  final List<String> groups;
  final bool disabled;
  final int activeSessions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static ManagedUser fromJson(Map<String, dynamic> map) {
    final roleRaw = map['role']?.toString() ?? 'duty';
    final role = roleRaw == 'admin'
        ? UserRole.admin
        : roleRaw == 'editor'
            ? UserRole.editor
            : UserRole.duty;
    final rawGroups = (map['groups'] as List?) ?? const <dynamic>[];
    return ManagedUser(
      login: map['login']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? map['login']?.toString() ?? '',
      role: role,
      groups: rawGroups.map((dynamic e) => e.toString()).toList(),
      disabled: map['disabled'] == true,
      activeSessions: int.tryParse(map['activeSessions']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }
}

class Person {
  Person({
    required this.id,
    required this.rank,
    required this.name,
    required this.group,
    Map<String, Map<String, String>>? statuses,
  }) : statuses = statuses ?? <String, Map<String, String>>{};

  String id;
  String rank;
  String name;
  String group;
  StatusMap statuses;

  Mark mark(DateTime day, Meal meal) {
    final byDay = statuses[dateKey(day)];
    return markFromText(byDay?[mealKey(meal)] ?? '');
  }

  void setMark(DateTime day, Meal meal, Mark mark) {
    final key = dateKey(day);
    statuses.putIfAbsent(key, () => <String, String>{});
    if (mark == Mark.none) {
      statuses[key]!.remove(mealKey(meal));
      if (statuses[key]!.isEmpty) statuses.remove(key);
    } else {
      statuses[key]![mealKey(meal)] = markText(mark);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'rank': rank,
        'name': name,
        'group': group,
        'statuses': statuses,
      };

  static Person fromJson(Map<String, dynamic> map) {
    final rawStatuses = (map['statuses'] as Map?) ?? <String, dynamic>{};
    final parsed = <String, Map<String, String>>{};
    for (final entry in rawStatuses.entries) {
      final inner = <String, String>{};
      final source = (entry.value as Map?) ?? <String, dynamic>{};
      for (final item in source.entries) {
        inner[item.key.toString()] = item.value.toString();
      }
      parsed[entry.key.toString()] = inner;
    }
    return Person(
      id: map['id'].toString(),
      rank: map['rank'].toString(),
      name: map['name'].toString(),
      group: map['group'].toString(),
      statuses: parsed,
    );
  }
}

class AuditEntry {
  AuditEntry({
    required this.time,
    required this.actor,
    required this.personId,
    required this.personName,
    required this.group,
    required this.day,
    required this.meal,
    required this.oldValue,
    required this.newValue,
    required this.action,
  });

  final DateTime time;
  final String actor;
  final String personId;
  final String personName;
  final String group;
  final String day;
  final String meal;
  final String oldValue;
  final String newValue;
  final String action;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'time': time.toIso8601String(),
        'actor': actor,
        'personId': personId,
        'personName': personName,
        'group': group,
        'day': day,
        'meal': meal,
        'oldValue': oldValue,
        'newValue': newValue,
        'action': action,
      };

  static AuditEntry fromJson(Map<String, dynamic> map) => AuditEntry(
        time: DateTime.tryParse(map['time'].toString()) ?? DateTime.now(),
        actor: map['actor'].toString(),
        personId: map['personId'].toString(),
        personName: map['personName'].toString(),
        group: map['group'].toString(),
        day: map['day'].toString(),
        meal: map['meal'].toString(),
        oldValue: map['oldValue'].toString(),
        newValue: map['newValue'].toString(),
        action: map['action'].toString(),
      );
}

class AppController extends ChangeNotifier {
  static const groups = <String>['С-41', 'С-42', 'С-43', 'С-44', 'С-45'];

  static const Set<String> special190PlusNames = <String>{
    "Зінов'єв В.Е.",
    'Остапчук М.О.',
    'Несенюк І.В.',
    'Радовінчик І.О.',
    'Покормяхо В.І.',
    'Савченко Є.С.',
  };

  static String _normalizePersonName(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('ʼ', "'")
      .replaceAll('`', "'")
      .replaceAll(RegExp(r'\s+'), ' ');

  static final Set<String> _special190PlusKeys =
      special190PlusNames.map(_normalizePersonName).toSet();

  bool is190PlusPerson(Person person) =>
      _special190PlusKeys.contains(_normalizePersonName(person.name));

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  SharedPreferences? _prefs;
  AppApi? _api;
  String _sessionToken = '';
  List<Map<String, dynamic>> _pendingOps = <Map<String, dynamic>>[];

  AppUser? currentUser;
  ThemeMode themeMode = ThemeMode.dark;
  bool online = true;
  bool syncing = false;
  bool telegramLinked = false;
  String telegramName = '';
  int pendingChanges = 0;
  String apiUrl = '';
  String lastError = '';
  DateTime? lastSyncedAt;
  List<Person> people = <Person>[];
  List<AuditEntry> history = <AuditEntry>[];
  List<ManagedUser> managedUsers = <ManagedUser>[];
  bool managedUsersLoading = false;
  String managedUsersError = '';

  final UpdateService _updateService = UpdateService();
  String appVersion = '0.6.0';
  bool checkingUpdate = false;
  AppUpdateInfo? availableUpdate;
  bool updatePromptShown = false;
  String updateError = '';
  DateTime? lastUpdateCheck;

  final Map<String, AppUser> _demoUsers = <String, AppUser>{
    'admin': AppUser(
      login: 'admin',
      displayName: 'Адміністратор',
      role: UserRole.admin,
      groups: groups,
    ),
    'editor43': AppUser(
      login: 'editor43',
      displayName: 'Редактор С-43',
      role: UserRole.editor,
      groups: const <String>['С-43'],
    ),
    'duty': AppUser(
      login: 'duty',
      displayName: 'Черговий курсу',
      role: UserRole.duty,
      groups: groups,
    ),
  };

  bool get realBackend => apiUrl.trim().isNotEmpty;
  bool get canEdit => currentUser?.role != UserRole.duty;
  bool get isAdmin => currentUser?.role == UserRole.admin;

  String get backendLabel {
    if (!realBackend) return 'Демо-режим';
    if (currentUser == null) return 'Backend налаштований';
    if (!online) return 'Немає зв’язку';
    return 'Google Sheets підключено';
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      appVersion = await _updateService.currentVersion();
    } catch (_) {
      appVersion = '0.6.0';
    }

    final lastCheckRaw = _prefs?.getString('last_update_check') ?? '';
    lastUpdateCheck = DateTime.tryParse(lastCheckRaw);
    final cachedUpdateRaw = _prefs?.getString('cached_update_info') ?? '';
    if (cachedUpdateRaw.isNotEmpty) {
      try {
        final cached = AppUpdateInfo.fromJson(
          Map<String, dynamic>.from(jsonDecode(cachedUpdateRaw) as Map),
        );
        if (cached != null && UpdateService.compareVersions(cached.latestVersion, appVersion) > 0) {
          availableUpdate = cached;
        } else {
          await _prefs?.remove('cached_update_info');
        }
      } catch (_) {
        await _prefs?.remove('cached_update_info');
      }
    }

    final theme = _prefs?.getString('theme') ?? 'dark';
    themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
    telegramLinked = _prefs?.getBool('telegram_linked') ?? false;
    telegramName = _prefs?.getString('telegram_name') ?? '';
    apiUrl = _prefs?.getString('api_url') ?? '';
    _api = apiUrl.isEmpty ? null : AppApi(apiUrl);

    final peopleJson = _prefs?.getString('people');
    if (peopleJson != null && peopleJson.isNotEmpty) {
      final list = jsonDecode(peopleJson) as List<dynamic>;
      people = list
          .map((dynamic e) => Person.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (!realBackend) {
      people = _seedPeople();
      _seedStatuses();
      await _savePeople();
    }

    final historyJson = _prefs?.getString('history');
    if (historyJson != null && historyJson.isNotEmpty) {
      final list = jsonDecode(historyJson) as List<dynamic>;
      history = list
          .map((dynamic e) => AuditEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final pendingJson = _prefs?.getString('pending_ops');
    if (pendingJson != null && pendingJson.isNotEmpty) {
      final list = jsonDecode(pendingJson) as List<dynamic>;
      _pendingOps = list.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    pendingChanges = realBackend ? _pendingOps.length : (_prefs?.getInt('pending_changes') ?? 0);

    if (realBackend) {
      _sessionToken = await _secureStorage.read(key: 'c4_session_token') ?? '';
      if (_sessionToken.isNotEmpty) {
        try {
          _api!.token = _sessionToken;
          final response = await _api!.session();
          currentUser = _userFromMap(Map<String, dynamic>.from(response['user'] as Map));
          await syncNow();
        } catch (error) {
          lastError = error.toString();
          currentUser = null;
          _sessionToken = '';
          await _secureStorage.delete(key: 'c4_session_token');
        }
      }
    } else {
      online = _prefs?.getBool('online_demo') ?? true;
    }

    unawaited(checkForUpdates());
  }

  Future<AppUpdateInfo?> checkForUpdates({bool force = false}) async {
    if (checkingUpdate) return availableUpdate;
    final now = DateTime.now();
    if (!force && lastUpdateCheck != null && now.difference(lastUpdateCheck!) < const Duration(hours: 6)) {
      return availableUpdate;
    }

    checkingUpdate = true;
    updateError = '';
    notifyListeners();
    try {
      final info = await _updateService.checkForUpdate(currentVersion: appVersion);
      availableUpdate = info;
      lastUpdateCheck = now;
      await _prefs?.setString('last_update_check', now.toIso8601String());
      if (info == null) {
        await _prefs?.remove('cached_update_info');
      } else {
        await _prefs?.setString('cached_update_info', jsonEncode(info.toJson()));
        updatePromptShown = false;
      }
      return info;
    } catch (error) {
      updateError = error.toString();
      return availableUpdate;
    } finally {
      checkingUpdate = false;
      notifyListeners();
    }
  }

  void markUpdatePromptShown() {
    updatePromptShown = true;
  }

  Future<void> openAvailableUpdate() async {
    final info = availableUpdate;
    if (info == null) return;
    await _updateService.openDownload(info);
  }

  Future<void> openAvailableUpdateReleasePage() async {
    final info = availableUpdate;
    if (info == null) return;
    await _updateService.openReleasePage(info);
  }

  AppUser _userFromMap(Map<String, dynamic> map) {
    final roleRaw = map['role']?.toString() ?? 'duty';
    final role = roleRaw == 'admin'
        ? UserRole.admin
        : roleRaw == 'editor'
            ? UserRole.editor
            : UserRole.duty;
    final rawGroups = (map['groups'] as List?) ?? const <dynamic>[];
    return AppUser(
      login: map['login']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? map['login']?.toString() ?? '',
      role: role,
      groups: rawGroups.map((dynamic e) => e.toString()).toList(),
    );
  }

  Future<void> setApiUrl(String value) async {
    var normalized = value.trim();
    if (normalized.endsWith('/')) normalized = normalized.substring(0, normalized.length - 1);
    if (normalized.isNotEmpty && (!normalized.startsWith('https://script.google.com/') || !normalized.contains('/exec'))) {
      throw ApiException('Потрібне посилання Apps Script Web App, яке закінчується на /exec.');
    }
    apiUrl = normalized;
    _api = apiUrl.isEmpty ? null : AppApi(apiUrl);
    currentUser = null;
    _sessionToken = '';
    _pendingOps.clear();
    pendingChanges = 0;
    lastError = '';
    await _prefs?.setString('api_url', apiUrl);
    await _prefs?.remove('pending_ops');
    await _secureStorage.delete(key: 'c4_session_token');
    notifyListeners();
  }

  List<Person> _seedPeople() => <Person>[
        Person(id: 'p01', rank: 'ст. солдат', name: 'Матола О.В.', group: 'С-43'),
        Person(id: 'p02', rank: 'солдат', name: 'Пивовар Д.М.', group: 'С-43'),
        Person(id: 'p03', rank: 'мол. сержант', name: 'Гончар І.В.', group: 'С-43'),
        Person(id: 'p04', rank: 'солдат', name: 'Коляда В.В.', group: 'С-43'),
        Person(id: 'p05', rank: 'ст. солдат', name: 'Іваненко Т.Р.', group: 'С-41'),
        Person(id: 'p06', rank: 'солдат', name: 'Сидоренко М.П.', group: 'С-41'),
        Person(id: 'p07', rank: 'сержант', name: 'Коваленко О.В.', group: 'С-42'),
        Person(id: 'p08', rank: 'солдат', name: 'Бондарчук Д.С.', group: 'С-42'),
        Person(id: 'p09', rank: 'ст. солдат', name: 'Лесюк М.О.', group: 'С-44'),
        Person(id: 'p10', rank: 'солдат', name: 'Кулина М.О.', group: 'С-44'),
        Person(id: 'p11', rank: 'сержант', name: 'Галевський С.А.', group: 'С-45'),
        Person(id: 'p12', rank: 'солдат', name: 'Ільєнко В.С.', group: 'С-45'),
      ];

  void _seedStatuses() {
    final today = DateTime.now();
    if (people.length < 6) return;
    people[0].setMark(today, Meal.breakfast, Mark.k);
    people[0].setMark(today, Meal.lunch, Mark.k);
    people[1].setMark(today, Meal.breakfast, Mark.vd);
    people[1].setMark(today, Meal.lunch, Mark.vd);
    people[1].setMark(today, Meal.dinner, Mark.vd);
    people[2].setMark(today, Meal.dinner, Mark.sh);
    people[3].setMark(today, Meal.breakfast, Mark.v);
  }

  List<Person> get visiblePeople {
    final user = currentUser;
    if (user == null) return <Person>[];
    if (user.role == UserRole.admin || user.role == UserRole.duty) return people;
    return people.where((Person p) => user.groups.contains(p.group)).toList();
  }

  Future<bool> login(String login, String password, {bool remember = true}) async {
    lastError = '';
    if (realBackend) {
      try {
        final response = await _api!.login(login.trim(), password);
        _sessionToken = response['token']?.toString() ?? '';
        currentUser = _userFromMap(Map<String, dynamic>.from(response['user'] as Map));
        if (remember) {
          await _secureStorage.write(key: 'c4_session_token', value: _sessionToken);
        } else {
          await _secureStorage.delete(key: 'c4_session_token');
        }
        online = true;
        await syncNow();
        notifyListeners();
        return true;
      } catch (error) {
        lastError = error.toString();
        online = false;
        notifyListeners();
        return false;
      }
    }

    final user = _demoUsers[login.trim()];
    if (user == null) return false;
    final storedPassword = _prefs?.getString('demo_password_${user.login}');
    final expected = storedPassword ?? _defaultPassword(user.login);
    if (password != expected) return false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  String _defaultPassword(String login) {
    if (login == 'admin') return 'admin123';
    if (login == 'editor43') return 'editor123';
    return 'duty123';
  }

  Future<void> logout() async {
    if (realBackend) {
      try {
        await _api?.logout();
      } catch (_) {}
      _sessionToken = '';
      await _secureStorage.delete(key: 'c4_session_token');
    }
    currentUser = null;
    notifyListeners();
  }

  Future<bool> changeOwnPassword(String oldPassword, String newPassword) async {
    final user = currentUser;
    if (user == null) return false;
    if (realBackend) {
      if (newPassword.length < 10) return false;
      try {
        await _api!.changePassword(oldPassword: oldPassword, newPassword: newPassword);
        return true;
      } catch (error) {
        lastError = error.toString();
        notifyListeners();
        return false;
      }
    }
    if (newPassword.length < 6) return false;
    final storedPassword = _prefs?.getString('demo_password_${user.login}');
    if (oldPassword != (storedPassword ?? _defaultPassword(user.login))) return false;
    await _prefs?.setString('demo_password_${user.login}', newPassword);
    return true;
  }

  String _roleApiValue(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.editor:
        return 'editor';
      case UserRole.duty:
        return 'duty';
    }
  }

  Future<void> loadManagedUsers() async {
    if (!isAdmin) return;
    managedUsersLoading = true;
    managedUsersError = '';
    notifyListeners();

    if (!realBackend) {
      managedUsers = _demoUsers.values
          .map((AppUser user) => ManagedUser(
                login: user.login,
                displayName: user.displayName,
                role: user.role,
                groups: user.groups,
                disabled: false,
                activeSessions: user.login == currentUser?.login ? 1 : 0,
                createdAt: null,
                updatedAt: null,
              ))
          .toList();
      managedUsersLoading = false;
      notifyListeners();
      return;
    }

    try {
      _api!.token = _sessionToken;
      final response = await _api!.listUsers();
      final raw = (response['users'] as List?) ?? const <dynamic>[];
      managedUsers = raw
          .map((dynamic value) => ManagedUser.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList();
      online = true;
    } catch (error) {
      managedUsersError = error.toString();
      lastError = managedUsersError;
      online = false;
    } finally {
      managedUsersLoading = false;
      notifyListeners();
    }
  }

  Future<void> createManagedUser({
    required String login,
    required String displayName,
    required UserRole role,
    required List<String> groups,
    required String password,
  }) async {
    if (!isAdmin || !realBackend || _api == null) {
      throw ApiException('Керування користувачами доступне тільки адміністратору з підключеним backend.');
    }
    _api!.token = _sessionToken;
    await _api!.createUser(
      login: login.trim(),
      displayName: displayName.trim(),
      role: _roleApiValue(role),
      groups: role == UserRole.editor ? groups : AppController.groups,
      password: password,
    );
    await loadManagedUsers();
  }

  Future<void> updateManagedUser({
    required ManagedUser user,
    required String displayName,
    required UserRole role,
    required List<String> groups,
  }) async {
    if (!isAdmin || !realBackend || _api == null) {
      throw ApiException('Керування користувачами доступне тільки адміністратору з підключеним backend.');
    }
    _api!.token = _sessionToken;
    final response = await _api!.updateUser(
      login: user.login,
      displayName: displayName.trim(),
      role: _roleApiValue(role),
      groups: role == UserRole.editor ? groups : AppController.groups,
    );
    if (user.login == currentUser?.login && response['user'] is Map) {
      final updated = Map<String, dynamic>.from(response['user'] as Map);
      currentUser = _userFromMap(updated);
    }
    await loadManagedUsers();
  }

  Future<void> setManagedUserDisabled(ManagedUser user, bool disabled) async {
    if (!isAdmin || !realBackend || _api == null) {
      throw ApiException('Керування користувачами доступне тільки адміністратору з підключеним backend.');
    }
    _api!.token = _sessionToken;
    await _api!.setUserDisabled(login: user.login, disabled: disabled);
    await loadManagedUsers();
  }

  Future<int> resetManagedUserPassword(ManagedUser user, String newPassword) async {
    if (!isAdmin || !realBackend || _api == null) {
      throw ApiException('Керування користувачами доступне тільки адміністратору з підключеним backend.');
    }
    _api!.token = _sessionToken;
    final response = await _api!.resetUserPassword(login: user.login, newPassword: newPassword);
    await loadManagedUsers();
    return int.tryParse(response['terminatedSessions']?.toString() ?? '') ?? 0;
  }

  Future<int> terminateManagedUserSessions(ManagedUser user) async {
    if (!isAdmin || !realBackend || _api == null) {
      throw ApiException('Керування користувачами доступне тільки адміністратору з підключеним backend.');
    }
    _api!.token = _sessionToken;
    final response = await _api!.terminateUserSessions(user.login);
    await loadManagedUsers();
    return int.tryParse(response['terminatedSessions']?.toString() ?? '') ?? 0;
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    await _prefs?.setString('theme', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> setOnline(bool value) async {
    if (realBackend) {
      if (value) await syncNow();
      return;
    }
    online = value;
    await _prefs?.setBool('online_demo', value);
    if (value && pendingChanges > 0) {
      await syncNow();
    } else {
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    if (syncing) return;
    syncing = true;
    lastError = '';
    notifyListeners();

    if (realBackend) {
      if (currentUser == null || _api == null) {
        syncing = false;
        notifyListeners();
        return;
      }
      try {
        _api!.token = _sessionToken;
        await _flushPendingOps();
        final today = DateTime.now();
        final response = await _api!.sync(
          fromDate: dateKey(today.subtract(const Duration(days: 60))),
          toDate: dateKey(today.add(const Duration(days: 120))),
          groups: currentUser!.role == UserRole.editor ? currentUser!.groups : null,
        );
        final list = (response['people'] as List?) ?? const <dynamic>[];
        people = list
            .map((dynamic e) => Person.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        lastSyncedAt = DateTime.tryParse(response['syncedAt']?.toString() ?? '') ?? DateTime.now();
        online = true;
        await _savePeople();
      } catch (error) {
        online = false;
        lastError = error.toString();
      }
      pendingChanges = _pendingOps.length;
      syncing = false;
      await _savePendingOps();
      notifyListeners();
      return;
    }

    if (!online) {
      syncing = false;
      notifyListeners();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    pendingChanges = 0;
    await _prefs?.setInt('pending_changes', pendingChanges);
    syncing = false;
    notifyListeners();
  }

  Future<void> _flushPendingOps() async {
    if (!realBackend || _api == null || _pendingOps.isEmpty) return;
    _api!.token = _sessionToken;
    while (_pendingOps.isNotEmpty) {
      final op = _pendingOps.first;
      if (op['type'] == 'setStatus') {
        await _api!.setStatus(
          group: op['group'].toString(),
          personName: op['personName'].toString(),
          date: op['date'].toString(),
          meal: op['meal'].toString(),
          mark: op['mark'].toString(),
        );
      }
      _pendingOps.removeAt(0);
      await _savePendingOps();
    }
  }

  Future<void> _queueStatus(Person person, DateTime day, Meal meal, Mark mark) async {
    _pendingOps.add(<String, dynamic>{
      'type': 'setStatus',
      'group': person.group,
      'personName': person.name,
      'date': dateKey(day),
      'meal': mealKey(meal),
      'mark': markText(mark),
      'queuedAt': DateTime.now().toIso8601String(),
    });
    pendingChanges = _pendingOps.length;
    await _savePendingOps();
  }

  Future<void> _savePendingOps() async {
    pendingChanges = _pendingOps.length;
    await _prefs?.setString('pending_ops', jsonEncode(_pendingOps));
    await _prefs?.setInt('pending_changes', pendingChanges);
  }

  Future<void> setMark({
    required Person person,
    required DateTime day,
    required Meal meal,
    required Mark mark,
  }) async {
    if (!canEdit) return;
    if (currentUser?.role == UserRole.editor && !(currentUser?.groups.contains(person.group) ?? false)) return;
    final old = person.mark(day, meal);
    if (old == mark) return;

    person.setMark(day, meal, mark);
    history.insert(
      0,
      AuditEntry(
        time: DateTime.now(),
        actor: currentUser?.login ?? 'unknown',
        personId: person.id,
        personName: person.name,
        group: person.group,
        day: dateKey(day),
        meal: mealTitle(meal),
        oldValue: markText(old),
        newValue: markText(mark),
        action: 'STATUS_SET',
      ),
    );

    if (realBackend) {
      await _queueStatus(person, day, meal, mark);
      if (online) {
        try {
          await _flushPendingOps();
          online = true;
          lastError = '';
        } catch (error) {
          online = false;
          lastError = error.toString();
        }
      }
    } else if (!online) {
      pendingChanges++;
    }

    await _saveAll();
    notifyListeners();
  }

  Future<void> setWholeDay({
    required Person person,
    required DateTime day,
    required Mark mark,
  }) async {
    for (final meal in Meal.values) {
      await setMark(person: person, day: day, meal: meal, mark: mark);
    }
  }

  Future<void> bulkSet({
    required List<Person> selected,
    required DateTime start,
    required DateTime end,
    required Set<Meal> meals,
    required Mark mark,
  }) async {
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      for (final person in selected) {
        for (final meal in meals) {
          await setMark(person: person, day: cursor, meal: meal, mark: mark);
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  Future<void> updatePerson(Person person, String rank, String name) async {
    if (!canEdit) return;
    if (realBackend) {
      lastError = 'Редагування ПІБ/звання підключимо окремим безпечним модулем, щоб не пошкодити довідник рапортів.';
      notifyListeners();
      return;
    }
    final old = '${person.rank} | ${person.name}';
    person.rank = rank.trim();
    person.name = name.trim();
    history.insert(
      0,
      AuditEntry(
        time: DateTime.now(),
        actor: currentUser?.login ?? 'unknown',
        personId: person.id,
        personName: person.name,
        group: person.group,
        day: '',
        meal: '',
        oldValue: old,
        newValue: '${person.rank} | ${person.name}',
        action: 'PERSON_EDIT',
      ),
    );
    if (!online) pendingChanges++;
    await _saveAll();
    notifyListeners();
  }

  Future<Map<String, String>> calculationPreview(DateTime startDay, [DateTime? endDay]) async {
    final end = endDay ?? startDay;
    if (!realBackend || _api == null || currentUser == null) {
      return <String, String>{
        'message1': buildMessage1Range(startDay, end),
        'message2': buildMessage2Range(startDay, end),
      };
    }
    try {
      _api!.token = _sessionToken;
      final response = await _api!.calculationPreview(
        startDate: dateKey(startDay),
        endDate: dateKey(end),
      );
      online = true;
      lastError = '';
      final serverMessage1 = response['message1']?.toString() ?? '';
      return <String, String>{
        'message1': add190PlusToMessage1(serverMessage1, startDay, end),
        'message2': response['message2']?.toString() ?? '',
      };
    } catch (error) {
      online = false;
      lastError = error.toString();
      notifyListeners();
      return <String, String>{
        'message1': buildMessage1Range(startDay, end),
        'message2': buildMessage2Range(startDay, end),
      };
    }
  }

  Future<void> linkTelegramDemo() async {
    telegramLinked = true;
    telegramName = '@c4_demo';
    await _prefs?.setBool('telegram_linked', true);
    await _prefs?.setString('telegram_name', telegramName);
    notifyListeners();
  }

  Future<void> unlinkTelegram() async {
    telegramLinked = false;
    telegramName = '';
    await _prefs?.setBool('telegram_linked', false);
    await _prefs?.setString('telegram_name', '');
    notifyListeners();
  }

  Future<void> _savePeople() async {
    await _prefs?.setString('people', jsonEncode(people.map((Person p) => p.toJson()).toList()));
  }

  Future<void> _saveAll() async {
    await _savePeople();
    await _prefs?.setString('history', jsonEncode(history.take(500).map((AuditEntry e) => e.toJson()).toList()));
    await _prefs?.setInt('pending_changes', pendingChanges);
    if (realBackend) await _savePendingOps();
  }

  MealCounts countsFor(DateTime day, Meal meal, {String? group}) {
    final source = people.where((Person p) => group == null || p.group == group).toList();
    var k = 0;
    var k190Plus = 0;
    var v = 0;
    var sh = 0;
    var vd = 0;
    for (final person in source) {
      switch (person.mark(day, meal)) {
        case Mark.k:
          k++;
          if (is190PlusPerson(person)) k190Plus++;
          break;
        case Mark.v:
          v++;
          break;
        case Mark.sh:
          sh++;
          break;
        case Mark.vd:
          vd++;
          break;
        case Mark.none:
          break;
      }
    }
    return MealCounts(
      totalRoster: source.length,
      k: k,
      k190Plus: k190Plus,
      v: v,
      sh: sh,
      vd: vd,
    );
  }

  MealCounts countsForRange(DateTime start, DateTime end, Meal meal, {String? group}) {
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    var totalRoster = 0;
    var k = 0;
    var k190Plus = 0;
    var v = 0;
    var sh = 0;
    var vd = 0;

    while (!cursor.isAfter(last)) {
      final c = countsFor(cursor, meal, group: group);
      totalRoster += c.totalRoster;
      k += c.k;
      k190Plus += c.k190Plus;
      v += c.v;
      sh += c.sh;
      vd += c.vd;
      cursor = cursor.add(const Duration(days: 1));
    }

    return MealCounts(
      totalRoster: totalRoster,
      k: k,
      k190Plus: k190Plus,
      v: v,
      sh: sh,
      vd: vd,
    );
  }

  String _kLabel(MealCounts counts) {
    if (counts.k <= 0) return '';
    if (counts.k190Plus <= 0) return '${counts.k}К';
    return '${counts.k}К, з них ${counts.k190Plus} 190+';
  }

  String buildMessage1(DateTime day) {
    final lines = <String>[shortDate(day), ''];
    for (final meal in Meal.values) {
      final c = countsFor(day, meal);
      final eating = max(0, c.totalRoster - c.k - c.v - c.sh - c.vd);
      var line = '${mealTitle(meal)} - $eating';
      final kLabel = _kLabel(c);
      if (kLabel.isNotEmpty) line += ' ($kLabel)';
      final absences = <String>[];
      if (c.vd > 0) absences.add('${c.vd} відрядження');
      if (c.v > 0) absences.add('${c.v} відпустка');
      if (c.sh > 0) absences.add('${c.sh} шпиталь');
      if (absences.isNotEmpty) line += ' (${absences.join(', ')})';
      lines.add(line);
    }
    return lines.join('\n');
  }

  String buildMessage2(DateTime day) {
    final previous = day.subtract(const Duration(days: 1));
    final blocks = <String>[];
    blocks.add(_groupBlock(previous, Meal.dinner));
    blocks.add(_groupBlock(day, Meal.breakfast));
    blocks.add(_groupBlock(day, Meal.lunch));
    return blocks.join('\n\n');
  }

  String buildMessage1Range(DateTime start, DateTime end) {
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    if (cursor.isAfter(last)) return '';
    if (cursor == last) return buildMessage1(cursor);

    final blocks = <String>[];
    while (!cursor.isAfter(last)) {
      blocks.add(buildMessage1(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return blocks.join('\n\n');
  }

  String buildMessage2Range(DateTime start, DateTime end) {
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    if (cursor.isAfter(last)) return '';
    if (cursor == last) return buildMessage2(cursor);

    final blocks = <String>[];
    while (!cursor.isAfter(last)) {
      blocks.add(buildMessage2(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return blocks.join('\n\n');
  }

  String add190PlusToMessage1(String message, DateTime start, DateTime end) {
    if (message.trim().isEmpty) return message;

    final daysByLabel = <String, DateTime>{};
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      daysByLabel[shortDate(cursor)] = cursor;
      cursor = cursor.add(const Duration(days: 1));
    }

    var activeDay = DateTime(start.year, start.month, start.day);
    final lines = message.split('\n');
    final plainKPattern = RegExp(r'\((\d+)\s*К\)');

    for (var index = 0; index < lines.length; index++) {
      final trimmed = lines[index].trim();
      final labeledDay = daysByLabel[trimmed];
      if (labeledDay != null) {
        activeDay = labeledDay;
        continue;
      }

      for (final meal in Meal.values) {
        if (!trimmed.startsWith('${mealTitle(meal)} -')) continue;
        if (trimmed.contains('190+')) break;

        final counts = countsFor(activeDay, meal);
        if (counts.k190Plus <= 0) break;
        if (!plainKPattern.hasMatch(lines[index])) break;

        lines[index] = lines[index].replaceFirstMapped(
          plainKPattern,
          (match) => '(${match.group(1)}К, з них ${counts.k190Plus} 190+)',
        );
        break;
      }
    }

    return lines.join('\n');
  }

  String _groupBlock(DateTime day, Meal meal) {
    final lines = <String>['${mealTitle(meal)} ${shortDate(day)}'];
    var total = 0;
    for (final group in groups) {
      final c = countsFor(day, meal, group: group);
      final eating = max(0, c.totalRoster - c.k - c.v - c.sh - c.vd);
      total += eating;
      lines.add('$group - $eating');
    }
    lines.add('Всього: $total');
    return lines.join('\n');
  }
}

class MealCounts {
  const MealCounts({
    required this.totalRoster,
    required this.k,
    required this.k190Plus,
    required this.v,
    required this.sh,
    required this.vd,
  });
  final int totalRoster;
  final int k;
  final int k190Plus;
  final int v;
  final int sh;
  final int vd;
}

class C4FoodApp extends StatelessWidget {
  const C4FoodApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'С4 Харчування',
          themeMode: controller.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: AppUpdateGate(
            controller: controller,
            child: controller.currentUser == null
                ? LoginScreen(controller: controller)
                : HomeShell(controller: controller),
          ),
        );
      },
    );
  }
}

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.controller, required this.child});
  final AppController controller;
  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.controller.availableUpdate;
    if (info != null && !widget.controller.updatePromptShown && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showAppUpdateDialog(context, widget.controller, info);
        widget.controller.markUpdatePromptShown();
        _scheduled = false;
      });
    }
    return widget.child;
  }
}

Future<void> showAppUpdateDialog(
  BuildContext context,
  AppController controller,
  AppUpdateInfo info,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !info.mandatory,
    builder: (BuildContext dialogContext) => PopScope(
      canPop: !info.mandatory,
      child: AlertDialog(
        title: Row(children: <Widget>[
          const Icon(Icons.system_update_alt_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text('Доступне оновлення v${info.latestVersion}')),
        ]),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Встановлена версія: v${controller.appVersion}'),
              if (info.mandatory) ...<Widget>[
                const SizedBox(height: 10),
                const Row(children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: AppTheme.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Це оновлення обов’язкове для подальшої роботи.')),
                ]),
              ],
              if (info.notes.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                const Text('Що нового:', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                for (final note in info.notes.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      const Text('• '),
                      Expanded(child: Text(note)),
                    ]),
                  ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Windows завантажить Setup.exe, Android — APK, macOS — DMG. Встановлення підтверджує користувач.',
                style: TextStyle(fontSize: 11, color: Color(0xFF91A8BC)),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          if (!info.mandatory)
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Пізніше')),
          TextButton(
            onPressed: () async {
              try {
                await controller.openAvailableUpdateReleasePage();
              } catch (error) {
                if (dialogContext.mounted) showAppNotice(dialogContext, error.toString());
              }
            },
            child: const Text('Що нового'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await controller.openAvailableUpdate();
                if (!info.mandatory && dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                if (dialogContext.mounted) showAppNotice(dialogContext, error.toString());
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Оновити'),
          ),
        ],
      ),
    ),
  );
}

class AppTheme {
  static const navy = Color(0xFF061321);
  static const panel = Color(0xFF0C2235);
  static const panel2 = Color(0xFF102A41);
  static const blue = Color(0xFF1B8DF2);
  static const gold = Color(0xFFF2A31B);
  static const green = Color(0xFF20B56B);
  static const orange = Color(0xFFF29A1F);
  static const purple = Color(0xFF7448EF);
  static const red = Color(0xFFFF6F73);

  static ThemeData _base(Brightness brightness) {
    final darkMode = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
      surface: darkMode ? panel : const Color(0xFFFFFFFF),
    );
    final divider = darkMode ? const Color(0xFF1A3850) : const Color(0xFFD7E2EB);
    final field = darkMode ? const Color(0xFF102A41) : const Color(0xFFF1F6FA);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: darkMode ? navy : const Color(0xFFF0F5F9),
      colorScheme: scheme,
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: darkMode ? panel : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: divider),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: TextStyle(color: darkMode ? const Color(0xFF91A8BC) : const Color(0xFF6E8295)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          side: BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: darkMode ? const Color(0xFF071827) : Colors.white,
        indicatorColor: blue.withValues(alpha: .17),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? blue : null,
            )),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: divider),
        selectedColor: blue,
        secondarySelectedColor: blue,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(darkMode ? const Color(0xFF0A2032) : const Color(0xFFF0F5F9)),
        dividerThickness: 1,
        columnSpacing: 22,
        headingTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: darkMode ? const Color(0xFF91A8BC) : const Color(0xFF60778B),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static final ThemeData dark = _base(Brightness.dark);
  static final ThemeData light = _base(Brightness.light);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool busy = false;
  bool remember = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    if (!widget.controller.realBackend) {
      loginController.text = 'admin';
      passwordController.text = 'admin123';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.25,
            colors: <Color>[Color(0xFF103B5C), Color(0xFF071A2A), Color(0xFF05111D)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: <Widget>[
                  const AppLogo(size: 72),
                  const SizedBox(height: 18),
                  const Text('С4 Харчування', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 5),
                  const Text('Система обліку харчування', style: TextStyle(color: Color(0xFF91A8BC))),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: widget.controller.realBackend ? const Color(0xFF123C2D) : const Color(0xFF27394B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Icon(widget.controller.realBackend ? Icons.cloud_done_outlined : Icons.science_outlined, size: 16, color: widget.controller.realBackend ? const Color(0xFF4BE19A) : const Color(0xFF9AB0C2)),
                      const SizedBox(width: 7),
                      Text(widget.controller.backendLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2438),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF244056)),
                      boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x99000000), blurRadius: 42, offset: Offset(0, 22))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: loginController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'Логін', prefixIcon: Icon(Icons.person_outline)),
                        ),
                        const SizedBox(height: 11),
                        TextField(
                          controller: passwordController,
                          obscureText: obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Пароль',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => obscure = !obscure),
                              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        if (error.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 9),
                          Text(error, style: const TextStyle(color: Color(0xFFFF8187))),
                        ],
                        const SizedBox(height: 8),
                        Row(children: <Widget>[
                          Checkbox(value: remember, onChanged: (value) => setState(() => remember = value ?? true)),
                          const Text('Запам’ятати мене', style: TextStyle(color: Color(0xFFC4D2DE), fontSize: 12)),
                        ]),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: busy ? null : _login,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: busy
                                ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Увійти'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _configureBackend,
                          icon: const Icon(Icons.dns_outlined, size: 18),
                          label: Text(widget.controller.realBackend ? 'Змінити сервер' : 'Підключити Google Sheets'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.controller.realBackend
                        ? 'Backend v0.4 · авторизація та ролі через Apps Script'
                        : 'Демо: admin / admin123',
                    style: const TextStyle(color: Color(0xFF66849C), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _configureBackend() async {
    final field = TextEditingController(text: widget.controller.apiUrl);
    final save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Підключення до Apps Script'),
        content: SizedBox(
          width: 540,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
            const Text('Встав Web App URL, який закінчується на /exec.'),
            const SizedBox(height: 12),
            TextField(controller: field, decoration: const InputDecoration(labelText: 'https://script.google.com/macros/s/.../exec')),
          ]),
        ),
        actions: <Widget>[
          if (widget.controller.realBackend)
            TextButton(onPressed: () { field.text = ''; Navigator.pop(context, true); }, child: const Text('Повернути демо')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Зберегти')),
        ],
      ),
    );
    if (save != true) return;
    try {
      await widget.controller.setApiUrl(field.text);
      if (!mounted) return;
      setState(() {
        error = '';
        loginController.clear();
        passwordController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  Future<void> _login() async {
    setState(() {
      busy = true;
      error = '';
    });
    final ok = await widget.controller.login(loginController.text, passwordController.text, remember: remember);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (!ok) error = widget.controller.lastError.isNotEmpty ? widget.controller.lastError : 'Невірний логін або пароль.';
    });
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 46});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0E3856), Color(0xFF09243B)],
        ),
        borderRadius: BorderRadius.circular(size * .23),
        border: Border.all(color: const Color(0xFF315069).withValues(alpha: .7)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: size * .22, offset: Offset(0, size * .08))],
      ),
      alignment: Alignment.center,
      child: Text('🔱', style: TextStyle(fontSize: size * .52, height: 1)),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selected = 0;

  List<NavDestination> get destinations {
    final role = widget.controller.currentUser!.role;
    final common = <NavDestination>[
      NavDestination('Головна', Icons.home_outlined, Icons.home_rounded, () => DashboardScreen(controller: widget.controller, onNavigate: _navigateByTitle)),
    ];
    if (role != UserRole.duty) {
      common.addAll(<NavDestination>[
        NavDestination('Особовий склад', Icons.groups_2_outlined, Icons.groups_2_rounded, () => PersonnelScreen(controller: widget.controller)),
        NavDestination('Статуси', Icons.fact_check_outlined, Icons.fact_check_rounded, () => StatusesScreen(controller: widget.controller)),
      ]);
    }
    common.add(NavDestination('Розрахунки', Icons.bar_chart_outlined, Icons.bar_chart_rounded, () => CalculationScreen(controller: widget.controller)));
    if (role != UserRole.duty) {
      common.addAll(<NavDestination>[
        NavDestination('Шпиталь', Icons.local_hospital_outlined, Icons.local_hospital_rounded, () => AbsenceOverviewScreen(controller: widget.controller, mark: Mark.sh)),
        NavDestination('Відрядження', Icons.work_outline_rounded, Icons.work_rounded, () => AbsenceOverviewScreen(controller: widget.controller, mark: Mark.vd)),
        NavDestination('Документи', Icons.description_outlined, Icons.description_rounded, () => DocumentsScreen(controller: widget.controller)),
      ]);
    }
    if (role == UserRole.admin) {
      common.addAll(<NavDestination>[
        NavDestination('Користувачі', Icons.manage_accounts_outlined, Icons.manage_accounts_rounded, () => UsersScreen(controller: widget.controller)),
        NavDestination('Історія змін', Icons.history_outlined, Icons.history_rounded, () => HistoryScreen(controller: widget.controller)),
      ]);
    }
    common.add(NavDestination('Налаштування', Icons.settings_outlined, Icons.settings_rounded, () => SettingsScreen(controller: widget.controller)));
    return common;
  }

  void _navigateByTitle(String title) {
    final index = destinations.indexWhere((NavDestination d) => d.title == title);
    if (index >= 0) setState(() => selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final items = destinations;
    if (selected >= items.length) selected = 0;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final desktop = constraints.maxWidth >= 920;
        final content = items[selected].page();
        if (!desktop) {
          final bottom = items.take(4).toList();
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 58,
              titleSpacing: 12,
              title: const Row(
                children: <Widget>[
                  AppLogo(size: 34),
                  SizedBox(width: 10),
                  Text('С4 Харчування', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              actions: <Widget>[
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
                const SizedBox(width: 4),
              ],
            ),
            body: SafeArea(child: content),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selected < 4 ? selected : 4,
              onDestinationSelected: (int index) {
                if (index < bottom.length) {
                  setState(() => selected = index);
                } else {
                  _showMore(context, items);
                }
              },
              destinations: <NavigationDestination>[
                for (final d in bottom)
                  NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.title),
                const NavigationDestination(icon: Icon(Icons.menu_rounded), label: 'Ще'),
              ],
            ),
          );
        }

        final dark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          body: Row(
            children: <Widget>[
              Container(
                width: 255,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF061522) : Colors.white,
                  border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Column(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 6, 8, 16),
                      child: Row(
                        children: <Widget>[
                          AppLogo(size: 46),
                          SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('С4 Харчування', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                SizedBox(height: 2),
                                Text('Система обліку харчування', style: TextStyle(fontSize: 10, color: Color(0xFF8198AA))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (BuildContext context, int index) {
                          final item = items[index];
                          final active = index == selected;
                          return Material(
                            color: active ? const Color(0xFF155F9D) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => setState(() => selected = index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                child: Row(
                                  children: <Widget>[
                                    Icon(active ? item.selectedIcon : item.icon, size: 19, color: active ? Colors.white : null),
                                    const SizedBox(width: 11),
                                    Expanded(child: Text(item.title, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? Colors.white : null))),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    UserCard(controller: widget.controller),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
                      child: Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 310,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Пошук по ПІБ...',
                                prefixIcon: Icon(Icons.search_rounded, size: 20),
                                isDense: true,
                              ),
                            ),
                          ),
                          const Spacer(),
                          SyncBadge(controller: widget.controller),
                          const SizedBox(width: 10),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
                          IconButton(
                            tooltip: 'Змінити тему',
                            onPressed: () => widget.controller.setTheme(widget.controller.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
                            icon: Icon(widget.controller.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                          ),
                          IconButton(onPressed: widget.controller.syncNow, icon: const Icon(Icons.sync_rounded)),
                        ],
                      ),
                    ),
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMore(BuildContext context, List<NavDestination> items) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (var i = 4; i < items.length; i++)
              ListTile(
                leading: Icon(items[i].icon),
                title: Text(items[i].title),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selected = i);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class NavDestination {
  NavDestination(this.title, this.icon, this.selectedIcon, this.page);
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() page;
}

class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final color = !controller.online
        ? AppTheme.orange
        : controller.syncing
            ? const Color(0xFF4DA5FF)
            : const Color(0xFF2BD278);
    final title = !controller.online
        ? 'Офлайн${controller.pendingChanges > 0 ? ' · ${controller.pendingChanges}' : ''}'
        : controller.syncing
            ? 'Синхронізація...'
            : 'Синхронізовано';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: controller.online ? controller.syncNow : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: .2), blurRadius: 8, spreadRadius: 2)],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                Text(controller.online ? 'Сьогодні, 12:24' : 'Зміни збережено локально', style: const TextStyle(fontSize: 9, color: Color(0xFF8198AA))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser!;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: <Widget>[
        const CircleAvatar(radius: 17, child: Icon(Icons.person_outline, size: 19)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(user.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          Text(roleTitle(user.role), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF91A8BC), fontSize: 10)),
        ])),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFF91A8BC)),
      ]),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, this.subtitle, required this.child, this.actions = const <Widget>[]});
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 10,
              children: <Widget>[
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.7)),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(color: Color(0xFF91A8BC), fontSize: 14)),
                  ],
                ]),
                if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
            const SizedBox(height: 19),
            child,
          ]),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller, required this.onNavigate});
  final AppController controller;
  final void Function(String title) onNavigate;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return PageFrame(
      title: 'С4 Харчування',
      subtitle: 'Система обліку та розрахунку харчування С-4',
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(longDate(today)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final width = c.maxWidth;
              final columns = width >= 1120 ? 7 : width >= 760 ? 4 : 2;
              final cardWidth = (width - (columns - 1) * 11) / columns;
              return Wrap(
                spacing: 11,
                runSpacing: 11,
                children: <Widget>[
                  QuickActionCard(width: cardWidth, colors: const <Color>[Color(0xFF259C61), Color(0xFF147D4B)], icon: Icons.calendar_today_rounded, title: 'На сьогодні', subtitle: 'Розрахунок за сьогодні', onTap: () => onNavigate('Розрахунки')),
                  QuickActionCard(width: cardWidth, colors: const <Color>[Color(0xFF268DF0), Color(0xFF1268C2)], icon: Icons.arrow_forward_rounded, title: 'На завтра', subtitle: 'Розрахунок на завтра', onTap: () => onNavigate('Розрахунки')),
                  if (controller.currentUser?.role != UserRole.duty)
                    QuickActionCard(width: cardWidth, colors: const <Color>[Color(0xFF7858EF), Color(0xFF5B37D5)], icon: Icons.edit_calendar_rounded, title: 'Проставити статуси', subtitle: 'Відкрити таблицю', onTap: () => onNavigate('Статуси')),
                  QuickActionCard(width: cardWidth, colors: const <Color>[Color(0xFFF5A01C), Color(0xFFDF7C0D)], icon: Icons.bar_chart_rounded, title: 'Розрахунки', subtitle: 'Дата або період', onTap: () => onNavigate('Розрахунки')),
                  if (controller.currentUser?.role != UserRole.duty)
                    QuickActionCard(width: cardWidth, colors: const <Color>[Color(0xFF455F76), Color(0xFF30485E)], icon: Icons.table_chart_rounded, title: 'Місячний Excel', subtitle: 'Формування звіту', onTap: () => onNavigate('Документи')),
                  if (controller.currentUser?.role != UserRole.duty)
                    QuickActionCard(width: cardWidth, colors: const <Color>[Color(0xFF455F76), Color(0xFF30485E)], icon: Icons.description_rounded, title: 'Рапорти', subtitle: 'На компенсацію', onTap: () => onNavigate('Документи')),
                  QuickActionCard(
                    width: cardWidth,
                    colors: const <Color>[Color(0xFF258CF1), Color(0xFF1166BD)],
                    icon: Icons.send_rounded,
                    title: 'Мій Telegram',
                    subtitle: controller.telegramLinked ? controller.telegramName : 'Прив’язати акаунт',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TelegramScreen(controller: controller))),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              if (c.maxWidth < 900) {
                return Column(
                  children: <Widget>[
                    SizedBox(width: double.infinity, child: RecentActionsPanel(controller: controller)),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: TodayStatsPanel(controller: controller, day: today)),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: GroupsPanel(controller: controller)),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 9, child: RecentActionsPanel(controller: controller)),
                  const SizedBox(width: 12),
                  Expanded(flex: 13, child: TodayStatsPanel(controller: controller, day: today)),
                  const SizedBox(width: 12),
                  Expanded(flex: 7, child: GroupsPanel(controller: controller)),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF123B2A),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFF23553F)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF75E7A6), size: 28),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Дані синхронізовано', style: TextStyle(color: Color(0xFFDFFBEA), fontWeight: FontWeight.w800)),
                      Text('Усі зміни збережено в хмарі', style: TextStyle(color: Color(0xFF9FCEB3), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({super.key, required this.width, required this.colors, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final double width;
  final List<Color> colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 112,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[BoxShadow(color: colors.last.withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Stack(
              children: <Widget>[
                Positioned(right: -24, top: -28, child: Container(width: 88, height: 88, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), shape: BoxShape.circle))),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(icon, color: Colors.white, size: 25),
                      const Spacer(),
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TodayStatsPanel extends StatelessWidget {
  const TodayStatsPanel({super.key, required this.controller, required this.day});
  final AppController controller;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Статистика на сьогодні', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('С-4 (всі групи)', style: TextStyle(fontSize: 10, color: Color(0xFF8198AA))),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                if (c.maxWidth < 520) {
                  return Column(
                    children: <Widget>[
                      for (final meal in Meal.values) ...<Widget>[
                        SizedBox(width: double.infinity, child: MealStatCard(controller: controller, day: day, meal: meal)),
                        if (meal != Meal.values.last) const SizedBox(height: 9),
                      ],
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    for (final meal in Meal.values) ...<Widget>[
                      Expanded(child: MealStatCard(controller: controller, day: day, meal: meal)),
                      if (meal != Meal.values.last) const SizedBox(width: 9),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MealStatCard extends StatelessWidget {
  const MealStatCard({super.key, required this.controller, required this.day, required this.meal});
  final AppController controller;
  final DateTime day;
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final c = controller.countsFor(day, meal);
    final eating = max(0, c.totalRoster - c.k - c.v - c.sh - c.vd);
    final icon = meal == Meal.breakfast ? Icons.restaurant_rounded : meal == Meal.lunch ? Icons.lunch_dining_rounded : Icons.nights_stay_rounded;
    final accent = meal == Meal.breakfast ? const Color(0xFF49A8FF) : meal == Meal.lunch ? const Color(0xFFFFB51F) : const Color(0xFFFFD15C);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.panel2 : const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[Icon(icon, color: accent, size: 19), const SizedBox(width: 7), Expanded(child: Text(mealTitle(meal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))]),
          const SizedBox(height: 11),
          Text('$eating', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 5),
          Text('${c.k} К', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 11),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 9),
          _mini('Відрядження', c.vd),
          _mini('Відпустка', c.v),
          _mini('Шпиталь', c.sh),
        ],
      ),
    );
  }

  Widget _mini(String title, int value) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(children: <Widget>[Expanded(child: Text(title, style: const TextStyle(fontSize: 10))), Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10))]),
      );
}

class RecentActionsPanel extends StatelessWidget {
  const RecentActionsPanel({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final fallback = <Map<String, String>>[
      <String, String>{'name': 'Матола О.В.', 'detail': 'С-43 · Обід · К', 'time': '12:24'},
      <String, String>{'name': 'Пивовар Д.М.', 'detail': 'С-42 · Весь день · Вд', 'time': '11:58'},
      <String, String>{'name': 'Коляда В.В.', 'detail': 'С-44 · Сніданок · В', 'time': '10:32'},
      <String, String>{'name': 'Гончар І.В.', 'detail': 'С-43 · Вечеря · Ш', 'time': '09:17'},
    ];
    final rows = controller.history.take(4).map((AuditEntry e) => <String, String>{
          'name': e.personName,
          'detail': '${e.group} · ${e.meal} · ${e.newValue}',
          'time': '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}',
        }).toList();
    final data = rows.isEmpty ? fallback : rows;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Останні дії', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (var i = 0; i < data.length; i++) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF184C36), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6DE0A2))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(data[i]['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 2), Text(data[i]['detail']!, style: const TextStyle(color: Color(0xFF8198AA), fontSize: 10))])),
                    Text(data[i]['time']!, style: const TextStyle(color: Color(0xFF8198AA), fontSize: 9)),
                  ],
                ),
              ),
              if (i != data.length - 1) Divider(height: 1, color: Theme.of(context).dividerColor),
            ],
          ],
        ),
      ),
    );
  }
}

class GroupsPanel extends StatelessWidget {
  const GroupsPanel({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    const colors = <Color>[Color(0xFF1D7BD2), Color(0xFF1A9959), Color(0xFFDB8717), Color(0xFF6F4ADC), Color(0xFFD14D54)];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Групи', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('Всього: ${controller.people.length}', style: const TextStyle(color: Color(0xFF8198AA), fontSize: 10)),
            const SizedBox(height: 8),
            for (var i = 0; i < AppController.groups.length; i++) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: <Widget>[
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(7)), child: Text(AppController.groups[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10))),
                    const Spacer(),
                    Text('${controller.people.where((Person p) => p.group == AppController.groups[i]).length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 17, color: Color(0xFF8198AA)),
                  ],
                ),
              ),
              if (i != AppController.groups.length - 1) Divider(height: 1, color: Theme.of(context).dividerColor),
            ],
          ],
        ),
      ),
    );
  }
}

class AbsenceOverviewScreen extends StatelessWidget {
  const AbsenceOverviewScreen({super.key, required this.controller, required this.mark});
  final AppController controller;
  final Mark mark;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final title = mark == Mark.sh ? 'Шпиталь' : 'Відрядження';
    final filtered = controller.visiblePeople.where((Person p) {
      for (final meal in Meal.values) {
        if (p.mark(today, meal) == mark) return true;
      }
      return false;
    }).toList();
    return PageFrame(
      title: title,
      subtitle: 'Окремий облік по групах та особах',
      actions: <Widget>[
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined), label: Text(longDate(today))),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final total = filtered.length;
              final cards = <Widget>[
                _absenceMetric(context, title, total, mark == Mark.sh ? Icons.local_hospital_rounded : Icons.work_rounded, mark == Mark.sh ? AppTheme.red : AppTheme.blue),
                for (final group in AppController.groups.take(2))
                  _absenceMetric(
                    context,
                    group,
                    filtered.where((Person p) => p.group == group).length,
                    Icons.groups_2_rounded,
                    const Color(0xFF455F76),
                  ),
              ];
              if (c.maxWidth < 650) {
                return Column(children: <Widget>[for (final card in cards) ...<Widget>[SizedBox(width: double.infinity, child: card), const SizedBox(height: 10)]]);
              }
              return Row(children: <Widget>[for (var i = 0; i < cards.length; i++) ...<Widget>[Expanded(child: cards[i]), if (i != cards.length - 1) const SizedBox(width: 10)]]);
            },
          ),
          const SizedBox(height: 14),
          Card(
            child: filtered.isEmpty
                ? const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('На сьогодні записів немає.')))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
                    itemBuilder: (BuildContext context, int index) {
                      final person = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (mark == Mark.sh ? AppTheme.red : AppTheme.blue).withValues(alpha: .16),
                          child: Icon(mark == Mark.sh ? Icons.local_hospital_rounded : Icons.work_rounded, color: mark == Mark.sh ? AppTheme.red : AppTheme.blue),
                        ),
                        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${person.rank} · ${person.group}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: (mark == Mark.sh ? AppTheme.red : AppTheme.blue).withValues(alpha: .14), borderRadius: BorderRadius.circular(8)),
                          child: Text(markText(mark), style: TextStyle(color: mark == Mark.sh ? AppTheme.red : const Color(0xFF70B8FF), fontWeight: FontWeight.w900)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _absenceMetric(BuildContext context, String label, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text('$value', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Color(0xFF8198AA))),
        ]),
      ),
    );
  }
}

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  String search = '';
  String group = 'Всі';

  @override
  Widget build(BuildContext context) {
    final allowedGroups = widget.controller.currentUser?.role == UserRole.editor ? widget.controller.currentUser!.groups : AppController.groups;
    final filtered = widget.controller.visiblePeople.where((Person p) {
      final groupOk = group == 'Всі' || p.group == group;
      final searchOk = '${p.name} ${p.rank}'.toLowerCase().contains(search.toLowerCase());
      return groupOk && searchOk;
    }).toList();
    return PageFrame(
      title: 'Особовий склад',
      subtitle: 'ПІБ, звання та групи',
      child: Column(children: <Widget>[
        Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
          SizedBox(width: 330, child: TextField(onChanged: (String value) => setState(() => search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Пошук за ПІБ або званням'))),
          DropdownButton<String>(value: group, items: <String>['Всі', ...allowedGroups].map((String g) => DropdownMenuItem<String>(value: g, child: Text(g))).toList(), onChanged: (String? value) => setState(() => group = value ?? 'Всі')),
        ]),
        const SizedBox(height: 14),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final person = filtered[index];
              return ListTile(
                leading: CircleAvatar(child: Text(person.group.substring(person.group.length - 2))),
                title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${person.rank} · ${person.group}'),
                trailing: widget.controller.canEdit && !widget.controller.realBackend ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editPerson(person)) : (widget.controller.realBackend ? const Tooltip(message: 'Редагування ПІБ/звання буде у v0.4', child: Icon(Icons.lock_outline, size: 19)) : null),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _editPerson(Person person) async {
    final name = TextEditingController(text: person.name);
    final rank = TextEditingController(text: person.rank);
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Редагувати · ${person.group}'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            TextField(controller: name, decoration: const InputDecoration(labelText: 'ПІБ')),
            const SizedBox(height: 12),
            TextField(controller: rank, decoration: const InputDecoration(labelText: 'Звання')),
          ]),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Зберегти')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && rank.text.trim().isNotEmpty) {
      await widget.controller.updatePerson(person, rank.text, name.text);
    }
  }
}

class StatusesScreen extends StatefulWidget {
  const StatusesScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<StatusesScreen> createState() => _StatusesScreenState();
}

class _StatusesScreenState extends State<StatusesScreen> {
  DateTime day = DateTime.now();
  String group = '';
  String search = '';
  Mark filter = Mark.none;
  final Set<String> selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    final allowed = widget.controller.currentUser?.role == UserRole.editor ? widget.controller.currentUser!.groups : AppController.groups;
    group = allowed.first;
  }

  @override
  Widget build(BuildContext context) {
    final allowedGroups = widget.controller.currentUser?.role == UserRole.editor ? widget.controller.currentUser!.groups : AppController.groups;
    final list = widget.controller.visiblePeople.where((Person p) {
      if (p.group != group) return false;
      if (!p.name.toLowerCase().contains(search.toLowerCase())) return false;
      if (filter == Mark.none) return true;
      return Meal.values.any((Meal meal) => p.mark(day, meal) == filter);
    }).toList();
    return PageFrame(
      title: 'Статуси',
      subtitle: 'К · В · Ш · Вд',
      actions: <Widget>[
        OutlinedButton.icon(onPressed: () async {
          final picked = await showDatePicker(context: context, initialDate: day, firstDate: DateTime(2025), lastDate: DateTime(2035));
          if (picked != null) setState(() => day = picked);
        }, icon: const Icon(Icons.calendar_today_outlined), label: Text(longDate(day))),
        FilledButton.icon(onPressed: selectedIds.isEmpty ? null : _bulkDialog, icon: const Icon(Icons.playlist_add_check), label: Text('Масово · ${selectedIds.length}')),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Wrap(spacing: 8, runSpacing: 8, children: allowedGroups.map((String g) => ChoiceChip(label: Text(g), selected: group == g, onSelected: (_) => setState(() { group = g; selectedIds.clear(); }))).toList()),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
          SizedBox(width: 330, child: TextField(onChanged: (String value) => setState(() => search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Пошук по ПІБ'))),
          DropdownButton<Mark>(
            value: filter,
            items: const <DropdownMenuItem<Mark>>[
              DropdownMenuItem(value: Mark.none, child: Text('Всі статуси')),
              DropdownMenuItem(value: Mark.k, child: Text('Тільки К')),
              DropdownMenuItem(value: Mark.v, child: Text('Тільки В')),
              DropdownMenuItem(value: Mark.sh, child: Text('Тільки Ш')),
              DropdownMenuItem(value: Mark.vd, child: Text('Тільки Вд')),
            ],
            onChanged: (Mark? value) => setState(() => filter = value ?? Mark.none),
          ),
        ]),
        const SizedBox(height: 14),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('')),
                DataColumn(label: Text('ПІБ')),
                DataColumn(label: Text('Звання')),
                DataColumn(label: Text('Сніданок')),
                DataColumn(label: Text('Обід')),
                DataColumn(label: Text('Вечеря')),
                DataColumn(label: Text('Дії')),
              ],
              rows: list.map((Person person) {
                return DataRow(cells: <DataCell>[
                  DataCell(Checkbox(value: selectedIds.contains(person.id), onChanged: widget.controller.canEdit ? (bool? value) => setState(() { if (value == true) { selectedIds.add(person.id); } else { selectedIds.remove(person.id); } }) : null)),
                  DataCell(Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(Text(person.rank)),
                  for (final meal in Meal.values)
                    DataCell(MarkButton(mark: person.mark(day, meal), enabled: widget.controller.canEdit, onTap: () => _pickMark(person, meal))),
                  DataCell(PopupMenuButton<String>(
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem(value: 'day', child: Text('Поставити на весь день')),
                      PopupMenuItem(value: 'clear', child: Text('Очистити весь день')),
                    ],
                    onSelected: widget.controller.canEdit ? (String value) => _wholeDay(person, value == 'clear' ? Mark.none : null) : null,
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickMark(Person person, Meal meal) async {
    final old = person.mark(day, meal);
    final chosen = await showMarkPicker(context, old);
    if (chosen == null || chosen == old) return;
    await widget.controller.setMark(person: person, day: day, meal: meal, mark: chosen);
    if (!mounted) return;
    showAppNotice(
      context,
      '${person.name}: ${mealTitle(meal)} → ${markText(chosen).isEmpty ? 'очищено' : markText(chosen)}',
      action: SnackBarAction(
        label: 'Скасувати',
        onPressed: () => widget.controller.setMark(person: person, day: day, meal: meal, mark: old),
      ),
    );
  }

  Future<void> _wholeDay(Person person, Mark? directMark) async {
    final mark = directMark ?? await showMarkPicker(context, Mark.none);
    if (mark == null) return;
    await widget.controller.setWholeDay(person: person, day: day, mark: mark);
  }

  Future<void> _bulkDialog() async {
    final chosenPeople = widget.controller.visiblePeople.where((Person p) => selectedIds.contains(p.id)).toList();
    Mark mark = Mark.vd;
    DateTime start = day;
    DateTime end = day;
    final meals = <Meal>{...Meal.values};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setLocal) => AlertDialog(
          title: Text('Масова зміна · ${chosenPeople.length} осіб'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                DropdownButtonFormField<Mark>(
                  initialValue: mark,
                  decoration: const InputDecoration(labelText: 'Статус'),
                  items: const <DropdownMenuItem<Mark>>[
                    DropdownMenuItem(value: Mark.k, child: Text('К')),
                    DropdownMenuItem(value: Mark.v, child: Text('В')),
                    DropdownMenuItem(value: Mark.sh, child: Text('Ш')),
                    DropdownMenuItem(value: Mark.vd, child: Text('Вд')),
                    DropdownMenuItem(value: Mark.none, child: Text('Очистити')),
                  ],
                  onChanged: (Mark? value) => setLocal(() => mark = value ?? Mark.none),
                ),
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  Expanded(child: OutlinedButton(onPressed: () async { final value = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2025), lastDate: DateTime(2035)); if (value != null) setLocal(() => start = value); }, child: Text('Від ${longDate(start)}'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () async { final value = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2025), lastDate: DateTime(2035)); if (value != null) setLocal(() => end = value); }, child: Text('До ${longDate(end)}'))),
                ]),
                const SizedBox(height: 12),
                for (final meal in Meal.values)
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: meals.contains(meal), title: Text(mealTitle(meal)), onChanged: (bool? value) => setLocal(() { if (value == true) { meals.add(meal); } else { meals.remove(meal); } })),
              ]),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Скасувати')),
            FilledButton(onPressed: meals.isEmpty || end.isBefore(start) ? null : () => Navigator.pop(dialogContext, true), child: const Text('Застосувати')),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await widget.controller.bulkSet(selected: chosenPeople, start: start, end: end, meals: meals, mark: mark);
      if (mounted) showAppNotice(context, 'Масові зміни застосовано.');
    }
  }
}

class MarkButton extends StatelessWidget {
  const MarkButton({super.key, required this.mark, required this.enabled, required this.onTap});
  final Mark mark;
  final bool enabled;
  final VoidCallback onTap;

  Color _color(BuildContext context) {
    switch (mark) {
      case Mark.k:
        return Colors.green;
      case Mark.v:
        return Colors.amber;
      case Mark.sh:
        return Colors.redAccent;
      case Mark.vd:
        return Colors.blueAccent;
      case Mark.none:
        return Theme.of(context).colorScheme.outline.withValues(alpha: .35);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: mark == Mark.none ? color.withValues(alpha: .15) : color.withValues(alpha: .2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: .5))),
        child: Text(mark == Mark.none ? '—' : markText(mark), style: TextStyle(color: mark == Mark.none ? null : color, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

Future<Mark?> showMarkPicker(BuildContext context, Mark current) {
  return showModalBottomSheet<Mark>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const Text('Оберіть статус', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
            for (final mark in <Mark>[Mark.k, Mark.v, Mark.sh, Mark.vd, Mark.none])
              SizedBox(width: 110, child: FilledButton.tonal(onPressed: () => Navigator.pop(context, mark), child: Text(mark == Mark.none ? 'Очистити' : markText(mark)))),
          ]),
        ]),
      ),
    ),
  );
}

class CalculationScreen extends StatefulWidget {
  const CalculationScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends State<CalculationScreen> {
  DateTime startDay = DateTime.now();
  DateTime endDay = DateTime.now();
  String message1 = '';
  String message2 = '';
  String error = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = ''; });
    final result = await widget.controller.calculationPreview(startDay, endDay);
    if (!mounted) return;
    setState(() {
      message1 = result['message1'] ?? '';
      message2 = result['message2'] ?? '';
      loading = false;
      error = widget.controller.realBackend && !widget.controller.online ? widget.controller.lastError : '';
    });
  }

  Future<void> _setPeriod(DateTime start, DateTime end) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    setState(() {
      startDay = normalizedStart;
      endDay = normalizedEnd.isBefore(normalizedStart) ? normalizedStart : normalizedEnd;
    });
    await _load();
  }

  Future<void> _setSingleDay(DateTime value) => _setPeriod(value, value);

  Future<void> _setPresetDays(int days) {
    final today = DateTime.now();
    return _setPeriod(today, today.add(Duration(days: days - 1)));
  }

  bool _isPresetFromToday(int days) {
    final today = DateTime.now();
    return _sameDay(startDay, today) &&
        _sameDay(endDay, today.add(Duration(days: days - 1)));
  }

  Future<void> _pickStartDay() async {
    final value = await showDatePicker(
      context: context,
      initialDate: startDay,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );
    if (value == null) return;
    await _setPeriod(value, endDay.isBefore(value) ? value : endDay);
  }

  Future<void> _pickEndDay() async {
    final value = await showDatePicker(
      context: context,
      initialDate: endDay.isBefore(startDay) ? startDay : endDay,
      firstDate: startDay,
      lastDate: DateTime(2035),
    );
    if (value == null) return;
    await _setPeriod(startDay, value);
  }

  @override
  Widget build(BuildContext context) {
    final shown1 = message1.isEmpty ? widget.controller.buildMessage1Range(startDay, endDay) : message1;
    final shown2 = message2.isEmpty ? widget.controller.buildMessage2Range(startDay, endDay) : message2;
    return PageFrame(
      title: 'Розрахунок',
      subtitle: widget.controller.realBackend ? 'Розрахунок із Google Sheets / FAST CACHE' : 'Демо-розрахунок',
      actions: <Widget>[
        _segmentButton(
          'Сьогодні',
          _sameDay(startDay, DateTime.now()) && _sameDay(endDay, DateTime.now()),
          () => _setSingleDay(DateTime.now()),
        ),
        _segmentButton(
          'Завтра',
          _sameDay(startDay, DateTime.now().add(const Duration(days: 1))) &&
              _sameDay(endDay, DateTime.now().add(const Duration(days: 1))),
          () => _setSingleDay(DateTime.now().add(const Duration(days: 1))),
        ),
        _segmentButton('3 дні', _isPresetFromToday(3), () => _setPresetDays(3)),
        _segmentButton('7 днів', _isPresetFromToday(7), () => _setPresetDays(7)),
        OutlinedButton.icon(
          onPressed: loading ? null : _pickStartDay,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text('З ${shortDate(startDay)}'),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : _pickEndDay,
          icon: const Icon(Icons.event_available_outlined),
          label: Text('По ${shortDate(endDay)}'),
        ),
        IconButton(onPressed: loading ? null : _load, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded)),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        if (error.isNotEmpty) ...<Widget>[
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: <Widget>[
            const Icon(Icons.cloud_off_rounded, color: AppTheme.orange),
            const SizedBox(width: 10),
            Expanded(child: Text('Сервер недоступний. Показано локальну копію.\n$error')),
          ]))),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final messages = Column(
              children: <Widget>[
                MessageCard(
                  title: 'Повідомлення №1',
                  badge: widget.controller.realBackend ? 'Google Sheets' : 'Демо',
                  text: shown1,
                  actions: <Widget>[
                    FilledButton.icon(
                      onPressed: widget.controller.realBackend
                          ? null
                          : (widget.controller.telegramLinked ? _telegramDemo : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TelegramScreen(controller: widget.controller)))),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(widget.controller.realBackend ? 'Telegram · v0.4' : (widget.controller.telegramLinked ? 'Надіслати' : 'Прив’язати Telegram')),
                    ),
                    OutlinedButton.icon(onPressed: () => _copy(shown1), icon: const Icon(Icons.copy_rounded, size: 18), label: const Text('Копіювати №1')),
                    OutlinedButton.icon(onPressed: () => Share.share(shown1), icon: const Icon(Icons.share_rounded, size: 18), label: const Text('Поділитися')),
                  ],
                ),
                const SizedBox(height: 12),
                MessageCard(
                  title: 'Повідомлення №2',
                  badge: 'Групи',
                  text: shown2,
                  actions: <Widget>[
                    OutlinedButton.icon(onPressed: () => _copy(shown2), icon: const Icon(Icons.copy_rounded, size: 18), label: const Text('Копіювати №2')),
                    OutlinedButton.icon(onPressed: () => _copy('$shown1\n\n$shown2'), icon: const Icon(Icons.copy_all_rounded, size: 18), label: const Text('Копіювати все')),
                    OutlinedButton.icon(onPressed: () => Share.share(shown2), icon: const Icon(Icons.share_rounded, size: 18), label: const Text('Поділитися №2')),
                  ],
                ),
              ],
            );
            final summary = CalculationSummary(
              controller: widget.controller,
              startDay: startDay,
              endDay: endDay,
            );
            if (c.maxWidth < 820) {
              return Column(children: <Widget>[messages, const SizedBox(height: 12), SizedBox(width: double.infinity, child: summary)]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(flex: 12, child: messages), const SizedBox(width: 14), Expanded(flex: 7, child: summary)]);
          },
        ),
      ]),
    );
  }

  Widget _segmentButton(String label, bool selected, VoidCallback onPressed) {
    return selected ? FilledButton(onPressed: onPressed, child: Text(label)) : OutlinedButton(onPressed: onPressed, child: Text(label));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showAppNotice(context, 'Скопійовано.');
  }

  void _telegramDemo() {
    showAppNotice(context, 'Демо: два повідомлення поставлено в чергу Telegram.');
  }
}

class MessageCard extends StatelessWidget {
  const MessageCard({super.key, required this.title, required this.badge, required this.text, required this.actions});
  final String title;
  final String badge;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(children: <Widget>[
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF173653), borderRadius: BorderRadius.circular(7)),
                child: Text(badge, style: const TextStyle(color: Color(0xFF8FC7FF), fontWeight: FontWeight.w800, fontSize: 10)),
              ),
            ]),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.55)),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 8, runSpacing: 8, children: actions),
          ),
        ],
      ),
    );
  }
}

class CalculationSummary extends StatelessWidget {
  const CalculationSummary({
    super.key,
    required this.controller,
    required this.startDay,
    required this.endDay,
  });
  final AppController controller;
  final DateTime startDay;
  final DateTime endDay;

  @override
  Widget build(BuildContext context) {
    final breakfast = controller.countsForRange(startDay, endDay, Meal.breakfast);
    final lunch = controller.countsForRange(startDay, endDay, Meal.lunch);
    final dinner = controller.countsForRange(startDay, endDay, Meal.dinner);
    final dayCount = DateTime(endDay.year, endDay.month, endDay.day)
            .difference(DateTime(startDay.year, startDay.month, startDay.day))
            .inDays +
        1;
    int eat(MealCounts c) => max(0, c.totalRoster - c.k - c.v - c.sh - c.vd);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  dayCount == 1 ? 'Підсумок' : 'Підсумок за період · $dayCount дн.',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _row(context, 'Сніданок', eat(breakfast)),
                _row(context, 'Обід', eat(lunch)),
                _row(context, 'Вечеря', eat(dinner)),
                _row(context, 'Відрядження', breakfast.vd),
                _row(context, 'Відпустка', breakfast.v),
                _row(context, 'Шпиталь', breakfast.sh, last: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF123B2A), border: Border.all(color: const Color(0xFF23553F)), borderRadius: BorderRadius.circular(13)),
          child: const Row(children: <Widget>[
            Icon(Icons.bolt_rounded, color: Color(0xFF75E7A6)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text('FAST CACHE', style: TextStyle(color: Color(0xFFDFFBEA), fontWeight: FontWeight.w800)),
              Text('Дані актуальні · кеш готовий', style: TextStyle(color: Color(0xFF9FCEB3), fontSize: 10)),
            ])),
          ]),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String title, int value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(children: <Widget>[Expanded(child: Text(title)), Text('$value', style: const TextStyle(fontWeight: FontWeight.w800))]),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Документи',
      subtitle: 'Рапорти Word та місячний Excel',
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
        final wide = c.maxWidth > 720;
        final cards = <Widget>[
          DocumentCard(
            icon: Icons.description_outlined,
            title: 'Рапорт на компенсацію',
            subtitle: controller.isAdmin ? 'Генерація + налаштування шапки' : 'Генерація для дозволеної групи',
            badge: 'DOCX',
            onGenerate: () => _demo(context, 'Рапорт сформовано у демо-режимі.'),
          ),
          DocumentCard(
            icon: Icons.table_chart_outlined,
            title: 'Місячний Excel',
            subtitle: 'У місячний Excel переноситься тільки К',
            badge: 'XLSX',
            onGenerate: () => _demo(context, 'Місячний Excel сформовано у демо-режимі.'),
          ),
        ];
        if (wide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: cards[0]), const SizedBox(width: 14), Expanded(child: cards[1])]);
        return Column(children: <Widget>[cards[0], const SizedBox(height: 14), cards[1]]);
      }),
    );
  }

  void _demo(BuildContext context, String text) => showAppNotice(context, text);
}

class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.icon, required this.title, required this.subtitle, required this.badge, required this.onGenerate});
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[Icon(icon, size: 34), const Spacer(), Chip(label: Text(badge))]),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: onGenerate, icon: const Icon(Icons.auto_awesome), label: const Text('Сформувати')),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
            OutlinedButton.icon(onPressed: onGenerate, icon: const Icon(Icons.open_in_new), label: const Text('Відкрити')),
            OutlinedButton.icon(onPressed: onGenerate, icon: const Icon(Icons.download_outlined), label: const Text('Завантажити')),
            OutlinedButton.icon(onPressed: onGenerate, icon: const Icon(Icons.send_outlined), label: const Text('Telegram')),
          ]),
        ]),
      ),
    );
  }
}


class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key, required this.controller, required this.mark, required this.title});
  final AppController controller;
  final Mark mark;
  final String title;

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  DateTime day = DateTime.now();
  String group = 'Всі';
  String search = '';

  @override
  Widget build(BuildContext context) {
    final availableGroups = widget.controller.currentUser?.role == UserRole.editor
        ? widget.controller.currentUser!.groups
        : AppController.groups;
    final people = widget.controller.visiblePeople.where((p) {
      final groupOk = group == 'Всі' || p.group == group;
      final searchOk = p.name.toLowerCase().contains(search.toLowerCase());
      final hasMark = Meal.values.any((meal) => p.mark(day, meal) == widget.mark);
      return groupOk && searchOk && hasMark;
    }).toList();

    return PageFrame(
      title: widget.title,
      subtitle: 'Список особового складу зі статусом ${markText(widget.mark)}',
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: () async {
            final value = await showDatePicker(context: context, initialDate: day, firstDate: DateTime(2025), lastDate: DateTime(2035));
            if (value != null) setState(() => day = value);
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(longDate(day)),
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (value) => setState(() => search = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Пошук по ПІБ...'),
            ),
          ),
          DropdownButton<String>(
            value: group,
            items: <String>['Всі', ...availableGroups].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (value) => setState(() => group = value ?? 'Всі'),
          ),
        ]),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
              Row(children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (widget.mark == Mark.sh ? AppTheme.red : AppTheme.gold).withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.mark == Mark.sh ? Icons.local_hospital_outlined : Icons.luggage_outlined, color: widget.mark == Mark.sh ? AppTheme.red : AppTheme.gold),
                ),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('Всього: ${people.length}', style: const TextStyle(fontSize: 10, color: Color(0xFF91A8BC))),
                ])),
              ]),
              const SizedBox(height: 8),
              if (people.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('За вибраними параметрами людей немає.')))
              else
                for (final person in people)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(person.name.isEmpty ? '?' : person.name[0])),
                    title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${person.group} · ${person.rank}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.controller.loadManagedUsers());
  }

  String _roleLabel(UserRole role) => roleTitle(role);

  String _accessLabel(ManagedUser user) {
    if (user.role == UserRole.admin) return 'Усі групи';
    if (user.role == UserRole.duty) return 'Перегляд усіх груп';
    return user.groups.isEmpty ? 'Без груп' : user.groups.join(', ');
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    try {
      await action();
      if (!mounted) return;
      if (success != null) {
        showAppNotice(context, success);
      }
    } catch (error) {
      if (!mounted) return;
      showAppNotice(
        context,
        error.toString(),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _openUserDialog({ManagedUser? user}) async {
    final isNew = user == null;
    final loginController = TextEditingController(text: user?.login ?? '');
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final passwordController = TextEditingController();
    var role = user?.role ?? UserRole.editor;
    final selectedGroups = <String>{...(user?.groups ?? const <String>['С-43'])};
    var obscurePassword = true;
    String localError = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setLocal) => AlertDialog(
          title: Text(isNew ? 'Додати користувача' : 'Редагувати ${user.login}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: loginController,
                    enabled: isNew,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Логін', hintText: 'наприклад: editor43'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Ім’я / назва'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Роль'),
                    items: UserRole.values
                        .map((UserRole value) => DropdownMenuItem<UserRole>(
                              value: value,
                              child: Text(_roleLabel(value)),
                            ))
                        .toList(),
                    onChanged: (UserRole? value) {
                      if (value == null) return;
                      setLocal(() {
                        role = value;
                        if (role == UserRole.editor && selectedGroups.isEmpty) {
                          selectedGroups.add('С-43');
                        }
                      });
                    },
                  ),
                  if (role == UserRole.editor) ...<Widget>[
                    const SizedBox(height: 14),
                    const Text('Дозволені групи', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: AppController.groups.map((String group) {
                        final selected = selectedGroups.contains(group);
                        return FilterChip(
                          label: Text(group),
                          selected: selected,
                          onSelected: (bool value) {
                            setLocal(() {
                              if (value) {
                                selectedGroups.add(group);
                              } else {
                                selectedGroups.remove(group);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  if (isNew) ...<Widget>[
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Тимчасовий пароль',
                        helperText: 'Мінімум 10 символів',
                        suffixIcon: IconButton(
                          onPressed: () => setLocal(() => obscurePassword = !obscurePassword),
                          icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                  ],
                  if (localError.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(localError, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Роль і доступ до груп перевіряються на сервері, а не лише в інтерфейсі.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF91A8BC)),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Скасувати')),
            FilledButton(
              onPressed: () {
                final login = loginController.text.trim();
                final name = nameController.text.trim();
                final password = passwordController.text;
                String error = '';
                if (isNew && login.length < 4) {
                  error = 'Логін має містити щонайменше 4 символи.';
                } else if (name.isEmpty) {
                  error = 'Вкажіть ім’я/назву користувача.';
                } else if (role == UserRole.editor && selectedGroups.isEmpty) {
                  error = 'Виберіть хоча б одну групу.';
                } else if (isNew && password.length < 10) {
                  error = 'Пароль має містити щонайменше 10 символів.';
                }
                if (error.isNotEmpty) {
                  setLocal(() => localError = error);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(isNew ? 'Створити' : 'Зберегти'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (isNew) {
        await _run(
          () => widget.controller.createManagedUser(
            login: loginController.text,
            displayName: nameController.text,
            role: role,
            groups: selectedGroups.toList(),
            password: passwordController.text,
          ),
          success: 'Користувача створено.',
        );
      } else {
        await _run(
          () => widget.controller.updateManagedUser(
            user: user,
            displayName: nameController.text,
            role: role,
            groups: selectedGroups.toList(),
          ),
          success: 'Дані користувача оновлено.',
        );
      }
    }

    loginController.dispose();
    nameController.dispose();
    passwordController.dispose();
  }

  Future<void> _resetPassword(ManagedUser user) async {
    final controller = TextEditingController();
    var obscure = true;
    String error = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setLocal) => AlertDialog(
          title: Text('Скинути пароль · ${user.login}'),
          content: SizedBox(
            width: 430,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Новий тимчасовий пароль',
                  helperText: 'Мінімум 10 символів. Поточний пароль адміністратор не бачить.',
                  suffixIcon: IconButton(
                    onPressed: () => setLocal(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              if (error.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ]),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Скасувати')),
            FilledButton(
              onPressed: () {
                if (controller.text.length < 10) {
                  setLocal(() => error = 'Пароль має містити щонайменше 10 символів.');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Скинути пароль'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _run(() async {
        final count = await widget.controller.resetManagedUserPassword(user, controller.text);
        if (!mounted) return;
        showAppNotice(context, 'Пароль скинуто. Завершено сесій: $count.');
      });
    }
    controller.dispose();
  }

  Future<void> _toggleBlocked(ManagedUser user) async {
    final targetDisabled = !user.disabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(targetDisabled ? 'Заблокувати ${user.login}?' : 'Розблокувати ${user.login}?'),
        content: Text(
          targetDisabled
              ? 'Користувач більше не зможе увійти. Його активні сесії будуть завершені.'
              : 'Користувач знову зможе входити зі своїм поточним паролем.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(targetDisabled ? 'Заблокувати' : 'Розблокувати')),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(
        () => widget.controller.setManagedUserDisabled(user, targetDisabled),
        success: targetDisabled ? 'Користувача заблоковано.' : 'Користувача розблоковано.',
      );
    }
  }

  Future<void> _terminateSessions(ManagedUser user) async {
    await _run(() async {
      final count = await widget.controller.terminateManagedUserSessions(user);
      if (!mounted) return;
      showAppNotice(context, 'Завершено сесій користувача ${user.login}: $count.');
    });
  }

  Widget _status(ManagedUser user) {
    final active = !user.disabled;
    return Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Icon(Icons.circle, size: 9, color: active ? const Color(0xFF50D990) : AppTheme.red),
      const SizedBox(width: 6),
      Text(active ? 'Активний' : 'Заблокований'),
    ]);
  }

  Widget _actions(ManagedUser user) {
    final self = user.login == widget.controller.currentUser?.login;
    return PopupMenuButton<String>(
      tooltip: 'Дії',
      onSelected: (String value) async {
        if (value == 'edit') await _openUserDialog(user: user);
        if (value == 'reset') await _resetPassword(user);
        if (value == 'sessions') await _terminateSessions(user);
        if (value == 'block') await _toggleBlocked(user);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Редагувати'), contentPadding: EdgeInsets.zero)),
        if (!self)
          const PopupMenuItem<String>(value: 'reset', child: ListTile(leading: Icon(Icons.password_outlined), title: Text('Скинути пароль'), contentPadding: EdgeInsets.zero)),
        if (!self)
          const PopupMenuItem<String>(value: 'sessions', child: ListTile(leading: Icon(Icons.phonelink_erase_outlined), title: Text('Завершити сесії'), contentPadding: EdgeInsets.zero)),
        if (!self)
          PopupMenuItem<String>(
            value: 'block',
            child: ListTile(
              leading: Icon(user.disabled ? Icons.lock_open_outlined : Icons.block_outlined),
              title: Text(user.disabled ? 'Розблокувати' : 'Заблокувати'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
      child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.more_horiz)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final users = c.managedUsers;
    return PageFrame(
      title: 'Користувачі',
      subtitle: 'Реальні акаунти, ролі та серверні права доступу',
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: c.managedUsersLoading ? null : c.loadManagedUsers,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Оновити'),
        ),
        FilledButton.icon(
          onPressed: !c.realBackend ? null : () => _openUserDialog(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Додати користувача'),
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        if (!c.realBackend)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Для реального керування користувачами підключіть Apps Script backend v0.4.'),
            ),
          ),
        if (c.managedUsersError.isNotEmpty) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: <Widget>[
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                Expanded(child: Text(c.managedUsersError)),
                TextButton(onPressed: c.loadManagedUsers, child: const Text('Повторити')),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (c.managedUsersLoading && users.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator())))
        else if (users.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Користувачів не знайдено.'))))
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  children: users.map((ManagedUser user) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          CircleAvatar(child: Text(user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase())),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              Row(children: <Widget>[
                                Expanded(child: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                                _actions(user),
                              ]),
                              Text('@${user.login}', style: const TextStyle(color: Color(0xFF91A8BC))),
                              const SizedBox(height: 8),
                              Wrap(spacing: 7, runSpacing: 7, children: <Widget>[
                                Chip(label: Text(_roleLabel(user.role))),
                                Chip(label: Text(_accessLabel(user))),
                                Chip(label: Text('Сесій: ${user.activeSessions}')),
                              ]),
                              const SizedBox(height: 6),
                              _status(user),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  )).toList(),
                );
              }

              return Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Користувач')),
                      DataColumn(label: Text('Роль')),
                      DataColumn(label: Text('Доступ')),
                      DataColumn(label: Text('Сесії')),
                      DataColumn(label: Text('Статус')),
                      DataColumn(label: Text('')),
                    ],
                    rows: users.map((ManagedUser user) => DataRow(cells: <DataCell>[
                      DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text('@${user.login}', style: const TextStyle(fontSize: 11, color: Color(0xFF91A8BC))),
                      ])),
                      DataCell(Text(_roleLabel(user.role))),
                      DataCell(Text(_accessLabel(user))),
                      DataCell(Text('${user.activeSessions}')),
                      DataCell(_status(user)),
                      DataCell(_actions(user)),
                    ])).toList(),
                  ),
                ),
              );
            },
          ),
      ]),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.controller.history.where((AuditEntry e) => '${e.actor} ${e.personName} ${e.group} ${e.newValue} ${e.action}'.toLowerCase().contains(search.toLowerCase())).toList();
    return PageFrame(
      title: 'Історія змін',
      subtitle: 'Доступно тільки адміністраторам',
      child: Column(children: <Widget>[
        TextField(onChanged: (String value) => setState(() => search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Користувач, ПІБ, група, статус...')),
        const SizedBox(height: 14),
        Card(
          child: list.isEmpty
              ? const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Історія поки порожня.')))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final e = list[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.history)),
                      title: Text('${e.personName} · ${e.group}'),
                      subtitle: Text('${e.actor} · ${e.day} ${e.meal}\n${e.oldValue.isEmpty ? '—' : e.oldValue} → ${e.newValue.isEmpty ? '—' : e.newValue}'),
                      isThreeLine: true,
                      trailing: Text('${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}'),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class TelegramScreen extends StatelessWidget {
  const TelegramScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final code = 100000 + Random().nextInt(899999);
    return Scaffold(
      appBar: AppBar(title: const Text('Мій Telegram')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: <Widget>[
                  Icon(controller.telegramLinked ? Icons.check_circle : Icons.send_outlined, size: 64, color: controller.telegramLinked ? Colors.green : Colors.blue),
                  const SizedBox(height: 14),
                  Text(controller.telegramLinked ? 'Telegram підключено' : 'Telegram не підключено', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (controller.telegramLinked) ...<Widget>[
                    Text(controller.telegramName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(onPressed: controller.unlinkTelegram, icon: const Icon(Icons.link_off), label: const Text('Відв’язати')),
                  ] else ...<Widget>[
                    const Text('У production цей одноразовий код надсилається боту. У демо-режимі кнопка нижче імітує успішну прив’язку.'),
                    const SizedBox(height: 16),
                    SelectableText('$code', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 4)),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: controller.linkTelegramDemo, icon: const Icon(Icons.link), label: const Text('Імітувати прив’язку')),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser!;
    final syncSubtitle = controller.realBackend
        ? (controller.online
            ? 'Google Sheets · ${controller.pendingChanges == 0 ? 'синхронізовано' : 'черга ${controller.pendingChanges}'}'
            : 'Офлайн · черга ${controller.pendingChanges}')
        : (controller.online ? 'Онлайн (демо)' : 'Офлайн · черга ${controller.pendingChanges}');
    return PageFrame(
      title: 'Налаштування',
      subtitle: '${user.displayName} · ${roleTitle(user.role)}',
      child: Column(children: <Widget>[
        Card(child: Column(children: <Widget>[
          ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('Тема'), subtitle: Text(controller.themeMode == ThemeMode.dark ? 'Темна' : 'Світла'), trailing: Switch(value: controller.themeMode == ThemeMode.dark, onChanged: (bool value) => controller.setTheme(value ? ThemeMode.dark : ThemeMode.light))),
          const Divider(height: 1),
          ListTile(
            leading: Icon(controller.realBackend ? Icons.cloud_done_outlined : Icons.science_outlined),
            title: Text(controller.realBackend ? 'Backend / Google Sheets' : 'Демо-режим'),
            subtitle: Text(controller.realBackend ? controller.apiUrl : 'Реальний сервер ще не підключений'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _configureBackend(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(controller.online ? Icons.sync_rounded : Icons.cloud_off_rounded),
            title: const Text('Синхронізація'),
            subtitle: Text(syncSubtitle),
            trailing: controller.syncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded),
            onTap: controller.syncing ? null : controller.syncNow,
          ),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.send_outlined), title: const Text('Мій Telegram'), subtitle: Text(controller.realBackend ? 'Персональне підключення буде у v0.6' : (controller.telegramLinked ? controller.telegramName : 'Не підключено')), onTap: controller.realBackend ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TelegramScreen(controller: controller)))),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.password_outlined), title: const Text('Змінити пароль'), onTap: () => _changePassword(context)),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('Оновлення застосунку'),
            subtitle: Text(
              controller.availableUpdate != null
                  ? 'v${controller.appVersion} → доступна v${controller.availableUpdate!.latestVersion}'
                  : 'v${controller.appVersion} · актуальна версія',
            ),
            trailing: controller.checkingUpdate
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: controller.checkingUpdate
                ? null
                : () async {
                    final info = await controller.checkForUpdates(force: true);
                    if (!context.mounted) return;
                    if (info == null) {
                      showAppNotice(
                        context,
                        controller.updateError.isEmpty
                            ? 'У вас остання версія v${controller.appVersion}.'
                            : 'Не вдалося перевірити оновлення: ${controller.updateError}',
                      );
                      return;
                    }
                    await showAppUpdateDialog(context, controller, info);
                    controller.markUpdatePromptShown();
                  },
          ),
        ])),
        if (controller.isAdmin) ...<Widget>[
          const SizedBox(height: 14),
          const Card(child: Column(children: <Widget>[
            ListTile(leading: Icon(Icons.manage_accounts_outlined), title: Text('Користувачі та ролі'), subtitle: Text('Керування користувачами та серверні обмеження працюють')), 
            Divider(height: 1),
            ListTile(leading: Icon(Icons.article_outlined), title: Text('Шапки та підписанти'), subtitle: Text('Поточні налаштування Apps Script не змінювались')),
          ])),
        ],
        if (controller.lastError.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            const Icon(Icons.warning_amber_rounded, color: AppTheme.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(controller.lastError)),
          ]))),
        ],
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: controller.logout, icon: const Icon(Icons.logout), label: const Text('Вийти'))),
      ]),
    );
  }

  Future<void> _configureBackend(BuildContext context) async {
    final field = TextEditingController(text: controller.apiUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Backend URL'),
        content: SizedBox(width: 540, child: TextField(controller: field, decoration: const InputDecoration(labelText: 'Apps Script Web App /exec URL'))),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Зберегти')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await controller.setApiUrl(field.text);
      if (!context.mounted) return;
      showAppNotice(context, 'Backend змінено. Увійдіть повторно.');
    } catch (e) {
      if (!context.mounted) return;
      showAppNotice(context, e.toString());
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final old = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Змінити пароль'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'Поточний пароль')),
          const SizedBox(height: 10),
          TextField(controller: next, obscureText: true, decoration: InputDecoration(labelText: controller.realBackend ? 'Новий пароль · мін. 10 символів' : 'Новий пароль · мін. 6 символів')),
        ])),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Змінити')),
        ],
      ),
    );
    if (ok == true) {
      final success = await controller.changeOwnPassword(old.text, next.text);
      if (!context.mounted) return;
      showAppNotice(
        context,
        success
            ? 'Пароль змінено.'
            : (controller.lastError.isNotEmpty
                ? controller.lastError
                : 'Перевір поточний пароль і довжину нового.'),
      );
    }
  }
}

