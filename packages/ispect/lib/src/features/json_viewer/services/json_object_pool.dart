/// Object pool service for reducing allocations in JSON viewer
class JsonObjectPool {
  JsonObjectPool._();
  static final JsonObjectPool _instance = JsonObjectPool._();
  static JsonObjectPool get instance => _instance;

  // Pools for different types of objects
  final List<List<int>> _intListPool = [];
  final List<List<String>> _stringListPool = [];
  final List<StringBuffer> _stringBufferPool = [];

  /// Get a reusable List<int> from the pool
  List<int> getIntList() {
    if (_intListPool.isNotEmpty) {
      return _intListPool.removeLast()..clear();
    }
    return <int>[];
  }

  /// Return a List<int> to the pool for reuse
  void releaseIntList(List<int> list) {
    if (_intListPool.length < 20) {
      // Limit pool size
      list.clear();
      _intListPool.add(list);
    }
  }

  /// Get a reusable List<String> from the pool
  List<String> getStringList() {
    if (_stringListPool.isNotEmpty) {
      return _stringListPool.removeLast()..clear();
    }
    return <String>[];
  }

  /// Return a List<String> to the pool for reuse
  void releaseStringList(List<String> list) {
    if (_stringListPool.length < 20) {
      // Limit pool size
      list.clear();
      _stringListPool.add(list);
    }
  }

  /// Get a reusable StringBuffer from the pool
  StringBuffer getStringBuffer() {
    if (_stringBufferPool.isNotEmpty) {
      return _stringBufferPool.removeLast()..clear();
    }
    return StringBuffer();
  }

  /// Return a StringBuffer to the pool for reuse
  void releaseStringBuffer(StringBuffer buffer) {
    if (_stringBufferPool.length < 10) {
      // Limit pool size
      buffer.clear();
      _stringBufferPool.add(buffer);
    }
  }

  /// Clear all pools to free memory
  void clearPools() {
    _intListPool.clear();
    _stringListPool.clear();
    _stringBufferPool.clear();
  }

  /// Get current pool sizes for debugging
  Map<String, int> getPoolSizes() => {
        'intLists': _intListPool.length,
        'stringLists': _stringListPool.length,
        'stringBuffers': _stringBufferPool.length,
      };
}
