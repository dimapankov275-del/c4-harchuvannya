/**
 * C4 Харчування v0.4 — API для Windows / Android / macOS клієнта.
 *
 * Додається ДО ІСНУЮЧОГО Apps Script проєкту v3.23 FAST CACHE.
 * Не змінює зовнішній вигляд Google Таблиці і не створює службових аркушів.
 *
 * Публічні функції:
 *   setupC4AppBackendV03()         — одноразове створення адміністратора.
 *   c4AppResetAllSessionsV03()     — завершити всі сесії застосунку.
 *
 * Web App:
 *   doGet  — health check.
 *   doPost — JSON API.
 */

const C4_APP_V03 = Object.freeze({
  VERSION: '0.4.0',
  USER_STORE_KEY: 'C4_APP_V03_USERS',
  PEPPER_KEY: 'C4_APP_V03_PEPPER',
  SESSION_PREFIX: 'C4_APP_V03_SESSION_',
  FAIL_PREFIX: 'C4_APP_V03_FAIL_',
  SESSION_TTL_MS: 30 * 24 * 60 * 60 * 1000,
  PASSWORD_ROUNDS: 4096,
  MAX_FAILS: 6,
  FAIL_TTL_SECONDS: 600,
  GROUPS: ['С-41', 'С-42', 'С-43', 'С-44', 'С-45'],
  DATE_ROW: 1,
  MEAL_ROW: 2,
  START_ROW: 3,
  FIRST_DATE_COLUMN: 4,
});

function doGet(e) {
  return c4AppJsonV03_({
    ok: true,
    service: 'C4 Харчування API',
    version: C4_APP_V03.VERSION,
    time: new Date().toISOString(),
  });
}

function doPost(e) {
  try {
    const body = c4AppParseBodyV03_(e);
    const action = String(body.action || '').trim();

    if (!action) throw new Error('Не вказано action.');

    if (action === 'login') {
      return c4AppJsonV03_({ok: true, data: c4AppLoginV03_(body)});
    }

    const session = c4AppRequireSessionV03_(body.token);

    if (action === 'session') {
      return c4AppJsonV03_({ok: true, data: {user: c4AppPublicUserV03_(session.user)}});
    }
    if (action === 'sync') {
      return c4AppJsonV03_({ok: true, data: c4AppSyncV03_(session.user, body)});
    }
    if (action === 'setStatus') {
      return c4AppJsonV03_({ok: true, data: c4AppSetStatusV03_(session.user, body)});
    }
    if (action === 'calculationPreview') {
      return c4AppJsonV03_({ok: true, data: c4AppCalculationPreviewV03_(session.user, body)});
    }
    if (action === 'changePassword') {
      return c4AppJsonV03_({ok: true, data: c4AppChangePasswordV03_(session.user, body)});
    }
    if (action === 'listUsers') {
      return c4AppJsonV03_({ok: true, data: c4AppListUsersV04_(session.user)});
    }
    if (action === 'createUser') {
      return c4AppJsonV03_({ok: true, data: c4AppCreateUserV04_(session.user, body)});
    }
    if (action === 'updateUser') {
      return c4AppJsonV03_({ok: true, data: c4AppUpdateUserV04_(session.user, body)});
    }
    if (action === 'setUserDisabled') {
      return c4AppJsonV03_({ok: true, data: c4AppSetUserDisabledV04_(session.user, body)});
    }
    if (action === 'resetUserPassword') {
      return c4AppJsonV03_({ok: true, data: c4AppResetUserPasswordV04_(session.user, body)});
    }
    if (action === 'terminateUserSessions') {
      return c4AppJsonV03_({ok: true, data: c4AppTerminateUserSessionsV04_(session.user, body)});
    }
    if (action === 'logout') {
      c4AppDeleteSessionV03_(body.token);
      return c4AppJsonV03_({ok: true, data: {loggedOut: true}});
    }

    throw new Error('Невідома дія: ' + action);
  } catch (error) {
    console.error(error && error.stack ? error.stack : error);
    return c4AppJsonV03_({
      ok: false,
      error: error && error.message ? error.message : String(error),
    });
  }
}

/**
 * Запустіть ОДИН РАЗ вручну з редактора Apps Script.
 * Створює першого адміністратора. Пароль у відкритому вигляді не зберігається.
 */
function setupC4AppBackendV03() {
  ScriptApp.requireAllScopes(ScriptApp.AuthMode.FULL);
  const ui = SpreadsheetApp.getUi();
  const props = PropertiesService.getScriptProperties();

  if (!props.getProperty(C4_APP_V03.PEPPER_KEY)) {
    props.setProperty(C4_APP_V03.PEPPER_KEY, c4AppRandomTokenV03_() + c4AppRandomTokenV03_());
  }

  const loginPrompt = ui.prompt(
    'С4 Харчування — Backend v0.4',
    'Введіть логін адміністратора (мінімум 4 символи):',
    ui.ButtonSet.OK_CANCEL
  );
  if (loginPrompt.getSelectedButton() !== ui.Button.OK) return;

  const login = c4AppNormalizeLoginV03_(loginPrompt.getResponseText());
  if (login.length < 4) throw new Error('Логін має містити щонайменше 4 символи.');

  const passPrompt = ui.prompt(
    'С4 Харчування — Backend v0.4',
    'Введіть пароль адміністратора (мінімум 10 символів):',
    ui.ButtonSet.OK_CANCEL
  );
  if (passPrompt.getSelectedButton() !== ui.Button.OK) return;

  const password = String(passPrompt.getResponseText() || '');
  if (password.length < 10) throw new Error('Пароль має містити щонайменше 10 символів.');

  const namePrompt = ui.prompt(
    'С4 Харчування — Backend v0.4',
    'Ім’я/підпис адміністратора в застосунку:',
    ui.ButtonSet.OK_CANCEL
  );
  if (namePrompt.getSelectedButton() !== ui.Button.OK) return;

  const displayName = String(namePrompt.getResponseText() || 'Адміністратор').trim() || 'Адміністратор';
  const users = c4AppLoadUsersV03_();
  const salt = c4AppRandomTokenV03_();

  users[login] = {
    login: login,
    displayName: displayName,
    role: 'admin',
    groups: C4_APP_V03.GROUPS.slice(),
    salt: salt,
    passwordHash: c4AppHashPasswordV03_(password, salt),
    disabled: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  c4AppSaveUsersV03_(users);
  c4AppResetAllSessionsV03();

  ui.alert(
    'Готово',
    'Backend v0.4 налаштовано.\n\nАдміністратор: ' + login +
      '\nТепер розгорніть проєкт як Web App і вставте /exec URL у застосунок.',
    ui.ButtonSet.OK
  );
}

function c4AppResetAllSessionsV03() {
  const props = PropertiesService.getScriptProperties();
  const all = props.getProperties();
  Object.keys(all).forEach(function(key) {
    if (key.indexOf(C4_APP_V03.SESSION_PREFIX) === 0) props.deleteProperty(key);
  });
  return {ok: true};
}

function c4AppParseBodyV03_(e) {
  if (!e || !e.postData || !e.postData.contents) {
    throw new Error('Порожній запит.');
  }
  let parsed;
  try {
    parsed = JSON.parse(e.postData.contents);
  } catch (error) {
    throw new Error('Некоректний JSON.');
  }
  if (!parsed || typeof parsed !== 'object') throw new Error('Некоректний JSON.');
  return parsed;
}

function c4AppJsonV03_(payload) {
  return ContentService
    .createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}

function c4AppNormalizeLoginV03_(value) {
  return String(value || '').trim().toLowerCase().replace(/\s+/g, '');
}

function c4AppLoadUsersV03_() {
  const raw = PropertiesService.getScriptProperties().getProperty(C4_APP_V03.USER_STORE_KEY);
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === 'object' ? parsed : {};
  } catch (error) {
    throw new Error('Пошкоджено сховище користувачів C4 API.');
  }
}

function c4AppSaveUsersV03_(users) {
  PropertiesService.getScriptProperties().setProperty(C4_APP_V03.USER_STORE_KEY, JSON.stringify(users));
}

function c4AppPublicUserV03_(user) {
  return {
    login: user.login,
    displayName: user.displayName || user.login,
    role: user.role,
    groups: Array.isArray(user.groups) ? user.groups : [],
  };
}

function c4AppLoginV03_(body) {
  const login = c4AppNormalizeLoginV03_(body.login);
  const password = String(body.password || '');
  if (!login || !password) throw new Error('Вкажіть логін і пароль.');

  const cache = CacheService.getScriptCache();
  const failKey = C4_APP_V03.FAIL_PREFIX + c4AppShortHashV03_(login);
  const fails = Number(cache.get(failKey) || 0);
  if (fails >= C4_APP_V03.MAX_FAILS) {
    throw new Error('Забагато невдалих спроб. Спробуйте ще раз через 10 хвилин.');
  }

  const users = c4AppLoadUsersV03_();
  const user = users[login];
  if (!user || user.disabled) {
    cache.put(failKey, String(fails + 1), C4_APP_V03.FAIL_TTL_SECONDS);
    throw new Error('Невірний логін або пароль.');
  }

  const actual = c4AppHashPasswordV03_(password, user.salt);
  if (!c4AppTimingSafeEqualV03_(actual, user.passwordHash)) {
    cache.put(failKey, String(fails + 1), C4_APP_V03.FAIL_TTL_SECONDS);
    throw new Error('Невірний логін або пароль.');
  }

  cache.remove(failKey);
  const token = c4AppRandomTokenV03_() + c4AppRandomTokenV03_();
  const expiresAt = Date.now() + C4_APP_V03.SESSION_TTL_MS;
  const sessionKey = C4_APP_V03.SESSION_PREFIX + c4AppShortHashV03_(token);

  PropertiesService.getScriptProperties().setProperty(sessionKey, JSON.stringify({
    login: login,
    expiresAt: expiresAt,
    createdAt: Date.now(),
  }));

  return {
    token: token,
    expiresAt: new Date(expiresAt).toISOString(),
    user: c4AppPublicUserV03_(user),
  };
}

function c4AppRequireSessionV03_(token) {
  token = String(token || '').trim();
  if (!token) throw new Error('Сесію не знайдено. Увійдіть повторно.');

  const props = PropertiesService.getScriptProperties();
  const key = C4_APP_V03.SESSION_PREFIX + c4AppShortHashV03_(token);
  const raw = props.getProperty(key);
  if (!raw) throw new Error('Сесія завершена. Увійдіть повторно.');

  let session;
  try { session = JSON.parse(raw); } catch (error) { session = null; }
  if (!session || Number(session.expiresAt || 0) < Date.now()) {
    props.deleteProperty(key);
    throw new Error('Сесія завершена. Увійдіть повторно.');
  }

  const users = c4AppLoadUsersV03_();
  const user = users[session.login];
  if (!user || user.disabled) {
    props.deleteProperty(key);
    throw new Error('Користувач заблокований або видалений.');
  }

  return {key: key, session: session, user: user};
}

function c4AppDeleteSessionV03_(token) {
  if (!token) return;
  PropertiesService.getScriptProperties().deleteProperty(
    C4_APP_V03.SESSION_PREFIX + c4AppShortHashV03_(String(token))
  );
}

function c4AppChangePasswordV03_(user, body) {
  const oldPassword = String(body.oldPassword || '');
  const newPassword = String(body.newPassword || '');
  if (newPassword.length < 10) throw new Error('Новий пароль має містити щонайменше 10 символів.');

  const users = c4AppLoadUsersV03_();
  const stored = users[user.login];
  if (!stored) throw new Error('Користувача не знайдено.');

  const oldHash = c4AppHashPasswordV03_(oldPassword, stored.salt);
  if (!c4AppTimingSafeEqualV03_(oldHash, stored.passwordHash)) {
    throw new Error('Поточний пароль неправильний.');
  }

  const salt = c4AppRandomTokenV03_();
  stored.salt = salt;
  stored.passwordHash = c4AppHashPasswordV03_(newPassword, salt);
  stored.updatedAt = new Date().toISOString();
  users[user.login] = stored;
  c4AppSaveUsersV03_(users);
  return {changed: true};
}

function c4AppSyncV03_(user, body) {
  const fromDate = validateIsoDate_(body.fromDate, 'дату початку синхронізації');
  const toDate = validateIsoDate_(body.toDate, 'дату завершення синхронізації');
  if (fromDate > toDate) throw new Error('Некоректний період синхронізації.');

  const requested = Array.isArray(body.groups) ? body.groups.map(normalizeGroup_) : [];
  const allowed = c4AppAllowedGroupsV03_(user);
  const groups = (requested.length ? requested : allowed).filter(function(group) {
    return allowed.indexOf(group) !== -1;
  });
  if (!groups.length) throw new Error('Немає доступних груп.');

  const reference = loadReference_();
  const sheetMap = resolveGroupSheets_(groups);
  const people = [];

  groups.forEach(function(group) {
    const sheet = sheetMap[group];
    const lastRow = sheet.getLastRow();
    const lastColumn = sheet.getLastColumn();
    if (lastRow < C4_APP_V03.START_ROW || lastColumn < C4_APP_V03.FIRST_DATE_COLUMN) return;

    const width = lastColumn - C4_APP_V03.FIRST_DATE_COLUMN + 1;
    const rawDates = sheet.getRange(C4_APP_V03.DATE_ROW, C4_APP_V03.FIRST_DATE_COLUMN, 1, width).getValues()[0];
    const shownDates = sheet.getRange(C4_APP_V03.DATE_ROW, C4_APP_V03.FIRST_DATE_COLUMN, 1, width).getDisplayValues()[0];
    const meals = sheet.getRange(C4_APP_V03.MEAL_ROW, C4_APP_V03.FIRST_DATE_COLUMN, 1, width).getDisplayValues()[0];

    const selected = [];
    let currentDate = null;
    for (let i = 0; i < width; i++) {
      const raw = rawDates[i];
      const shown = String(shownDates[i] || '').trim();
      if ((raw !== '' && raw !== null && raw !== undefined) || shown) {
        const parsed = parseSheetDateKey_(raw, shown);
        if (parsed) currentDate = parsed;
      }
      const meal = normalizeMeal_(meals[i]);
      if (currentDate && meal && currentDate >= fromDate && currentDate <= toDate) {
        selected.push({index: C4_APP_V03.FIRST_DATE_COLUMN - 1 + i, date: currentDate, meal: meal});
      }
    }

    const rows = sheet.getRange(C4_APP_V03.START_ROW, 1, lastRow - C4_APP_V03.START_ROW + 1, lastColumn).getDisplayValues();
    const refGroup = reference[group] || {};

    rows.forEach(function(row) {
      const tableKey = String(row[1] || '').trim();
      if (!tableKey) return;
      const rowGroup = normalizeGroup_(row[2] || group);
      if (rowGroup && rowGroup !== group) return;

      const normalizedKey = normalizePersonKey_(tableKey);
      const ref = refGroup[normalizedKey] || {};
      const statuses = {};

      selected.forEach(function(col) {
        const mark = c4AppNormalizeMarkV03_(row[col.index]);
        if (!mark) return;
        if (!statuses[col.date]) statuses[col.date] = {};
        statuses[col.date][col.meal] = mark;
      });

      people.push({
        id: c4AppPersonIdV03_(group, tableKey),
        rank: String(ref.rank || ''),
        name: tableKey,
        group: group,
        statuses: statuses,
      });
    });
  });

  return {
    version: C4_APP_V03.VERSION,
    syncedAt: new Date().toISOString(),
    fromDate: fromDate,
    toDate: toDate,
    people: people,
  };
}

function c4AppSetStatusV03_(user, body) {
  c4AppRequireEditorV03_(user);
  const group = normalizeGroup_(body.group);
  c4AppRequireGroupV03_(user, group);

  const tableKey = String(body.personName || '').trim();
  if (!tableKey) throw new Error('Не вказано ПІБ.');
  const day = validateIsoDate_(body.date, 'дату');
  const meal = String(body.meal || '').trim();
  if (['breakfast', 'lunch', 'dinner'].indexOf(meal) === -1) throw new Error('Некоректний прийом їжі.');
  const mark = c4AppNormalizeMarkV03_(body.mark);
  if (String(body.mark || '').trim() && !mark) throw new Error('Некоректний статус.');

  const lock = LockService.getDocumentLock();
  lock.waitLock(30000);
  try {
    const sheet = resolveGroupSheets_([group])[group];
    const row = c4AppFindPersonRowV03_(sheet, group, tableKey);
    const column = c4AppFindMealColumnV03_(sheet, day, meal);
    const cell = sheet.getRange(row, column);
    const oldValue = c4AppNormalizeMarkV03_(cell.getDisplayValue());
    cell.setValue(mark || '');
    SpreadsheetApp.flush();

    // Дані змінилися — старий FAST CACHE більше не актуальний.
    if (typeof FOOD_FAST_V323 !== 'undefined') {
      CacheService.getScriptCache().remove(FOOD_FAST_V323.SNAPSHOT_CACHE_KEY);
    }

    return {
      changed: true,
      group: group,
      personName: tableKey,
      date: day,
      meal: meal,
      oldValue: oldValue,
      newValue: mark,
      serverTime: new Date().toISOString(),
    };
  } finally {
    lock.releaseLock();
  }
}

function c4AppCalculationPreviewV03_(user, body) {
  const startDate = validateIsoDate_(body.startDate, 'дату початку');
  const endDate = validateIsoDate_(body.endDate || body.startDate, 'дату завершення');
  if (startDate > endDate) throw new Error('Некоректний період.');

  const preview = buildFoodCalculationPreview({
    startDate: startDate,
    endDate: endDate,
  });

  return {
    startDate: preview.startDate,
    endDate: preview.endDate,
    dayCount: preview.dayCount,
    message1: preview.message1,
    message2: preview.message2,
    cacheAgeSeconds: Number(preview.cacheAgeSeconds || 0),
  };
}

function c4AppAllowedGroupsV03_(user) {
  if (user.role === 'admin' || user.role === 'duty') return C4_APP_V03.GROUPS.slice();
  const groups = Array.isArray(user.groups) ? user.groups.map(normalizeGroup_) : [];
  return groups.filter(function(group) { return C4_APP_V03.GROUPS.indexOf(group) !== -1; });
}

function c4AppRequireEditorV03_(user) {
  if (user.role === 'duty') throw new Error('Черговий курсу має доступ тільки до перегляду.');
  if (user.role !== 'admin' && user.role !== 'editor') throw new Error('Недостатньо прав.');
}

function c4AppRequireGroupV03_(user, group) {
  if (c4AppAllowedGroupsV03_(user).indexOf(group) === -1) {
    throw new Error('Немає доступу до групи ' + group + '.');
  }
}

function c4AppFindPersonRowV03_(sheet, group, tableKey) {
  const lastRow = sheet.getLastRow();
  if (lastRow < C4_APP_V03.START_ROW) throw new Error('Аркуш групи порожній.');
  const values = sheet.getRange(C4_APP_V03.START_ROW, 2, lastRow - C4_APP_V03.START_ROW + 1, 2).getDisplayValues();
  const target = normalizePersonKey_(tableKey);
  for (let i = 0; i < values.length; i++) {
    const key = normalizePersonKey_(values[i][0]);
    const rowGroup = normalizeGroup_(values[i][1] || group);
    if (key === target && (!rowGroup || rowGroup === group)) return C4_APP_V03.START_ROW + i;
  }
  throw new Error('Не знайдено «' + tableKey + '» у групі ' + group + '.');
}

function c4AppFindMealColumnV03_(sheet, day, meal) {
  const lastColumn = sheet.getLastColumn();
  const width = lastColumn - C4_APP_V03.FIRST_DATE_COLUMN + 1;
  if (width <= 0) throw new Error('Немає колонок з датами.');

  const rawDates = sheet.getRange(C4_APP_V03.DATE_ROW, C4_APP_V03.FIRST_DATE_COLUMN, 1, width).getValues()[0];
  const shownDates = sheet.getRange(C4_APP_V03.DATE_ROW, C4_APP_V03.FIRST_DATE_COLUMN, 1, width).getDisplayValues()[0];
  const meals = sheet.getRange(C4_APP_V03.MEAL_ROW, C4_APP_V03.FIRST_DATE_COLUMN, 1, width).getDisplayValues()[0];
  let currentDate = null;

  for (let i = 0; i < width; i++) {
    const raw = rawDates[i];
    const shown = String(shownDates[i] || '').trim();
    if ((raw !== '' && raw !== null && raw !== undefined) || shown) {
      const parsed = parseSheetDateKey_(raw, shown);
      if (parsed) currentDate = parsed;
    }
    if (currentDate === day && normalizeMeal_(meals[i]) === meal) {
      return C4_APP_V03.FIRST_DATE_COLUMN + i;
    }
  }
  throw new Error('У таблиці немає ' + day + ' / ' + meal + '.');
}

function c4AppNormalizeMarkV03_(value) {
  const raw = String(value || '').trim();
  if (!raw) return '';
  const text = raw
    .replace(/[KkКк]/g, 'К')
    .replace(/[VvВв]/g, 'В')
    .replace(/д/g, 'д')
    .replace(/Д/g, 'д');
  if (text === 'К') return 'К';
  if (text === 'В') return 'В';
  if (/^[Шш]$/.test(raw)) return 'Ш';
  if (/^[ВвVv][ДдdD]$/.test(raw)) return 'Вд';
  return '';
}

function c4AppPersonIdV03_(group, tableKey) {
  return c4AppShortHashV03_(normalizeGroup_(group) + '|' + normalizePersonKey_(tableKey)).slice(0, 22);
}

function c4AppHashPasswordV03_(password, salt) {
  const pepper = PropertiesService.getScriptProperties().getProperty(C4_APP_V03.PEPPER_KEY) || '';
  let value = String(salt) + '|' + String(password) + '|' + pepper;
  for (let i = 0; i < C4_APP_V03.PASSWORD_ROUNDS; i++) {
    const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, value, Utilities.Charset.UTF_8);
    value = c4AppBytesToHexV03_(bytes) + '|' + salt + '|' + pepper;
  }
  return value.split('|')[0];
}

function c4AppShortHashV03_(value) {
  const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, String(value), Utilities.Charset.UTF_8);
  return c4AppBytesToHexV03_(bytes);
}

function c4AppBytesToHexV03_(bytes) {
  return bytes.map(function(b) {
    const n = b < 0 ? b + 256 : b;
    return ('0' + n.toString(16)).slice(-2);
  }).join('');
}

function c4AppRandomTokenV03_() {
  return Utilities.getUuid().replace(/-/g, '') + Utilities.getUuid().replace(/-/g, '');
}

function c4AppTimingSafeEqualV03_(a, b) {
  a = String(a || '');
  b = String(b || '');
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}


/**
 * v0.4 — керування користувачами з застосунку.
 * Усі дії нижче доступні тільки ролі admin. Паролі/хеші/солі ніколи не
 * повертаються клієнту.
 */
function c4AppRequireAdminV04_(actor) {
  if (!actor || actor.role !== 'admin') {
    throw new Error('Ця дія доступна тільки адміністратору.');
  }
}

function c4AppValidateRoleV04_(value) {
  const role = String(value || '').trim().toLowerCase();
  if (['admin', 'editor', 'duty'].indexOf(role) === -1) {
    throw new Error('Некоректна роль. Дозволено: admin, editor, duty.');
  }
  return role;
}

function c4AppNormalizeGroupsForRoleV04_(role, rawGroups) {
  if (role === 'admin' || role === 'duty') return C4_APP_V03.GROUPS.slice();
  const source = Array.isArray(rawGroups) ? rawGroups : [];
  const unique = {};
  source.forEach(function(value) {
    const group = normalizeGroup_(value);
    if (C4_APP_V03.GROUPS.indexOf(group) !== -1) unique[group] = true;
  });
  const groups = C4_APP_V03.GROUPS.filter(function(group) { return unique[group] === true; });
  if (!groups.length) throw new Error('Для редактора потрібно вибрати щонайменше одну групу.');
  return groups;
}

function c4AppPublicAdminUserV04_(user, sessionCounts) {
  return {
    login: user.login,
    displayName: user.displayName || user.login,
    role: user.role,
    groups: Array.isArray(user.groups) ? user.groups : [],
    disabled: user.disabled === true,
    createdAt: user.createdAt || '',
    updatedAt: user.updatedAt || '',
    activeSessions: Number((sessionCounts && sessionCounts[user.login]) || 0),
  };
}

function c4AppSessionCountsV04_() {
  const props = PropertiesService.getScriptProperties();
  const all = props.getProperties();
  const counts = {};
  const now = Date.now();
  Object.keys(all).forEach(function(key) {
    if (key.indexOf(C4_APP_V03.SESSION_PREFIX) !== 0) return;
    let session;
    try { session = JSON.parse(all[key]); } catch (error) { session = null; }
    if (!session || Number(session.expiresAt || 0) < now) {
      props.deleteProperty(key);
      return;
    }
    const login = c4AppNormalizeLoginV03_(session.login);
    if (!login) return;
    counts[login] = Number(counts[login] || 0) + 1;
  });
  return counts;
}

function c4AppListUsersV04_(actor) {
  c4AppRequireAdminV04_(actor);
  const users = c4AppLoadUsersV03_();
  const sessionCounts = c4AppSessionCountsV04_();
  const list = Object.keys(users)
    .map(function(login) { return c4AppPublicAdminUserV04_(users[login], sessionCounts); })
    .sort(function(a, b) {
      if (a.role === 'admin' && b.role !== 'admin') return -1;
      if (a.role !== 'admin' && b.role === 'admin') return 1;
      return String(a.login).localeCompare(String(b.login));
    });
  return {users: list, serverTime: new Date().toISOString()};
}

function c4AppCreateUserV04_(actor, body) {
  c4AppRequireAdminV04_(actor);
  const login = c4AppNormalizeLoginV03_(body.login);
  const displayName = String(body.displayName || '').trim();
  const password = String(body.password || '');
  const role = c4AppValidateRoleV04_(body.role);
  const groups = c4AppNormalizeGroupsForRoleV04_(role, body.groups);

  if (login.length < 4) throw new Error('Логін має містити щонайменше 4 символи.');
  if (!/^[a-z0-9._-]+$/.test(login)) {
    throw new Error('Логін може містити лише латинські літери, цифри, крапку, _ або -.');
  }
  if (!displayName) throw new Error('Вкажіть ім’я/назву користувача.');
  if (password.length < 10) throw new Error('Пароль має містити щонайменше 10 символів.');

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    const users = c4AppLoadUsersV03_();
    if (users[login]) throw new Error('Користувач «' + login + '» уже існує.');
    const salt = c4AppRandomTokenV03_();
    const now = new Date().toISOString();
    users[login] = {
      login: login,
      displayName: displayName,
      role: role,
      groups: groups,
      salt: salt,
      passwordHash: c4AppHashPasswordV03_(password, salt),
      disabled: false,
      createdAt: now,
      updatedAt: now,
    };
    c4AppSaveUsersV03_(users);
    return {user: c4AppPublicAdminUserV04_(users[login], {})};
  } finally {
    lock.releaseLock();
  }
}

function c4AppUpdateUserV04_(actor, body) {
  c4AppRequireAdminV04_(actor);
  const login = c4AppNormalizeLoginV03_(body.login);
  const displayName = String(body.displayName || '').trim();
  const role = c4AppValidateRoleV04_(body.role);
  const groups = c4AppNormalizeGroupsForRoleV04_(role, body.groups);
  if (!login) throw new Error('Не вказано логін користувача.');
  if (!displayName) throw new Error('Вкажіть ім’я/назву користувача.');
  if (login === actor.login && role !== 'admin') {
    throw new Error('Не можна забрати роль адміністратора у власного активного акаунта.');
  }

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    const users = c4AppLoadUsersV03_();
    const user = users[login];
    if (!user) throw new Error('Користувача не знайдено.');
    const roleChanged = user.role !== role;
    const groupsChanged = JSON.stringify(user.groups || []) !== JSON.stringify(groups);
    user.displayName = displayName;
    user.role = role;
    user.groups = groups;
    user.updatedAt = new Date().toISOString();
    users[login] = user;
    c4AppSaveUsersV03_(users);
    if (roleChanged || groupsChanged) c4AppTerminateSessionsForLoginV04_(login);
    return {user: c4AppPublicAdminUserV04_(user, c4AppSessionCountsV04_())};
  } finally {
    lock.releaseLock();
  }
}

function c4AppSetUserDisabledV04_(actor, body) {
  c4AppRequireAdminV04_(actor);
  const login = c4AppNormalizeLoginV03_(body.login);
  const disabled = body.disabled === true;
  if (!login) throw new Error('Не вказано логін користувача.');
  if (login === actor.login && disabled) throw new Error('Не можна заблокувати власний активний акаунт.');

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    const users = c4AppLoadUsersV03_();
    const user = users[login];
    if (!user) throw new Error('Користувача не знайдено.');
    user.disabled = disabled;
    user.updatedAt = new Date().toISOString();
    users[login] = user;
    c4AppSaveUsersV03_(users);
    if (disabled) c4AppTerminateSessionsForLoginV04_(login);
    return {user: c4AppPublicAdminUserV04_(user, c4AppSessionCountsV04_())};
  } finally {
    lock.releaseLock();
  }
}

function c4AppResetUserPasswordV04_(actor, body) {
  c4AppRequireAdminV04_(actor);
  const login = c4AppNormalizeLoginV03_(body.login);
  const password = String(body.newPassword || '');
  if (!login) throw new Error('Не вказано логін користувача.');
  if (password.length < 10) throw new Error('Тимчасовий пароль має містити щонайменше 10 символів.');

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    const users = c4AppLoadUsersV03_();
    const user = users[login];
    if (!user) throw new Error('Користувача не знайдено.');
    const salt = c4AppRandomTokenV03_();
    user.salt = salt;
    user.passwordHash = c4AppHashPasswordV03_(password, salt);
    user.updatedAt = new Date().toISOString();
    users[login] = user;
    c4AppSaveUsersV03_(users);
    const terminated = c4AppTerminateSessionsForLoginV04_(login);
    return {reset: true, terminatedSessions: terminated};
  } finally {
    lock.releaseLock();
  }
}

function c4AppTerminateSessionsForLoginV04_(login) {
  login = c4AppNormalizeLoginV03_(login);
  const props = PropertiesService.getScriptProperties();
  const all = props.getProperties();
  let removed = 0;
  Object.keys(all).forEach(function(key) {
    if (key.indexOf(C4_APP_V03.SESSION_PREFIX) !== 0) return;
    let session;
    try { session = JSON.parse(all[key]); } catch (error) { session = null; }
    if (session && c4AppNormalizeLoginV03_(session.login) === login) {
      props.deleteProperty(key);
      removed++;
    }
  });
  return removed;
}

function c4AppTerminateUserSessionsV04_(actor, body) {
  c4AppRequireAdminV04_(actor);
  const login = c4AppNormalizeLoginV03_(body.login);
  if (!login) throw new Error('Не вказано логін користувача.');
  if (login === actor.login) {
    throw new Error('Для завершення власної сесії використайте «Вийти» у застосунку.');
  }
  const users = c4AppLoadUsersV03_();
  if (!users[login]) throw new Error('Користувача не знайдено.');
  const removed = c4AppTerminateSessionsForLoginV04_(login);
  return {terminatedSessions: removed};
}

/**
 * Резервний ручний адмін-інструмент. У v0.4 основне керування є в екрані «Користувачі».
 * Запустіть вручну в Apps Script та заповніть поля.
 */
function createC4AppUserV03() {
  const ui = SpreadsheetApp.getUi();
  const loginPrompt = ui.prompt('Новий користувач', 'Логін:', ui.ButtonSet.OK_CANCEL);
  if (loginPrompt.getSelectedButton() !== ui.Button.OK) return;
  const login = c4AppNormalizeLoginV03_(loginPrompt.getResponseText());
  if (login.length < 4) throw new Error('Логін має містити щонайменше 4 символи.');

  const namePrompt = ui.prompt('Новий користувач', 'Ім’я/назва:', ui.ButtonSet.OK_CANCEL);
  if (namePrompt.getSelectedButton() !== ui.Button.OK) return;
  const displayName = String(namePrompt.getResponseText() || login).trim() || login;

  const rolePrompt = ui.prompt(
    'Новий користувач',
    'Роль: admin, editor або duty',
    ui.ButtonSet.OK_CANCEL
  );
  if (rolePrompt.getSelectedButton() !== ui.Button.OK) return;
  const role = String(rolePrompt.getResponseText() || '').trim().toLowerCase();
  if (['admin', 'editor', 'duty'].indexOf(role) === -1) throw new Error('Роль має бути admin, editor або duty.');

  let userGroups = C4_APP_V03.GROUPS.slice();
  if (role === 'editor') {
    const groupPrompt = ui.prompt(
      'Новий користувач',
      'Групи редактора через кому, наприклад: С-43 або С-42,С-43',
      ui.ButtonSet.OK_CANCEL
    );
    if (groupPrompt.getSelectedButton() !== ui.Button.OK) return;
    userGroups = String(groupPrompt.getResponseText() || '')
      .split(',')
      .map(normalizeGroup_)
      .filter(function(group) { return C4_APP_V03.GROUPS.indexOf(group) !== -1; });
    if (!userGroups.length) throw new Error('Не вибрано жодної коректної групи.');
  }

  const passPrompt = ui.prompt('Новий користувач', 'Тимчасовий пароль (мінімум 10 символів):', ui.ButtonSet.OK_CANCEL);
  if (passPrompt.getSelectedButton() !== ui.Button.OK) return;
  const password = String(passPrompt.getResponseText() || '');
  if (password.length < 10) throw new Error('Пароль має містити щонайменше 10 символів.');

  const users = c4AppLoadUsersV03_();
  if (users[login]) throw new Error('Користувач «' + login + '» уже існує.');
  const salt = c4AppRandomTokenV03_();
  users[login] = {
    login: login,
    displayName: displayName,
    role: role,
    groups: userGroups,
    salt: salt,
    passwordHash: c4AppHashPasswordV03_(password, salt),
    disabled: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  c4AppSaveUsersV03_(users);
  ui.alert('Готово', 'Створено користувача «' + login + '».', ui.ButtonSet.OK);
}

function resetC4AppUserPasswordV03() {
  const ui = SpreadsheetApp.getUi();
  const loginPrompt = ui.prompt('Скидання пароля', 'Логін користувача:', ui.ButtonSet.OK_CANCEL);
  if (loginPrompt.getSelectedButton() !== ui.Button.OK) return;
  const login = c4AppNormalizeLoginV03_(loginPrompt.getResponseText());
  const users = c4AppLoadUsersV03_();
  if (!users[login]) throw new Error('Користувача не знайдено.');

  const passPrompt = ui.prompt('Скидання пароля', 'Новий тимчасовий пароль (мінімум 10 символів):', ui.ButtonSet.OK_CANCEL);
  if (passPrompt.getSelectedButton() !== ui.Button.OK) return;
  const password = String(passPrompt.getResponseText() || '');
  if (password.length < 10) throw new Error('Пароль має містити щонайменше 10 символів.');

  const salt = c4AppRandomTokenV03_();
  users[login].salt = salt;
  users[login].passwordHash = c4AppHashPasswordV03_(password, salt);
  users[login].updatedAt = new Date().toISOString();
  c4AppSaveUsersV03_(users);
  c4AppResetAllSessionsV03();
  ui.alert('Готово', 'Пароль користувача «' + login + '» скинуто. Усі app-сесії завершено.', ui.ButtonSet.OK);
}
