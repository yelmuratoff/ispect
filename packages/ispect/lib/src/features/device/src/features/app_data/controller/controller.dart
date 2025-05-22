part of '../app_data_screen.dart';

class AppDataController extends ChangeNotifier {
  var _files = <File>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<File> get files => _files;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Loads the list of files from AppFileService
  ///
  /// Updates loading state and clears any previous error messages.
  /// If no files are found, returns an empty list.
  Future<void> loadFilesList({
    required BuildContext context,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final f = await AppFileService.instance.getFiles();
      _files = f;
      notifyListeners();
    } catch (e, st) {
      if (context.mounted &&
          !e.toString().contains('No such file or directory')) {
        ISpect.logger.handle(exception: e, stackTrace: st);
        _setError(e.toString());
        await _showErrorToast(context, e.toString());
      } else {
        _files = [];
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes a single file by index
  ///
  /// Throws an exception if the file can't be deleted.
  /// Performs index bounds checking to prevent out-of-range errors.
  /// Refreshes the file list after successful deletion.
  Future<void> deleteFile({
    required BuildContext context,
    required int index,
  }) async {
    if (index < 0 || index >= _files.length) return;

    _setLoading(true);
    try {
      await _files[index].delete();
      if (context.mounted) {
        await loadFilesList(context: context);
      }
    } on Exception catch (e, st) {
      ISpect.logger.handle(exception: e, stackTrace: st);
      if (context.mounted) {
        await _showErrorToast(context, e.toString());
      }
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  /// Deletes all files concurrently for improved performance
  ///
  /// Uses Future.wait to process file deletions in parallel.
  /// Individual file deletion errors are logged but don't stop the overall process.
  /// Refreshes the file list after all deletions are processed.
  Future<void> deleteFiles({
    required BuildContext context,
  }) async {
    if (_files.isEmpty) return;

    _setLoading(true);
    try {
      // Process file deletions in parallel for better performance
      await Future.wait(
        _files.map(
          (file) => file.delete().catchError((Object e) {
            // Log individual file deletion errors but continue processing
            ISpect.logger.handle(
              exception: e,
              stackTrace: StackTrace.current,
              message: 'Error deleting file: ${file.path}',
            );
            // Return the file since we need a compatible FileSystemEntity type
            return file;
          }),
        ),
      );

      if (context.mounted) {
        await loadFilesList(context: context);
      }
    } on Exception catch (e, st) {
      ISpect.logger.handle(exception: e, stackTrace: st);
      if (context.mounted) {
        await _showErrorToast(context, e.toString());
      }
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  /// Helper method for displaying error notifications
  Future<void> _showErrorToast(BuildContext context, String message) =>
      ISpectToaster.showErrorToast(
        context,
        title: message,
      );

  @override
  void dispose() {
    _files.clear();
    super.dispose();
  }
}
