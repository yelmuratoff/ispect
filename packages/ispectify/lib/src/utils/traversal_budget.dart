final class TraversalBudget {
  TraversalBudget(this._remaining);

  int _remaining;

  bool get hasCapacity => _remaining > 0;

  bool take() {
    if (_remaining <= 0) return false;
    _remaining--;
    return true;
  }
}
