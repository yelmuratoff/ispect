part of '../app_data.dart';

class AppDataController extends ChangeNotifier {
  var _files = <File>[];
  List<File> get files => _files;

  Future<void> loadFilesList({
    required BuildContext context,
    required Talker talker,
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
        talker.handle(e, st);
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
    required Talker talker,
    required int index,
  }) async {
    try {
      await _files[index].delete();
      if (context.mounted) {
        await loadFilesList(
          context: context,
          talker: talker,
        );
      }
    } on Exception catch (e, st) {
      talker.handle(e, st);
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
    required Talker talker,
  }) async {
    try {
      for (final file in _files) {
        await file.delete();
      }
      if (context.mounted) {
        await loadFilesList(
          context: context,
          talker: talker,
        );
      }
    } on Exception catch (e, st) {
      talker.handle(e, st);
      if (context.mounted) {
        await ISpectToaster.showErrorToast(
          context,
          title: e.toString(),
        );
      }
    }
  }
}
