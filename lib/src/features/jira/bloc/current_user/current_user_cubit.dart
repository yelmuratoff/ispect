import 'package:atlassian_apis/jira_platform.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ispect/src/features/jira/jira_client.dart';

part 'current_user_state.dart';

class CurrentUserCubit extends Cubit<CurrentUserState> {
  CurrentUserCubit() : super(const CurrentUserState.initial());

  Future<void> getCurrentUser() async {
    try {
      emit(const CurrentUserState.loading());
      final user = await JiraClient.getCurrentUser();
      emit(CurrentUserState.loaded(user: user));
    } catch (error, stackTrace) {
      emit(CurrentUserState.error(error: error, stackTrace: stackTrace));
    }
  }
}
