import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';
import 'package:ispect_jira/src/jira/models/board.dart';
import 'package:meta/meta.dart';

part 'boards_state.dart';

class BoardsCubit extends Cubit<BoardsState> {
  BoardsCubit() : super(const BoardsState.initial());

  Future<void> getBoards() async {
    emit(const BoardsState.loading());

    try {
      final boards = await ISpectJiraClient.getBoards();
      emit(BoardsState.loaded(boards: boards));
    } catch (error, stackTrace) {
      emit(BoardsState.error(error: error, stackTrace: stackTrace));
    }
  }
}
