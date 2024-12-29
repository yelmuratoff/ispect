import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectifyFilter', () {
    _testFilterByTitles(useISpectifyFilter: false);
    _testFilterByTitles(useISpectifyFilter: true);

    _testFilterByTypes(useISpectifyFilter: false);
    _testFilterByTypes(useISpectifyFilter: true);

    _testFilterBySearchText(useISpectifyFilter: false);
    _testFilterBySearchText(useISpectifyFilter: true);

    test('copyWith', () {
      final filter = BaseISpectifyFilter(
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
  required bool useISpectifyFilter,
}) {
  return group('By search text', () {
    _testFilterFoundBySearchText(
      useISpectifyFilter: useISpectifyFilter,
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
  required bool useISpectifyFilter,
}) {
  group('By type', () {
    _testFilterFoundByType(
      useISpectifyFilter: useISpectifyFilter,
      types: [ISpectifyLog],
      countFound: 1,
      logCallback: (iSpectify) {
        iSpectify.error('Test log');
      },
    );
    _testFilterFoundByType(
      useISpectifyFilter: useISpectifyFilter,
      types: [ISpectifyError],
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
  required bool useISpectifyFilter,
}) {
  return group(
    'By title',
    () {
      _testFilterFoundByTitle(
        useISpectifyFilter: useISpectifyFilter,
        titles: ['error'],
        countFound: 1,
        logCallback: (iSpectify) {
          iSpectify.error('Test log');
        },
      );

      _testFilterFoundByTitle(
        useISpectifyFilter: useISpectifyFilter,
        titles: ['error', 'exception'],
        countFound: 2,
        logCallback: (iSpectify) {
          iSpectify.error('Test log');
          iSpectify.handle(Exception('Test log'));
        },
      );

      _testFilterFoundByTitle(
        useISpectifyFilter: useISpectifyFilter,
        titles: ['error', 'verbose'],
        countFound: 2,
        logCallback: (iSpectify) {
          iSpectify.error('Test log');
          iSpectify.handle(Exception('Test disabled log'));
          iSpectify.verbose('Test log');
        },
      );

      _testFilterFoundByTitle(
        useISpectifyFilter: useISpectifyFilter,
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
  required bool useISpectifyFilter,
}) {
  final filter = BaseISpectifyFilter(types: [], titles: [], searchQuery: searchQuery);

  final iSpectify = useISpectifyFilter ? ISpectiy(filter: filter) : ISpectiy();

  test('Found $countFound ${useISpectifyFilter ? 'By ISpectiy' : 'By Filter'} with searchQuery $searchQuery', () {
    logCallback.call(iSpectify);
    final foundRecords =
        useISpectifyFilter ? iSpectify.history : iSpectify.history.where((e) => filter.filter(e)).toList();

    expect(foundRecords, isNotEmpty);
    expect(foundRecords.length, countFound);
  });
}

void _testFilterFoundByType({
  required List<Type> types,
  required Function(ISpectiy iSpectify) logCallback,
  required int countFound,
  required bool useISpectifyFilter,
}) {
  final filter = BaseISpectifyFilter(types: types);
  final iSpectify = useISpectifyFilter ? ISpectiy(filter: filter) : ISpectiy();

  test('Found $countFound ${useISpectifyFilter ? 'By ISpectiy' : 'By Filter'} in ${types.join(',')}', () {
    logCallback.call(iSpectify);
    final foundRecords =
        useISpectifyFilter ? iSpectify.history : iSpectify.history.where((e) => filter.filter(e)).toList();
    expect(foundRecords, isNotEmpty);
    expect(foundRecords.length, countFound);
  });
}

void _testFilterFoundByTitle(
    {required List<String> titles,
    required Function(ISpectiy) logCallback,
    required int countFound,
    required bool useISpectifyFilter}) {
  final filter = BaseISpectifyFilter(titles: titles);
  final iSpectify = useISpectifyFilter ? ISpectiy(filter: filter) : ISpectiy();

  test('Found $countFound ${useISpectifyFilter ? 'By ISpectiy' : 'By Filter'} in ${titles.join(',')}', () {
    logCallback.call(iSpectify);

    final foundRecords =
        useISpectifyFilter ? iSpectify.history : iSpectify.history.where((e) => filter.filter(e)).toList();

    expect(foundRecords, isNotEmpty);
    expect(foundRecords.length, countFound);
  });
}
