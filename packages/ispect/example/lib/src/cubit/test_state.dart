part of 'test_cubit.dart';

sealed class TestState {}

final class TestInitial extends TestState {}

final class TestLoading extends TestState {}

final class TestLoaded extends TestState {
  final String data;

  TestLoaded(this.data);
}

final class TestError extends TestState {
  final String message;

  TestError(this.message);
}
