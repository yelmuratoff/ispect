import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const _prefix = 'ext.ispect.';
const _timeout = Duration(seconds: 10);
const _usage =
    'Usage: ispect_logs.dart <vm-service-uri> <method> [name=value ...]\n'
    'Methods: getSummary, getLogs, getLog, getTrace';

Future<void> main(List<String> args) async {
  if (args.length < 2) return _fail(_usage, code: 64);
  final [rawUri, rawMethod, ...pairs] = args;
  final method =
      rawMethod.startsWith('ext.') ? rawMethod : '$_prefix$rawMethod';
  if (!method.startsWith(_prefix)) {
    return _fail('Only $_prefix* methods are allowed, got "$rawMethod".');
  }
  final params = <String, String>{};
  for (final pair in pairs) {
    final separator = pair.indexOf('=');
    if (separator < 1) {
      return _fail('Expected name=value, got "$pair".\n$_usage', code: 64);
    }
    params[pair.substring(0, separator)] = pair.substring(separator + 1);
  }

  final VmService service;
  try {
    service = await vmServiceConnectUri(
      _webSocketUri(rawUri),
    ).timeout(_timeout);
  } on Object catch (error) {
    return _fail('Cannot connect to $rawUri: $error');
  }
  try {
    final available = <String>{};
    final vm = await service.getVM();
    for (final ref in vm.isolates ?? const <IsolateRef>[]) {
      final Isolate isolate;
      try {
        isolate = await service.getIsolate(ref.id!);
      } on SentinelException {
        continue;
      }
      final extensions = isolate.extensionRPCs ?? const <String>[];
      available.addAll(extensions.where((name) => name.startsWith(_prefix)));
      if (!extensions.contains(method)) continue;
      final response = await service
          .callServiceExtension(method, isolateId: ref.id, args: params)
          .timeout(_timeout);
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(response.json));
      return;
    }
    if (available.isNotEmpty) {
      return _fail(
        'Unknown method $method; available: ${available.join(', ')}.',
      );
    }
    _fail(
      'No isolate registers $_prefix* methods. Build with ISPECT_ENABLED=true '
      'and initialize ISpect before querying.',
    );
  } on RPCError catch (error) {
    _fail(error.details ?? error.message);
  } on TimeoutException {
    _fail('No reply within ${_timeout.inSeconds}s; the isolate may be paused.');
  } finally {
    await service.dispose();
  }
}

String _webSocketUri(String uri) {
  final parsed = Uri.parse(uri);
  final scheme = switch (parsed.scheme) {
    'http' => 'ws',
    'https' => 'wss',
    final other => other,
  };
  final path = parsed.path.endsWith('/ws')
      ? parsed.path
      : '${parsed.path.endsWith('/') ? parsed.path : '${parsed.path}/'}ws';
  return parsed.replace(scheme: scheme, path: path).toString();
}

void _fail(String message, {int code = 1}) {
  stderr.writeln(message);
  exitCode = code;
}
