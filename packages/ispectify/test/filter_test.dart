import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectifyFilter', () {
    _testFilterByTitles(useTalkerFilter: false);
    _testFilterByTitles(useTalkerFilter: true);

    _testFilterByTypes(useTalkerFilter: false);
    _testFilterByTypes(useTalkerFilter: true);

    _testFilterBySearchText(useTalkerFilter: false);
    _testFilterBySearchText(useTalkerFilter: true);

    test('copyWith', () {
      final filter = BaseTalkerFilter(
        titles: ['Error'],
        types: [Exception],
      );
      final newFilter = filter.copyWith(titles: ['LOG']);
      expect(filter == newFilter, false);
      expect(filter.titles == newFilter.titles, false);
      expect(filter.titles.first == newFilter.titles.first, false);

      final typesChangesFilter = filter.copyWith(types: [Error]);
      expect(filter == typesChangesFilter, false);
      expect(filter.types == typesChangesFilter.types, false);
      expect(filter.types.first == typesChangesFilter.types.first, false);
    });
  });
}

void _testFilterBySearchText({
  required bool useTalkerFilter,
}) {
  return group('By search text', () {
    _testFilterFoundBySearchText(
      useTalkerFilter: useTalkerFilter,
      searchQuery: 'http',
      countFound: 4,
      logCallback: (iSpectify) {
        iSpectify.error('HTTP log');
        iSpectify.info('Log http request');
        iSpectify.warning('http');
        iSpectify.debug('Log http');
        iSpectify.verbose('htt request');
        iSpectify.info('ttp request');
      },
    );
  });
}

void _testFilterByTypes({
  required bool useTalkerFilter,
}) {
  group('By type', () {
    _testFilterFoundByType(
      useTalkerFilter: useTalkerFilter,
      types: [ISpectifyLog],
      countFound: 1,
      logCallback: (iSpectify) {
        iSpectify.error('Test log');
      },
    );
    _testFilterFoundByType(
      useTalkerFilter: useTalkerFilter,
      types: [TalkerError],
      countFound: 2,
      logCallback: (iSpectify) {
        iSpectify.info('Test log');
        iSpectify.handle(ArgumentError());
        iSpectify.handle(ArgumentError());
      },
    );
  });
}

void _testFilterByTitles({
  required bool useTalkerFilter,
}) {
  return group(
    'By title',
    () {
      _testFilterFoundByTitle(
        useTalkerFilter: useTalkerFilter,
        titles: ['error'],
        countFound: 1,
        logCallback: (iSpectify) {
          iSpectify.error('Test log');
        },
      );

      _testFilterFoundByTitle(
        useTalkerFilter: useTalkerFilter,
        titles: ['error', 'exception'],
        countFound: 2,
        logCallback: (iSpectify) {
          iSpectify.error('Test log');
          iSpectify.handle(Exception('Test log'));
        },
      );

      _testFilterFoundByTitle(
        useTalkerFilter: useTalkerFilter,
        titles: ['error', 'verbose'],
        countFound: 2,
        logCallback: (iSpectify) {
          iSpectify.error('Test log');
          iSpectify.handle(Exception('Test disabled log'));
          iSpectify.verbose('Test log');
        },
      );

      _testFilterFoundByTitle(
        useTalkerFilter: useTalkerFilter,
        titles: ['verbose'],
        countFound: 5,
        logCallback: (iSpectify) {
          iSpectify.verbose('Test log');
          iSpectify.verbose('Test log');
          iSpectify.error('Test log');
          iSpectify.verbose('Test log');
          iSpectify.verbose('Test log');
          iSpectify.handle(Exception('Test disabled log'));
          iSpectify.handle(ArgumentError());
          iSpectify.verbose('Test log');
          iSpectify.critical('Test log');
        },
      );
    },
  );
}

void _testFilterFoundBySearchText({
  required String searchQuery,
  required Function(ISpectiy iSpectify) logCallback,
  required int countFound,
  required bool useTalkerFilter,
}) {
  final filter = BaseTalkerFilter(types: [], titles: [], searchQuery: searchQuery);

  final iSpectify = useTalkerFilter ? ISpectiy(filter: filter) : ISpectiy();

  test('Found $countFound ${useTalkerFilter ? 'By ISpectiy' : 'By Filter'} with searchQuery $searchQuery', () {
    logCallback.call(iSpectify);
    final foundRecords =
        useTalkerFilter ? iSpectify.history : iSpectify.history.where((e) => filter.filter(e)).toList();

    expect(foundRecords, isNotEmpty);
    expect(foundRecords.length, countFound);
  });
}

void _testFilterFoundByType({
  required List<Type> types,
  required Function(ISpectiy iSpectify) logCallback,
  required int countFound,
  required bool useTalkerFilter,
}) {
  final filter = BaseTalkerFilter(types: types);
  final iSpectify = useTalkerFilter ? ISpectiy(filter: filter) : ISpectiy();

  test('Found $countFound ${useTalkerFilter ? 'By ISpectiy' : 'By Filter'} in ${types.join(',')}', () {
    logCallback.call(iSpectify);
    final foundRecords =
        useTalkerFilter ? iSpectify.history : iSpectify.history.where((e) => filter.filter(e)).toList();
    expect(foundRecords, isNotEmpty);
    expect(foundRecords.length, countFound);
  });
}

void _testFilterFoundByTitle(
    {required List<String> titles,
    required Function(ISpectiy) logCallback,
    required int countFound,
    required bool useTalkerFilter}) {
  final filter = BaseTalkerFilter(titles: titles);
  final iSpectify = useTalkerFilter ? ISpectiy(filter: filter) : ISpectiy();

  test('Found $countFound ${useTalkerFilter ? 'By ISpectiy' : 'By Filter'} in ${titles.join(',')}', () {
    logCallback.call(iSpectify);

    final foundRecords =
        useTalkerFilter ? iSpectify.history : iSpectify.history.where((e) => filter.filter(e)).toList();

    expect(foundRecords, isNotEmpty);
    expect(foundRecords.length, countFound);
  });
}
