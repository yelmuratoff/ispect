import 'package:atlassian_apis/jira_platform.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';
import 'package:meta/meta.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(const UsersState.initial());

  Future<void> getUsers() async {
    emit(const UsersState.loading());

    try {
      final users = await ISpectJiraClient.getUsers();
      emit(
        UsersState.loaded(
          users: users
              .where((user) => user.active && user.accountType?.value != 'app')
              .toList(),
        ),
      );
    } catch (error, stackTrace) {
      emit(UsersState.error(error: error, stackTrace: stackTrace));
    }
  }
}
