import 'package:bloc/bloc.dart';
import 'package:ispect/src/features/jira/jira_client.dart';
import 'package:ispect/src/features/jira/models/board.dart';
import 'package:meta/meta.dart';

part 'boards_state.dart';

class BoardsCubit extends Cubit<BoardsState> {
  BoardsCubit() : super(const BoardsState.initial());

  Future<void> getBoards() async {
    emit(const BoardsState.loading());

    try {
      final boards = await JiraClient.getBoards();
      emit(BoardsState.loaded(boards: boards));
    } catch (error, stackTrace) {
      emit(BoardsState.error(error: error, stackTrace: stackTrace));
    }
  }
}
