## VM service extensions

A debug or profile build compiled with `ISPECT_ENABLED` exposes the log
history through read-only VM service extensions, so DevTools, scripts, and AI
agents can query a running app. `ISpect.run` and `ISpect.initialize` register
them automatically. An app that uses only `ispectify` registers its logger
itself:

```dart
ISpectServiceExtensions.register(() => logger);
```

| Method                  | Returns                                                                                                         |
| ----------------------- | --------------------------------------------------------------------------------------------------------------- |
| `ext.ispect.getSummary` | Entry and level counts, the most frequent log keys, and the latest errors.                                      |
| `ext.ispect.getLogs`    | Compact entries filtered by `minLevel`, `keys`, and `query`, paged with `limit`, `afterId`, and `beforeId`.     |
| `ext.ispect.getLog`     | One full record by `id`.                                                                                        |
| `ext.ispect.getTrace`   | Up to 200 entries sharing a correlation or transaction ID, such as one call's request, response, and error.     |

Responses pass through the same redaction and size limits as a JSON Lines
export. Release builds have no VM service, and builds without the flag compile
the extensions out. A client connected through `package:vm_service` calls them
by name:

```dart
final response = await service.callServiceExtension(
  ISpectServiceExtensions.getLogs,
  isolateId: isolateId,
  args: {'minLevel': 'error', 'limit': '20'},
);
```
