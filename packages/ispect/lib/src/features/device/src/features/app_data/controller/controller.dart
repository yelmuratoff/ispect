part of '../app_data_screen.dart';

class AppDataController extends ChangeNotifier {
  var _files = <File>[];
  List<File> get files => _files;

  Future<void> loadFilesList({
    required BuildContext context,
  }) async {
    try {
      final f = await AppFileService.instance.getFiles();
      _files = f;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e, st) {
      if (context.mounted &&
          !e.toString().contains('No such file or directory')) {
        ISpect.logger.handle(exception: e, stackTrace: st);
        await ISpectToaster.showErrorToast(
          context,
          title: e.toString(),
        );
      } else {
        _files = [];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    }
  }

  Future<void> deleteFile({
    required BuildContext context,
    required int index,
  }) async {
    try {
      await _files[index].delete();
      if (context.mounted) {
        await loadFilesList(
          context: context,
        );
      }
    } on Exception catch (e, st) {
      ISpect.logger.handle(exception: e, stackTrace: st);
      if (context.mounted) {
        await ISpectToaster.showErrorToast(
          context,
          title: e.toString(),
        );
      }
    }
  }

  Future<void> deleteFiles({
    required BuildContext context,
  }) async {
    try {
      for (final file in _files) {
        await file.delete();
      }
      if (context.mounted) {
        await loadFilesList(
          context: context,
        );
      }
    } on Exception catch (e, st) {
      ISpect.logger.handle(exception: e, stackTrace: st);
      if (context.mounted) {
        await ISpectToaster.showErrorToast(
          context,
          title: e.toString(),
        );
      }
    }
  }
}
