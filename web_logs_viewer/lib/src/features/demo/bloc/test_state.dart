part of 'test_bloc.dart';

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
