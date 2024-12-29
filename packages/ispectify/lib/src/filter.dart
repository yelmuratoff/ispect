import 'package:ispectify/ispectify.dart';

typedef ISpectifyFilter = _Filter<ISpectiyData>;

class BaseISpectifyFilter implements ISpectifyFilter {
  BaseISpectifyFilter({
    this.titles = const [],
    this.types = const [],
    this.searchQuery,
  });

  /// List of enabled for filter titles [exception], [error], [verbose]
  final List<String> titles;

  /// List of enabled for filter types - subclasses of [ISpectiyData]
  /// Like [ISpectifyError], [ISpectifyException], [ISpectifyLog], etc.
  final List<Type> types;

  /// String query for filtering logs
  final String? searchQuery;

  @override
  bool filter(ISpectiyData item) {
    var match = false;

    if (titles.isNotEmpty) {
      match = match || titles.contains(item.title);
    }

    if (types.isNotEmpty) {
      match = match || _checkTypeMatch(item);
    }

    if (searchQuery?.isNotEmpty ?? false) {
      final fullMsg = item.generateTextMessage();
      final fullUpperMsg = fullMsg.toUpperCase();
      final fullLowerMsg = fullMsg.toLowerCase();
      final textContain = fullUpperMsg.contains(searchQuery!) || fullLowerMsg.contains(searchQuery!);
      match = match || textContain;
    }

    if (titles.isEmpty && types.isEmpty && (searchQuery?.isEmpty ?? true)) {
      match = true;
    }
    return match;
  }

  bool _checkTypeMatch(ISpectiyData item) {
    var match = false;
    for (final type in types) {
      if (item.runtimeType == type) {
        match = true;
        break;
      }
    }
    return match;
  }

  BaseISpectifyFilter copyWith({
    List<String>? titles,
    List<Type>? types,
    String? searchQuery,
  }) {
    return BaseISpectifyFilter(
      titles: titles ?? this.titles,
      types: types ?? this.types,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

abstract class _Filter<T> {
  bool filter(T item);
}
