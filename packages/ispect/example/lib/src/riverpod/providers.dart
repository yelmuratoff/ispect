import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:dio/dio.dart';
import 'package:ispect_example/src/services/log_generation_service.dart';
import 'package:ispect_example/src/services/stream_service.dart';
import 'package:ispect_example/src/cubit/test_cubit.dart';
import 'package:ispect_example/src/bloc/counter_bloc.dart';

final dioProvider = Provider<Dio>((ref) => Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
      ),
    ));

final dummyDioProvider = Provider<Dio>((ref) => Dio(
      BaseOptions(
        baseUrl: 'https://api.escuelajs.co',
      ),
    ));

final clientProvider = Provider<http_interceptor.InterceptedClient>(
    (ref) => http_interceptor.InterceptedClient.build(interceptors: []));

final logGenerationServiceProvider = Provider<LogGenerationService>((ref) {
  final dio = ref.watch(dioProvider);
  final client = ref.watch(clientProvider);
  final dummyDio = ref.watch(dummyDioProvider);
  return LogGenerationService(
    dio: dio,
    client: client,
    dummyDio: dummyDio,
  );
});

final streamServiceProvider = Provider<StreamService>((ref) => StreamService());

final testCubitProvider = Provider<TestCubit>((ref) => TestCubit());

final counterBlocProvider = Provider<CounterBloc>((ref) => CounterBloc());
