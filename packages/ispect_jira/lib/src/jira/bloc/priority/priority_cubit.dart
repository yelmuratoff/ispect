import 'package:atlassian_apis/jira_platform.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';
import 'package:meta/meta.dart';

part 'priority_state.dart';

class PriorityCubit extends Cubit<PriorityState> {
  PriorityCubit() : super(const PriorityState.initial());

  Future<void> getPriorities() async {
    emit(const PriorityState.loading());

    try {
      final priorities = await ISpectJiraClient.getPriorities();
      emit(PriorityState.loaded(priorities: priorities));
    } catch (error, stackTrace) {
      emit(PriorityState.error(error: error, stackTrace: stackTrace));
    }
  }
}
