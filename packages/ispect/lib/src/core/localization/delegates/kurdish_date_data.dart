/// Shared Kurdish date symbols and patterns for Sorani (`ckb`) and Kurmanji (`ku`).
library;

/// Date patterns used by Kurdish Material localization delegates.
const kurdishMaterialLocaleDatePatterns = {
  'd': 'd', // DAY
  'E': 'ccc', // ABBR_WEEKDAY
  'EEEE': 'cccc', // WEEKDAY
  'LLL': 'LLL', // ABBR_STANDALONE_MONTH
  'LLLL': 'LLLL', // STANDALONE_MONTH
  'M': 'L', // NUM_MONTH
  'Md': 'd/‏M', // NUM_MONTH_DAY
  'MEd': 'EEE، d/M', // NUM_MONTH_WEEKDAY_DAY
  'MMM': 'LLL', // ABBR_MONTH
  'MMMd': 'd MMM', // ABBR_MONTH_DAY
  'MMMEd': 'EEE، d MMM', // ABBR_MONTH_WEEKDAY_DAY
  'MMMM': 'LLLL', // MONTH
  'MMMMd': 'd MMMM', // MONTH_DAY
  'MMMMEEEEd': 'EEEE، d MMMM', // MONTH_WEEKDAY_DAY
  'QQQ': 'QQQ', // ABBR_QUARTER
  'QQQQ': 'QQQQ', // QUARTER
  'y': 'y', // YEAR
  'yM': 'M‏/y', // YEAR_NUM_MONTH
  'yMd': 'd‏/M‏/y', // YEAR_NUM_MONTH_DAY
  'yMEd': 'EEE، d/‏M/‏y', // YEAR_NUM_MONTH_WEEKDAY_DAY
  'yMMM': 'MMM y', // YEAR_ABBR_MONTH
  'yMMMd': 'd MMM y', // YEAR_ABBR_MONTH_DAY
  'yMMMEd': 'EEE، d MMM y', // YEAR_ABBR_MONTH_WEEKDAY_DAY
  'yMMMM': 'MMMM y', // YEAR_MONTH
  'yMMMMd': 'd MMMM y', // YEAR_MONTH_DAY
  'yMMMMEEEEd': 'EEEE، d MMMM y', // YEAR_MONTH_WEEKDAY_DAY
  'yQQQ': 'QQQ y', // YEAR_ABBR_QUARTER
  'yQQQQ': 'QQQQ y', // YEAR_QUARTER
  'H': 'HH', // HOUR24
  'Hm': 'HH:mm', // HOUR24_MINUTE
  'Hms': 'HH:mm:ss', // HOUR24_MINUTE_SECOND
  'j': 'h a', // HOUR
  'jm': 'h:mm a', // HOUR_MINUTE
  'jms': 'h:mm:ss a', // HOUR_MINUTE_SECOND
  'jmv': 'h:mm a v', // HOUR_MINUTE_GENERIC_TZ
  'jmz': 'h:mm a z', // HOUR_MINUTETZ
  'jz': 'h a z', // HOURGENERIC_TZ
  'm': 'm', // MINUTE
  'ms': 'mm:ss', // MINUTE_SECOND
  's': 's', // SECOND
  'v': 'v', // ABBR_GENERIC_TZ
  'z': 'z', // ABBR_SPECIFIC_TZ
  'zzzz': 'zzzz', // SPECIFIC_TZ
  'ZZZZ': 'ZZZZ', // ABBR_UTC_TZ
};

/// Date patterns used by Kurdish Cupertino localization delegates.
const kurdishCupertinoLocaleDatePatterns = {
  'd': 'd.',
  'E': 'ccc',
  'EEEE': 'cccc',
  'LLL': 'LLL',
  'LLLL': 'LLLL',
  'M': 'L.',
  'Md': 'd.M.',
  'MEd': 'EEE d.M.',
  'MMM': 'LLL',
  'MMMd': 'd. MMM',
  'MMMEd': 'EEE d. MMM',
  'MMMM': 'LLLL',
  'MMMMd': 'd. MMMM',
  'MMMMEEEEd': 'EEEE d. MMMM',
  'QQQ': 'QQQ',
  'QQQQ': 'QQQQ',
  'y': 'y',
  'yM': 'M.y',
  'yMd': 'd.M.y',
  'yMEd': 'EEE d.MM.y',
  'yMMM': 'MMM y',
  'yMMMd': 'd. MMM y',
  'yMMMEd': 'EEE d. MMM y',
  'yMMMM': 'MMMM y',
  'yMMMMd': 'd. MMMM y',
  'yMMMMEEEEd': 'EEEE d. MMMM y',
  'yQQQ': 'QQQ y',
  'yQQQQ': 'QQQQ y',
  'H': 'HH',
  'Hm': 'HH:mm',
  'Hms': 'HH:mm:ss',
  'j': 'HH',
  'jm': 'HH:mm',
  'jms': 'HH:mm:ss',
  'jmv': 'HH:mm v',
  'jmz': 'HH:mm z',
  'jz': 'HH z',
  'm': 'm',
  'ms': 'mm:ss',
  's': 's',
  'v': 'v',
  'z': 'z',
  'zzzz': 'zzzz',
  'ZZZZ': 'ZZZZ',
};

const _kurdishEraNames = ['پێش زاینی', 'زاینی'];

const _kurdishNarrowMonths = [
  'ک.د',
  'ش',
  'ز',
  'ن',
  'م',
  'ح',
  'ت',
  'ئ',
  'ل',
  'ت.ی',
  'ت.د',
  'ک.ی',
];

const _kurdishMonths = [
  'کانونی دووەم',
  'شوبات',
  'ئازار',
  'نیسان',
  'مایس',
  'حوزەیران',
  'تەمموز',
  'ئاب',
  'ئەیلوول',
  'تشرینی یەکەم',
  'تشرینی دووەم',
  'کانونی یەکەم',
];

const _kurdishWeekdays = [
  'یەکشەممە',
  'دووشەممە',
  'سێشەممە',
  'چوارشەممە',
  'پێنجشەممە',
  'هەینی',
  'شەممە',
];

const _kurdishShortWeekdays = [
  'یەکشەم',
  'دووشەم',
  'سێشەم',
  'چوارشەم',
  'پێنجشەم',
  'هەینی',
  'شەممە',
];

const _kurdishNarrowWeekdays = ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'];

const _kurdishQuarters = [
  'چارەکی یەکەم',
  'چارەکی دووەم',
  'چارەکی سێیەم',
  'چارەکی چوارەم',
];

/// Builds Kurdish [DateSymbols] data for a given locale code.
Map<String, dynamic> kurdishDateSymbols({
  required String name,
  required List<String> eras,
  required List<String> ampms,
}) => {
    'NAME': name,
    'ERAS': eras,
    'ERANAMES': _kurdishEraNames,
    'NARROWMONTHS': _kurdishNarrowMonths,
    'STANDALONENARROWMONTHS': _kurdishNarrowMonths,
    'MONTHS': _kurdishMonths,
    'STANDALONEMONTHS': _kurdishMonths,
    'SHORTMONTHS': _kurdishMonths,
    'STANDALONESHORTMONTHS': _kurdishMonths,
    'WEEKDAYS': _kurdishWeekdays,
    'STANDALONEWEEKDAYS': _kurdishWeekdays,
    'SHORTWEEKDAYS': _kurdishShortWeekdays,
    'STANDALONESHORTWEEKDAYS': _kurdishShortWeekdays,
    'NARROWWEEKDAYS': _kurdishNarrowWeekdays,
    'STANDALONENARROWWEEKDAYS': _kurdishNarrowWeekdays,
    'SHORTQUARTERS': ['چ١', 'چ٢', 'چ٣', 'چ٤'],
    'QUARTERS': _kurdishQuarters,
    'AMPMS': ampms,
    'DATEFORMATS': [
      'EEEE، d MMMM y',
      'd MMMM y',
      'dd‏/MM‏/y',
      'd‏/M‏/y',
    ],
    'TIMEFORMATS': [
      'h:mm:ss a zzzz',
      'h:mm:ss a z',
      'h:mm:ss a',
      'h:mm a',
    ],
    'AVAILABLEFORMATS': null,
    'DATETIMEFORMATS': [
      '{1} {0}',
      '{1} {0}',
      '{1} {0}',
      '{1} {0}',
    ],
    'ZERODIGIT': '٠',
    'FIRSTDAYOFWEEK': 5,
    'WEEKENDRANGE': [4, 5],
    'FIRSTWEEKCUTOFFDAY': 3,
  };

/// Date symbols for Sorani Kurdish (`ckb`).
final soraniDateSymbols = kurdishDateSymbols(
  name: 'ckb',
  eras: const ['پ.ز', 'ز'],
  ampms: const ['پ.ن', 'د.ن'],
);

/// Date symbols for Kurmanji Kurdish (`ku`).
final kurmanjiDateSymbols = kurdishDateSymbols(
  name: 'ku',
  eras: const ['ب.ز', 'ز'],
  ampms: const ['ب.ن', 'پ.ن'],
);
