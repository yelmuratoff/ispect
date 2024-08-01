import 'package:atlassian_apis/jira_platform.dart';
import 'package:bloc/bloc.dart';
import 'package:ispect/src/features/jira/jira_client.dart';
import 'package:meta/meta.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(const UsersState.initial());

  Future<void> getUsers() async {
    emit(const UsersState.loading());

    try {
      final users = await JiraClient.getUsers();
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
