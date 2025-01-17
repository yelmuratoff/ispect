import 'package:flutter_bloc/flutter_bloc.dart';

part 'test_state.dart';

class TestCubit extends Cubit<TestState> {
  TestCubit() : super(TestInitial());

  void load({required String data}) {
    emit(TestLoading());
    emit(TestLoaded(data));
  }
}
