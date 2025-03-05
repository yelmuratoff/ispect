import 'package:ispectify/ispectify.dart';

abstract class _Filter<T> {
  bool filter(T item);
}

typedef ISpectifyFilter = _Filter<ISpectiyData>;

class DefaultISpectifyFilter implements ISpectifyFilter {
  DefaultISpectifyFilter({
    this.titles = const [],
    this.types = const [],
    this.searchQuery,
  });

  final List<String> titles;
  final List<Type> types;
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
      final fullMsg = item.textMessage;
      final fullUpperMsg = fullMsg.toUpperCase();
      final fullLowerMsg = fullMsg.toLowerCase();
      final textContain = fullUpperMsg.contains(searchQuery!) ||
          fullLowerMsg.contains(searchQuery!);
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

  DefaultISpectifyFilter copyWith({
    List<String>? titles,
    List<Type>? types,
    String? searchQuery,
  }) =>
      DefaultISpectifyFilter(
        titles: titles ?? this.titles,
        types: types ?? this.types,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}
