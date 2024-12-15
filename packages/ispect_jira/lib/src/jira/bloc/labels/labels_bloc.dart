import 'package:atlassian_apis/jira_platform.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect_jira/src/jira/jira_client.dart';
import 'package:meta/meta.dart';

part 'labels_state.dart';

class LabelsCubit extends Cubit<LabelsState> {
  LabelsCubit() : super(const LabelsState.initial());

  Future<void> getLabels() async {
    emit(const LabelsState.loading());
    try {
      final labels = await ISpectJiraClient.getLabels();
      emit(LabelsState.loaded(labels: labels));
    } catch (error, stackTrace) {
      emit(LabelsState.error(error: error, stackTrace: stackTrace));
    }
  }
}
