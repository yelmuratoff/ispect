import 'package:ispectify/src/network/replay/network_replay_request.dart';
import 'package:ispectify/src/network/replay/network_replay_result.dart';

/// Sends a composed/replayed request through a real, app-owned client.
///
/// Implemented per transport (`DioRequestSender` in `ispectify_dio`,
/// `HttpClientRequestSender` in `ispectify_http`) and registered by the host
/// app so the composer reuses the client's base URL, auth interceptors, and
/// retries instead of reconstructing them. Because the request travels through
/// the instrumented client, it is also logged by the existing interceptor — no
/// parallel, unredacted log is produced.
abstract interface class NetworkRequestSender {
  /// Stable identifier for the underlying transport (e.g. `dio`, `http`).
  String get id;

  /// Human-readable label shown when several senders are registered.
  String get label;

  /// Sends [request] and returns a summary of the response.
  ///
  /// Implementations translate transport errors into a
  /// [NetworkReplayResult] with a non-null `error` rather than throwing, so the
  /// composer can render the failure inline.
  Future<NetworkReplayResult> send(NetworkReplayRequest request);
}
