/// Thrown when `ISpect.read(context)` is called from a widget that is not
/// inside an `ISpectBuilder` subtree.
///
/// This is a programmer error, not a runtime condition: the fix is to wrap
/// the relevant subtree with `ISpectBuilder.wrap(child: ...)`.
final class ISpectScopeNotFoundError extends Error {
  ISpectScopeNotFoundError();

  @override
  String toString() => 'ISpectScopeNotFoundError: '
      'ISpect.read(context) called with a context that does not contain an '
      'ISpectScopeController.\n'
      'Ensure that ISpectBuilder is an ancestor of the widget using this '
      'context.';
}
