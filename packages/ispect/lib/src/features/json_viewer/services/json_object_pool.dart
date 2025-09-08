/// Interface for object pool following Dependency Inversion Principle
abstract class ObjectPool {
  T get<T>();
  void release<T>(T object);
  void clear();
  void warmUp();
}

/// Interface for list pool operations
abstract class ListPool {
  List<int> getIntList();
  List<String> getStringList();
  List<T> getTypedList<T>();
  void releaseIntList(List<int> list);
  void releaseStringList(List<String> list);
  void releaseTypedList<T>(List<T> list);
}

/// Interface for set pool operations
abstract class SetPool {
  Set<String> getStringSet();
  Set<int> getIntSet();
  Set<T> getTypedSet<T>();
  void releaseStringSet(Set<String> set);
  void releaseIntSet(Set<int> set);
  void releaseTypedSet<T>(Set<T> set);
}

/// Interface for map pool operations
abstract class MapPool {
  Map<String, dynamic> getStringDynamicMap();
  Map<K, V> getTypedMap<K, V>();
  void releaseStringDynamicMap(Map<String, dynamic> map);
  void releaseTypedMap<K, V>(Map<K, V> map);
}

/// Consolidated interface for all pool operations
abstract class UniversalObjectPool
    implements ObjectPool, ListPool, SetPool, MapPool {
  void setMaxPoolSize(int size);
  int getPoolSize<T>();
  void clearPool<T>();
  Map<String, int> getPoolStatistics();
}

/// Concrete implementation of object pool with multiple pool types
class JsonObjectPool implements UniversalObjectPool {
  JsonObjectPool._internal();

  static final JsonObjectPool _instance = JsonObjectPool._internal();
  static JsonObjectPool get instance => _instance;

  // Pool configurations
  static const int _defaultMaxPoolSize = 50;
  static const int _defaultInitialSize = 10;

  // Separate pools for different object types
  final List<List<int>> _intListPool = <List<int>>[];
  final List<List<String>> _stringListPool = <List<String>>[];
  final List<Set<String>> _stringSetPool = <Set<String>>[];
  final List<Set<int>> _intSetPool = <Set<int>>[];
  final List<Map<String, dynamic>> _stringDynamicMapPool =
      <Map<String, dynamic>>[];

  // Generic pools for typed collections
  final Map<Type, List<List<Object>>> _typedListPools =
      <Type, List<List<Object>>>{};
  final Map<Type, List<Set<Object>>> _typedSetPools =
      <Type, List<Set<Object>>>{};
  final Map<Type, List<Map<Object, Object>>> _typedMapPools =
      <Type, List<Map<Object, Object>>>{};

  int _maxPoolSize = _defaultMaxPoolSize;

  @override
  void setMaxPoolSize(int size) {
    _maxPoolSize = size.clamp(10, 200);
  }

  @override
  int getPoolSize<T>() {
    if (T == List<int>) return _intListPool.length;
    if (T == List<String>) return _stringListPool.length;
    if (T == Set<String>) return _stringSetPool.length;
    if (T == Set<int>) return _intSetPool.length;
    if (T == Map<String, dynamic>) return _stringDynamicMapPool.length;
    return 0;
  }

  @override
  void clearPool<T>() {
    if (T == List<int>) {
      _intListPool.clear();
    } else if (T == List<String>) {
      _stringListPool.clear();
    } else if (T == Set<String>) {
      _stringSetPool.clear();
    } else if (T == Set<int>) {
      _intSetPool.clear();
    } else if (T == Map<String, dynamic>) {
      _stringDynamicMapPool.clear();
    }
  }

  // Object Pool interface implementation
  @override
  T get<T>() {
    if (T == List<int>) return getIntList() as T;
    if (T == List<String>) return getStringList() as T;
    if (T == Set<String>) return getStringSet() as T;
    if (T == Set<int>) return getIntSet() as T;
    if (T == Map<String, dynamic>) return getStringDynamicMap() as T;

    throw UnsupportedError('Type $T not supported by object pool');
  }

  @override
  void release<T>(T object) {
    if (object is List<int>) {
      releaseIntList(object);
    } else if (object is List<String>) {
      releaseStringList(object);
    } else if (object is Set<String>) {
      releaseStringSet(object);
    } else if (object is Set<int>) {
      releaseIntSet(object);
    } else if (object is Map<String, dynamic>) {
      releaseStringDynamicMap(object);
    } else {
      throw UnsupportedError(
        'Type ${T.runtimeType} not supported by object pool',
      );
    }
  }

  // List Pool interface implementation
  @override
  List<int> getIntList() {
    if (_intListPool.isNotEmpty) {
      return _intListPool.removeLast()..clear();
    }
    return <int>[];
  }

  @override
  List<String> getStringList() {
    if (_stringListPool.isNotEmpty) {
      return _stringListPool.removeLast()..clear();
    }
    return <String>[];
  }

  @override
  List<T> getTypedList<T>() {
    final pools = _typedListPools[T];
    if (pools != null && pools.isNotEmpty) {
      return pools.removeLast().cast<T>()..clear();
    }
    return <T>[];
  }

  @override
  void releaseIntList(List<int> list) {
    if (_intListPool.length < _maxPoolSize) {
      list.clear();
      _intListPool.add(list);
    }
  }

  @override
  void releaseStringList(List<String> list) {
    if (_stringListPool.length < _maxPoolSize) {
      list.clear();
      _stringListPool.add(list);
    }
  }

  @override
  void releaseTypedList<T>(List<T> list) {
    final pools = _typedListPools[T] ??= <List<Object>>[];
    if (pools.length < _maxPoolSize) {
      list.clear();
      pools.add(list.cast<Object>());
    }
  }

  // Set Pool interface implementation
  @override
  Set<String> getStringSet() {
    if (_stringSetPool.isNotEmpty) {
      return _stringSetPool.removeLast()..clear();
    }
    return <String>{};
  }

  @override
  Set<int> getIntSet() {
    if (_intSetPool.isNotEmpty) {
      return _intSetPool.removeLast()..clear();
    }
    return <int>{};
  }

  @override
  Set<T> getTypedSet<T>() {
    final pools = _typedSetPools[T];
    if (pools != null && pools.isNotEmpty) {
      return pools.removeLast().cast<T>()..clear();
    }
    return <T>{};
  }

  @override
  void releaseStringSet(Set<String> set) {
    if (_stringSetPool.length < _maxPoolSize) {
      set.clear();
      _stringSetPool.add(set);
    }
  }

  @override
  void releaseIntSet(Set<int> set) {
    if (_intSetPool.length < _maxPoolSize) {
      set.clear();
      _intSetPool.add(set);
    }
  }

  @override
  void releaseTypedSet<T>(Set<T> set) {
    final pools = _typedSetPools[T] ??= <Set<Object>>[];
    if (pools.length < _maxPoolSize) {
      set.clear();
      pools.add(set.cast<Object>());
    }
  }

  // Map Pool interface implementation
  @override
  Map<String, dynamic> getStringDynamicMap() {
    if (_stringDynamicMapPool.isNotEmpty) {
      return _stringDynamicMapPool.removeLast()..clear();
    }
    return <String, dynamic>{};
  }

  @override
  Map<K, V> getTypedMap<K, V>() {
    final pools = _typedMapPools[K];
    if (pools != null && pools.isNotEmpty) {
      return pools.removeLast().cast<K, V>()..clear();
    }
    return <K, V>{};
  }

  @override
  void releaseStringDynamicMap(Map<String, dynamic> map) {
    if (_stringDynamicMapPool.length < _maxPoolSize) {
      map.clear();
      _stringDynamicMapPool.add(map);
    }
  }

  @override
  void releaseTypedMap<K, V>(Map<K, V> map) {
    final pools = _typedMapPools[K] ??= <Map<Object, Object>>[];
    if (pools.length < _maxPoolSize) {
      map.clear();
      pools.add(map.cast<Object, Object>());
    }
  }

  @override
  void clear() {
    _intListPool.clear();
    _stringListPool.clear();
    _stringSetPool.clear();
    _intSetPool.clear();
    _stringDynamicMapPool.clear();
    _typedListPools.clear();
    _typedSetPools.clear();
    _typedMapPools.clear();
  }

  @override
  void warmUp() {
    // Pre-populate pools with common objects
    for (var i = 0; i < _defaultInitialSize; i++) {
      _intListPool.add(<int>[]);
      _stringListPool.add(<String>[]);
      _stringSetPool.add(<String>{});
      _intSetPool.add(<int>{});
      _stringDynamicMapPool.add(<String, dynamic>{});
    }
  }

  @override
  Map<String, int> getPoolStatistics() => {
        'intLists': _intListPool.length,
        'stringLists': _stringListPool.length,
        'stringSets': _stringSetPool.length,
        'intSets': _intSetPool.length,
        'stringDynamicMaps': _stringDynamicMapPool.length,
        'typedListPools': _typedListPools.length,
        'typedSetPools': _typedSetPools.length,
        'typedMapPools': _typedMapPools.length,
      };

  /// Legacy method for backward compatibility
  @Deprecated('Use get<List<int>>() instead')
  List<int> borrowIntList() => getIntList();

  /// Legacy method for backward compatibility
  @Deprecated('Use release(list) instead')
  void returnIntList(List<int> list) => releaseIntList(list);
}

/// Factory for creating object pools with dependency injection
class ObjectPoolFactory {
  static UniversalObjectPool createPool({
    int maxPoolSize = 50,
    bool warmUp = true,
  }) {
    final pool = JsonObjectPool.instance..setMaxPoolSize(maxPoolSize);
    if (warmUp) {
      pool.warmUp();
    }
    return pool;
  }

  /// Create a test-friendly mock pool
  static UniversalObjectPool createTestPool() => JsonObjectPool.instance;
}
