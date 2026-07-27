import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart' show ISpect, kISpectEnabled;
import 'package:ispect/src/common/utils/logs_file/logs_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testRoot;
  late File lockHolderHelper;
  late File lockProbeHelper;

  setUpAll(() async {
    testRoot = await Directory.systemTemp.createTemp('ispect_logs_file_test_');
    lockHolderHelper = File(
      '${testRoot.path}${Platform.pathSeparator}lease_lock_holder.dart',
    );
    await lockHolderHelper.writeAsString('''
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final handle = await File(arguments.single).open(mode: FileMode.append);
  await handle.lock();
  stdout.writeln('locked');
  await stdin.first;
  await handle.unlock();
  await handle.close();
}
''');
    lockProbeHelper = File(
      '${testRoot.path}${Platform.pathSeparator}lease_lock_probe.dart',
    );
    await lockProbeHelper.writeAsString('''
import 'dart:io';

Future<void> main(List<String> arguments) async {
  RandomAccessFile? handle;
  try {
    handle = await File(arguments.single).open(mode: FileMode.append);
    await handle.lock();
    stdout.writeln('locked');
    await handle.unlock();
  } catch (_) {
    stdout.writeln('blocked');
  } finally {
    await handle?.close();
  }
}
''');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => testRoot.path);
  });

  tearDownAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await testRoot.exists()) await testRoot.delete(recursive: true);
  });

  group('LogsFileFactory', () {
    test('creates platform-appropriate handler', () {
      final handler = LogsFileFactory.create();
      expect(handler, isA<BaseLogsFile>());

      // The specific type depends on platform but should always extend BaseLogsFile
      expect(handler.supportsNativeFiles, isA<bool>());
    });

    test('can create log files', () async {
      const testContent = 'Test log content\nLine 2\nLine 3';
      const fileName = 'test_logs';

      final logFile = await LogsFileFactory.createLogsFile(
        testContent,
        fileName: fileName,
      );

      expect(logFile, isNotNull);

      final handler = LogsFileFactory.create();
      final filePath = handler.getFilePath(logFile);
      expect(filePath, isA<String>());
      expect(filePath.isNotEmpty, isTrue);
      final nativeFile = File(filePath);
      expect(
        nativeFile.parent.path.split(Platform.pathSeparator).last,
        startsWith('ispect_logs_'),
      );
      expect(
        nativeFile.parent.parent.path,
        await testRoot.resolveSymbolicLinks(),
      );
      if (Platform.isLinux || Platform.isMacOS) {
        expect((await nativeFile.parent.stat()).mode & 0x3f, 0);
        expect((await nativeFile.stat()).mode & 0x3f, 0);
      }

      // Verify file size
      final size = await handler.getFileSize(logFile);
      expect(size, greaterThan(0));
      expect(size, equals(testContent.length));

      // Verify content
      final readContent = await handler.readAsString(logFile);
      expect(readContent, equals(testContent));

      // Clean up
      await handler.deleteFile(logFile);
    });

    test('concurrent persistent exports never replace one another', () async {
      final files = await Future.wait([
        LogsFileFactory.createLogsFile(
          'first persistent export',
          fileName: 'concurrent_persistent',
        ),
        LogsFileFactory.createLogsFile(
          'second persistent export',
          fileName: 'concurrent_persistent',
        ),
      ]);
      final handler = LogsFileFactory.create();
      addTearDown(() async {
        for (final file in files) {
          await handler.deleteFile(file);
        }
      });

      final paths = files.map(handler.getFilePath).toSet();
      expect(paths, hasLength(2));
      expect(
        await Future.wait(files.map(handler.readAsString)),
        containsAll([
          'first persistent export',
          'second persistent export',
        ]),
      );
    });

    test(
      'ignores a linked persistent-directory lookalike',
      () async {
        final logsPath =
            '${testRoot.path}${Platform.pathSeparator}ispect_logs_poison';
        final logsDirectory = Directory(logsPath);
        if (await logsDirectory.exists()) {
          await logsDirectory.delete(recursive: true);
        }

        final outside =
            await Directory.systemTemp.createTemp('ispect_outside_logs_');
        final sentinel = File(
          '${outside.path}${Platform.pathSeparator}sentinel.txt',
        );
        await sentinel.writeAsString('outside logs sentinel');
        final logsLink = Link(logsPath);
        await logsLink.create(outside.path);
        addTearDown(() async {
          if (await FileSystemEntity.type(
                logsPath,
                followLinks: false,
              ) ==
              FileSystemEntityType.link) {
            await logsLink.delete();
          }
          if (!await logsDirectory.exists()) {
            await logsDirectory.create();
          }
          if (await outside.exists()) {
            await outside.delete(recursive: true);
          }
        });

        final created = await LogsFileFactory.createLogsFile(
          'must not escape the platform directory',
          fileName: 'linked_persistent',
        );
        final createdFile = created as File;
        addTearDown(createdFile.delete);

        expect(await sentinel.readAsString(), 'outside logs sentinel');
        expect(
          await outside.list(followLinks: false).length,
          1,
        );
        expect(createdFile.parent.path, isNot(outside.path));
      },
      skip: Platform.isWindows
          ? 'Creating test symlinks requires Windows developer privileges.'
          : false,
    );

    test(
      'rejects a group- or world-writable app support directory',
      () async {
        if (Platform.isWindows) {
          markTestSkipped('POSIX permission bits are unavailable on Windows');
          return;
        }
        final chmod = await Process.run('/bin/chmod', ['0777', testRoot.path]);
        expect(chmod.exitCode, 0);
        addTearDown(() async {
          await Process.run('/bin/chmod', ['0700', testRoot.path]);
        });

        await expectLater(
          LogsFileFactory.createLogsFile(
            'must not use an unsafe app support directory',
            fileName: 'unsafe_support',
          ),
          throwsA(isA<FileSystemException>()),
        );
      },
      skip: Platform.isWindows
          ? 'POSIX permission bits are unavailable on Windows.'
          : false,
    );

    test('shares native exports from the temporary share directory', () async {
      String? sharedPath;

      await LogsFileFactory.shareFile(
        'temporary log content',
        fileName: 'share_test',
        onShare: (request) async {
          sharedPath = request.filePaths.single;
        },
      );

      expect(sharedPath, isNotNull);
      expect(sharedPath, contains('${Platform.pathSeparator}ispect_share'));
      expect(
        sharedPath,
        isNot(
          contains('${Platform.pathSeparator}logs${Platform.pathSeparator}'),
        ),
      );
      final sharedFile = File(sharedPath!);
      final sharedDirectory = sharedFile.parent;
      expect(
        sharedDirectory.path.split(Platform.pathSeparator).last,
        startsWith('process_'),
      );
      expect(
        sharedDirectory.parent.path.split(Platform.pathSeparator).last,
        'ispect_share',
      );
      if (!Platform.isWindows) {
        final mode = (await sharedDirectory.stat()).mode;
        expect(mode & 0x3f, 0);
      }
      expect(await sharedFile.exists(), isTrue);
      await sharedFile.delete();
    });

    test('concurrent shares use distinct files without overwriting', () async {
      final sharedPaths = <String>[];

      await Future.wait([
        LogsFileFactory.shareFile(
          'first log content',
          fileName: 'concurrent_share',
          onShare: (request) async => sharedPaths.add(request.filePaths.single),
        ),
        LogsFileFactory.shareFile(
          'second log content',
          fileName: 'concurrent_share',
          onShare: (request) async => sharedPaths.add(request.filePaths.single),
        ),
      ]);

      expect(sharedPaths, hasLength(2));
      expect(sharedPaths.toSet(), hasLength(2));
      final contents = await Future.wait(
        sharedPaths.map((path) => File(path).readAsString()),
      );
      expect(
        contents,
        containsAll(['first log content', 'second log content']),
      );

      await Future.wait(
        sharedPaths.map((path) => File(path).delete()),
      );
    });

    test('holds the OS lease lock while a share callback is pending', () async {
      final callbackStarted = Completer<String>();
      final releaseCallback = Completer<void>();
      String? sharedPath;
      final share = LogsFileFactory.shareFile(
        'locked pending share',
        fileName: 'persistent_lease_lock',
        onShare: (request) async {
          final path = request.filePaths.single;
          sharedPath = path;
          callbackStarted.complete(path);
          await releaseCallback.future;
        },
      );
      addTearDown(() async {
        if (!releaseCallback.isCompleted) releaseCallback.complete();
        await share;
        final path = sharedPath;
        if (path != null && await File(path).exists()) {
          await File(path).delete();
        }
      });

      final path = await callbackStarted.future;
      final lease = File(
        '${File(path).parent.path}${Platform.pathSeparator}.active-share',
      );

      expect(await _probeLeaseLock(lockProbeHelper, lease), 'blocked');

      releaseCallback.complete();
      await share;
    });

    test('share handoff keeps the successor callback leased', () async {
      final firstStarted = Completer<String>();
      final releaseFirst = Completer<void>();
      final secondStarted = Completer<String>();
      final releaseSecond = Completer<void>();
      String? firstPath;
      String? secondPath;

      final firstShare = LogsFileFactory.shareFile(
        'first handoff share',
        fileName: 'handoff_first',
        onShare: (request) async {
          final path = request.filePaths.single;
          firstPath = path;
          firstStarted.complete(path);
          await releaseFirst.future;
        },
      );
      await firstStarted.future;

      releaseFirst.complete();
      final secondShare = LogsFileFactory.shareFile(
        'second handoff share',
        fileName: 'handoff_second',
        onShare: (request) async {
          final path = request.filePaths.single;
          secondPath = path;
          secondStarted.complete(path);
          await releaseSecond.future;
        },
      );
      addTearDown(() async {
        if (!releaseFirst.isCompleted) releaseFirst.complete();
        if (!releaseSecond.isCompleted) releaseSecond.complete();
        await Future.wait([firstShare, secondShare]);
        for (final path in [firstPath, secondPath]) {
          if (path != null && await File(path).exists()) {
            await File(path).delete();
          }
        }
      });

      final successorPath = await secondStarted.future;
      await firstShare;
      final successorLease = File(
        '${File(successorPath).parent.path}'
        '${Platform.pathSeparator}.active-share',
      );

      expect(
        await _probeLeaseLock(lockProbeHelper, successorLease),
        'blocked',
      );

      releaseSecond.complete();
      await secondShare;
    });

    test('recreates the private share directory after external cleanup',
        () async {
      late String firstPath;
      late String secondPath;

      await LogsFileFactory.shareFile(
        'first share',
        fileName: 'removed_parent',
        onShare: (request) async => firstPath = request.filePaths.single,
      );
      final firstDirectory = File(firstPath).parent;
      await firstDirectory.delete(recursive: true);

      await LogsFileFactory.shareFile(
        'second share',
        fileName: 'recreated_parent',
        onShare: (request) async => secondPath = request.filePaths.single,
      );
      final secondFile = File(secondPath);

      expect(await secondFile.exists(), isTrue);
      expect(secondFile.parent.path, isNot(firstDirectory.path));
      expect(await secondFile.readAsString(), 'second share');
      await secondFile.delete();
    });

    test(
      'rejects a linked share root without writing outside cache',
      () async {
        final root = Directory(
          '${testRoot.path}${Platform.pathSeparator}ispect_share',
        );
        if (await root.exists()) await root.delete(recursive: true);
        final outside =
            await Directory.systemTemp.createTemp('ispect_outside_root_');
        final sentinel = File(
          '${outside.path}${Platform.pathSeparator}sentinel.txt',
        );
        await sentinel.writeAsString('outside root sentinel');
        final rootLink = Link(root.path);
        await rootLink.create(outside.path);
        addTearDown(() async {
          if (await rootLink.exists()) await rootLink.delete();
          if (!await root.exists()) await root.create();
          if (await outside.exists()) await outside.delete(recursive: true);
        });

        await expectLater(
          LogsFileFactory.shareFile(
            'must not escape cache',
            fileName: 'linked_root',
            onShare: (_) async {},
          ),
          throwsA(isA<FileSystemException>()),
        );

        expect(await sentinel.readAsString(), 'outside root sentinel');
        expect(
          await outside
              .list(followLinks: false)
              .where(
                (entry) =>
                    entry is Directory &&
                    entry.path
                        .split(Platform.pathSeparator)
                        .last
                        .startsWith('process_'),
              )
              .isEmpty,
          isTrue,
        );
      },
      skip: Platform.isWindows
          ? 'Creating test symlinks requires Windows developer privileges.'
          : false,
    );

    test(
      'abandons a process directory whose lease is a symlink',
      () async {
        late String firstPath;
        await LogsFileFactory.shareFile(
          'first linked-lease share',
          fileName: 'linked_lease_first',
          onShare: (request) async => firstPath = request.filePaths.single,
        );
        final poisonedDirectory = File(firstPath).parent;
        await File(firstPath).delete();
        final leasePath =
            '${poisonedDirectory.path}${Platform.pathSeparator}.active-share';
        final lease = File(leasePath);
        expect(await lease.exists(), isTrue);
        await lease.delete();

        final outside =
            await Directory.systemTemp.createTemp('ispect_outside_lease_');
        final sentinel = File(
          '${outside.path}${Platform.pathSeparator}sentinel.txt',
        );
        await sentinel.writeAsString('outside lease sentinel');
        final leaseLink = Link(leasePath);
        await leaseLink.create(sentinel.path);
        addTearDown(() async {
          if (await leaseLink.exists()) await leaseLink.delete();
          if (await poisonedDirectory.exists()) {
            await poisonedDirectory.delete(recursive: true);
          }
          if (await outside.exists()) await outside.delete(recursive: true);
        });
        late String secondPath;

        await LogsFileFactory.shareFile(
          'second linked-lease share',
          fileName: 'linked_lease_second',
          onShare: (request) async => secondPath = request.filePaths.single,
        );

        expect(await sentinel.readAsString(), 'outside lease sentinel');
        expect(File(secondPath).parent.path, isNot(poisonedDirectory.path));
        await File(secondPath).delete();
      },
      skip: Platform.isWindows
          ? 'Creating test symlinks requires Windows developer privileges.'
          : false,
    );

    test('ignores lookalike share directories outside the managed root',
        () async {
      final foreignDirectory = await testRoot.createTemp('ispect_share_');
      final foreignFile = File(
        '${foreignDirectory.path}${Platform.pathSeparator}foreign.json',
      );
      final foreignLease = File(
        '${foreignDirectory.path}${Platform.pathSeparator}.active-share',
      );
      await foreignFile.writeAsString('foreign diagnostics');
      await foreignLease.writeAsString('foreign-owner');
      await foreignFile.setLastModified(
        DateTime.now().subtract(const Duration(hours: 2)),
      );
      addTearDown(() async {
        if (await foreignDirectory.exists()) {
          await foreignDirectory.delete(recursive: true);
        }
      });
      late String sharedPath;

      await LogsFileFactory.shareFile(
        'current share',
        fileName: 'cross_process_sweep',
        onShare: (request) async => sharedPath = request.filePaths.single,
      );

      expect(await foreignFile.exists(), isTrue);
      expect(await foreignLease.exists(), isTrue);
      await File(sharedPath).delete();
    });

    test('removes crashed-process diagnostics after its lease expires',
        () async {
      final root = Directory(
        '${testRoot.path}${Platform.pathSeparator}ispect_share',
      );
      await root.create(recursive: true);
      final staleDirectory = await root.createTemp('process_');
      final staleFile = File(
        '${staleDirectory.path}${Platform.pathSeparator}stale.json',
      );
      final staleLease = File(
        '${staleDirectory.path}${Platform.pathSeparator}.active-share',
      );
      await staleFile.writeAsString('stale diagnostics');
      await staleLease.writeAsString('crashed-owner');
      final old = DateTime.now().subtract(const Duration(hours: 2));
      await staleFile.setLastModified(old);
      await staleLease.setLastModified(old);
      addTearDown(() async {
        if (await staleDirectory.exists()) {
          await staleDirectory.delete(recursive: true);
        }
      });
      late String sharedPath;

      await LogsFileFactory.shareFile(
        'current share',
        fileName: 'stale_process_sweep',
        onShare: (request) async => sharedPath = request.filePaths.single,
      );

      expect(await staleFile.exists(), isFalse);
      expect(await staleDirectory.exists(), isTrue);
      expect(await staleLease.exists(), isTrue);
      await File(sharedPath).delete();
    });

    test('a fresh foreign lease protects an active cross-process share',
        () async {
      final root = Directory(
        '${testRoot.path}${Platform.pathSeparator}ispect_share',
      );
      await root.create(recursive: true);
      final activeDirectory = await root.createTemp('process_');
      final activeFile = File(
        '${activeDirectory.path}${Platform.pathSeparator}active.json',
      );
      final activeLease = File(
        '${activeDirectory.path}${Platform.pathSeparator}.active-share',
      );
      await activeFile.writeAsString('active diagnostics');
      await activeFile.setLastModified(
        DateTime.now().subtract(const Duration(hours: 2)),
      );
      await activeLease.writeAsString('active-owner');
      addTearDown(() async {
        if (await activeDirectory.exists()) {
          await activeDirectory.delete(recursive: true);
        }
      });
      late String sharedPath;

      await LogsFileFactory.shareFile(
        'current share',
        fileName: 'active_process_sweep',
        onShare: (request) async => sharedPath = request.filePaths.single,
      );

      expect(await activeFile.exists(), isTrue);
      expect(await activeLease.exists(), isTrue);
      await File(sharedPath).delete();
    });

    test('stale sweep preserves a file with a pending share callback',
        () async {
      final callbackStarted = Completer<String>();
      final releaseCallback = Completer<void>();
      String? firstPath;
      String? secondPath;

      final firstShare = LogsFileFactory.shareFile(
        'pending share content',
        fileName: 'pending_share',
        onShare: (request) async {
          final path = request.filePaths.single;
          firstPath = path;
          callbackStarted.complete(path);
          await releaseCallback.future;
        },
      );
      addTearDown(() async {
        if (!releaseCallback.isCompleted) releaseCallback.complete();
        await firstShare;
        for (final path in [firstPath, secondPath]) {
          if (path == null) continue;
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      });

      firstPath = await callbackStarted.future;
      final firstFile = File(firstPath!);
      await firstFile.setLastModified(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      await LogsFileFactory.shareFile(
        'second share content',
        fileName: 'sweep_trigger',
        onShare: (request) async {
          secondPath = request.filePaths.single;
        },
      );

      expect(await firstFile.exists(), isTrue);

      releaseCallback.complete();
      await firstShare;
    });

    test('a freshly created lease-less process directory gets a grace period',
        () async {
      final root = Directory(
        '${testRoot.path}${Platform.pathSeparator}ispect_share',
      );
      await root.create(recursive: true);
      final foreignDirectory = await root.createTemp('process_');
      final foreignFile = File(
        '${foreignDirectory.path}${Platform.pathSeparator}foreign.json',
      );
      await foreignFile.writeAsString('foreign diagnostics');
      await foreignFile.setLastModified(
        DateTime.now().subtract(const Duration(hours: 2)),
      );
      addTearDown(() async {
        if (await foreignDirectory.exists()) {
          await foreignDirectory.delete(recursive: true);
        }
      });
      late String sharedPath;

      await LogsFileFactory.shareFile(
        'current share',
        fileName: 'lease_less_grace',
        onShare: (request) async => sharedPath = request.filePaths.single,
      );

      expect(await foreignDirectory.exists(), isTrue);
      expect(await foreignFile.exists(), isTrue);
      expect(
        await File(
          '${foreignDirectory.path}${Platform.pathSeparator}.active-share',
        ).exists(),
        isFalse,
      );
      await File(sharedPath).delete();
    });

    test('never opens another isolate directory from the current process',
        () async {
      final root = Directory(
        '${testRoot.path}${Platform.pathSeparator}ispect_share',
      );
      await root.create(recursive: true);
      final sameProcessDirectory = await root.createTemp('process_${pid}_');
      final sameProcessFile = File(
        '${sameProcessDirectory.path}${Platform.pathSeparator}active.json',
      );
      final sameProcessLease = File(
        '${sameProcessDirectory.path}${Platform.pathSeparator}.active-share',
      );
      await sameProcessFile.writeAsString('same-process diagnostics');
      await sameProcessLease.writeAsString('owner=other-isolate\nversion=1\n');
      final old = DateTime.now().subtract(const Duration(hours: 2));
      await sameProcessFile.setLastModified(old);
      await sameProcessLease.setLastModified(old);
      final sameProcessHandle =
          await sameProcessLease.open(mode: FileMode.append);
      await sameProcessHandle.lock();
      var handleClosed = false;
      addTearDown(() async {
        if (!handleClosed) {
          await sameProcessHandle.unlock();
          await sameProcessHandle.close();
        }
        if (await sameProcessDirectory.exists()) {
          await sameProcessDirectory.delete(recursive: true);
        }
      });
      late String sharedPath;

      await LogsFileFactory.shareFile(
        'current isolate share',
        fileName: 'same_process_isolate',
        onShare: (request) async => sharedPath = request.filePaths.single,
      );

      expect(await sameProcessFile.exists(), isTrue);
      expect(await sameProcessLease.exists(), isTrue);
      expect(
        await _probeLeaseLock(lockProbeHelper, sameProcessLease),
        'blocked',
      );
      await sameProcessHandle.unlock();
      await sameProcessHandle.close();
      handleClosed = true;
      await File(sharedPath).delete();
    });

    test('a stale but actively locked foreign lease is never swept', () async {
      final root = Directory(
        '${testRoot.path}${Platform.pathSeparator}ispect_share',
      );
      await root.create(recursive: true);
      final foreignDirectory = await root.createTemp('process_');
      final foreignFile = File(
        '${foreignDirectory.path}${Platform.pathSeparator}foreign.json',
      );
      final foreignLease = File(
        '${foreignDirectory.path}${Platform.pathSeparator}.active-share',
      );
      await foreignFile.writeAsString('active foreign diagnostics');
      await foreignLease.writeAsString('owner=foreign\nversion=1\n');
      final old = DateTime.now().subtract(const Duration(hours: 2));
      await foreignFile.setLastModified(old);
      await foreignLease.setLastModified(old);

      final process = await Process.start(
        Platform.isWindows ? 'dart.exe' : 'dart',
        [lockHolderHelper.path, foreignLease.path],
      );
      var helperExited = false;
      addTearDown(() async {
        if (!helperExited) {
          process.kill();
          await process.exitCode;
        }
        if (await foreignDirectory.exists()) {
          await foreignDirectory.delete(recursive: true);
        }
      });
      final ready = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 10));
      expect(ready, 'locked');
      late String sharedPath;

      await LogsFileFactory.shareFile(
        'current share',
        fileName: 'locked_foreign_lease',
        onShare: (request) async => sharedPath = request.filePaths.single,
      );

      expect(await foreignDirectory.exists(), isTrue);
      expect(await foreignFile.exists(), isTrue);
      expect(await foreignLease.exists(), isTrue);
      await File(sharedPath).delete();

      process.stdin.writeln('release');
      await process.stdin.close();
      expect(await process.exitCode, 0);
      helperExited = true;
    });

    test(
      'lazy initialization sweeps crashed diagnostics without a later share',
      () async {
        final root = Directory(
          '${testRoot.path}${Platform.pathSeparator}ispect_share',
        );
        await root.create(recursive: true);
        final staleDirectory = await root.createTemp('process_');
        final staleFile = File(
          '${staleDirectory.path}${Platform.pathSeparator}stale.json',
        );
        final staleLease = File(
          '${staleDirectory.path}${Platform.pathSeparator}.active-share',
        );
        await staleFile.writeAsString('stale restart diagnostics');
        await staleLease.writeAsString('owner=crashed\nversion=1\n');
        final old = DateTime.now().subtract(const Duration(hours: 2));
        await staleFile.setLastModified(old);
        await staleLease.setLastModified(old);
        var cleanupAttempts = 0;
        const channel = MethodChannel('plugins.flutter.io/path_provider');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (_) async {
          cleanupAttempts++;
          if (cleanupAttempts == 1) {
            throw MissingPluginException(
              'Binding/provider was not ready for early lazy cleanup.',
            );
          }
          return testRoot.path;
        });
        addTearDown(() async {
          await ISpect.dispose();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            channel,
            (_) async => testRoot.path,
          );
          if (await staleDirectory.exists()) {
            await staleDirectory.delete(recursive: true);
          }
        });

        final lazyLogger = ISpect.logger;
        await _waitUntil(() async => cleanupAttempts == 1);
        expect(ISpect.initialize(lazyLogger), isTrue);

        await _waitUntil(() async => !await staleFile.exists());
        expect(cleanupAttempts, greaterThanOrEqualTo(2));
        expect(await staleFile.exists(), isFalse);
        expect(await staleLease.exists(), isTrue);
        expect(await staleDirectory.exists(), isTrue);

        final attemptsAfterSuccess = cleanupAttempts;
        expect(ISpect.initialize(lazyLogger), isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(cleanupAttempts, attemptsAfterSuccess);
      },
      skip: !kISpectEnabled,
    );
  });
}

Future<void> _waitUntil(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Timed out waiting for native share cleanup.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<String> _probeLeaseLock(File helper, File lease) async {
  final result = await Process.run(
    Platform.isWindows ? 'dart.exe' : 'dart',
    [helper.path, lease.path],
  ).timeout(const Duration(seconds: 10));
  if (result.exitCode != 0) {
    throw ProcessException(
      helper.path,
      [lease.path],
      result.stderr.toString(),
      result.exitCode,
    );
  }
  return result.stdout.toString().trim();
}
