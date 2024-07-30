import 'package:atlassian_apis/jira_platform.dart';
import 'package:bloc/bloc.dart';
import 'package:ispect/src/features/jira/jira_client.dart';
import 'package:meta/meta.dart';

part 'labels_state.dart';

class LabelsCubit extends Cubit<LabelsState> {
  LabelsCubit() : super(const LabelsState.initial());

  Future<void> getLabels() async {
    emit(const LabelsState.loading());
    try {
      final labels = await JiraClient.getLabels();
      emit(LabelsState.loaded(labels: labels));
    } catch (error, stackTrace) {
      emit(LabelsState.error(error: error, stackTrace: stackTrace));
    }
  }
}
