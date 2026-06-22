/// Single source of truth for category ID strings.
///
/// All trace categories, [ISpectLogType.category], UI grouping, and filter
/// logic reference these constants. Never use raw category strings elsewhere.
abstract final class TraceCategoryIds {
  // ── Network protocols ──────────────────────────────────────────────────
  static const network = 'network';
  static const ws = 'ws';
  static const sse = 'sse';
  static const grpc = 'grpc';
  static const graphql = 'graphql';

  // ── Data & state ───────────────────────────────────────────────────────
  static const db = 'db';
  static const state = 'state';

  // ── Services ───────────────────────────────────────────────────────────
  static const auth = 'auth';
  static const storage = 'storage';
  static const push = 'push';
  static const analytics = 'analytics';
  static const payment = 'payment';

  // ── UI ─────────────────────────────────────────────────────────────────
  static const navigation = 'navigation';

  // ── Runtime ────────────────────────────────────────────────────────────
  static const performance = 'performance';

  // ── Fallback ───────────────────────────────────────────────────────────
  static const general = 'general';

  /// All built-in category IDs. Used in UI for prefix heuristic.
  static const builtIn = {
    network,
    ws,
    sse,
    grpc,
    graphql,
    db,
    state,
    auth,
    storage,
    push,
    analytics,
    payment,
    navigation,
    performance,
  };
}
