import 'package:flutter/widgets.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/logs_file/logs_file.dart';
import 'package:ispect/src/core/res/ispect_callbacks.dart';
import 'package:ispect/src/ispect.dart';
import 'package:ispectify/ispectify.dart';

/// Current state of an export operation.
enum ExportState { idle, exporting, done, error }

/// ViewModel for the unified export sheet.
///
/// Holds selected format, redaction preference, and async operation state.
/// All export logic lives here — the UI is purely declarative.
class ExportController extends ChangeNotifier {
  ExportController({
    required this.availableFormats,
    this.onShare,
    this.showRedaction = false,
  }) : _selectedFormat = availableFormats.first;

  // ── Configuration (immutable after construction) ──────────────────────

  final List<ExportFormat> availableFormats;
  final ISpectShareCallback? onShare;
  final bool showRedaction;

  bool get canShare => onShare != null;

  // ── Mutable state ─────────────────────────────────────────────────────

  ExportFormat _selectedFormat;
  ExportFormat get selectedFormat => _selectedFormat;

  bool _redact = true;
  bool get redact => _redact;

  ExportState _state = ExportState.idle;
  ExportState get state => _state;

  String _resultPath = '';
  String get resultPath => _resultPath;

  // ── State mutations ───────────────────────────────────────────────────

  void selectFormat(ExportFormat format) {
    if (_selectedFormat == format) return;
    _selectedFormat = format;
    notifyListeners();
  }

  void toggleRedaction() {
    _redact = !_redact;
    notifyListeners();
  }

  // ── Export actions ────────────────────────────────────────────────────

  Set<String>? get _effectiveRedactKeys =>
      showRedaction && _redact ? defaultSensitiveKeys : null;

  /// Shares the content via the platform share dialog.
  ///
  /// Requires [onShare] to be configured.
  Future<void> share(ExportContentBuilder contentBuilder) async {
    final shareCallback = onShare;
    if (shareCallback == null) return;
    await _run(ExportAction.share, contentBuilder, (content) async {
      await LogsFileFactory.downloadFile(
        content,
        fileName: _fileName,
        fileType: _selectedFormat.extension,
        onShare: shareCallback,
      );
    });
  }

  /// Downloads the content to device storage.
  ///
  /// On web triggers a browser download; on native saves to the logs
  /// directory and stores the path in [resultPath].
  Future<void> download(ExportContentBuilder contentBuilder) async {
    await _run(ExportAction.download, contentBuilder, (content) async {
      _resultPath = await LogsFileFactory.saveToDevice(
        content,
        fileName: _fileName,
        fileType: _selectedFormat.extension,
      );
    });
  }

  /// Copies the content to the system clipboard.
  Future<void> copy(
    BuildContext context,
    ExportContentBuilder contentBuilder,
  ) async {
    await _run(ExportAction.copy, contentBuilder, (content) async {
      if (!context.mounted) return;
      copyClipboard(context, value: content, showValue: false);
    });
  }

  // ── Internals ─────────────────────────────────────────────────────────

  String get _fileName =>
      'ispect_export_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _run(
    ExportAction action,
    ExportContentBuilder contentBuilder,
    Future<void> Function(String content) execute,
  ) async {
    if (_state == ExportState.exporting) return;
    _state = ExportState.exporting;
    notifyListeners();
    // Yield to let the UI rebuild and show loading indicator.
    await Future<void>.delayed(Duration.zero);
    try {
      final content = await contentBuilder(
        _selectedFormat,
        redactKeys: _effectiveRedactKeys,
        action: action,
      );
      if (content.isEmpty) {
        _state = ExportState.idle;
        notifyListeners();
        return;
      }
      await execute(content);
      _state = ExportState.done;
    } catch (e, st) {
      ISpect.logger.error('Export failed: $e', stackTrace: st);
      _state = ExportState.error;
    }
    notifyListeners();

    // Reset to idle after a short delay so the UI can show feedback.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_state != ExportState.exporting) {
      _state = ExportState.idle;
      notifyListeners();
    }
  }
}
