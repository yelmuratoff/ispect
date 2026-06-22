import 'package:ispectify/src/network/replay/network_request_sender.dart';

/// Holds the [NetworkRequestSender]s registered by the host application.
///
/// The ISpect entry point owns a single instance; the composer UI reads it to
/// decide whether request sending is available and, when more than one client
/// is registered, which one to send through. Registration happens once at
/// startup, so the registry is intentionally plain (no change notification).
final class NetworkSenderRegistry {
  final List<NetworkRequestSender> _senders = [];

  /// Currently registered senders, in registration order.
  List<NetworkRequestSender> get senders => List.unmodifiable(_senders);

  /// Whether at least one client is available to send through.
  bool get hasSenders => _senders.isNotEmpty;

  /// Registers [sender], replacing any existing one with the same [id].
  void register(NetworkRequestSender sender) {
    _senders
      ..removeWhere((s) => s.id == sender.id)
      ..add(sender);
  }

  /// Removes the sender with [id], if present.
  void unregister(String id) => _senders.removeWhere((s) => s.id == id);

  /// Returns the sender with [id], or `null` when none is registered.
  NetworkRequestSender? byId(String id) {
    for (final sender in _senders) {
      if (sender.id == id) return sender;
    }
    return null;
  }

  void clear() => _senders.clear();
}
