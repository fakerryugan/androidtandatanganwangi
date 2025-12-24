import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/network_helper.dart';
import '../../../core/model/model_user.dart';
import '../repository/login_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;

  LoginBloc(this.repository) : super(LoginInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(LoginLoading());
      try {
        final user = await repository.syncSsoUser(
          username: event.username,
          password: event.password,
          nama: event.nama,
          nim: event.nim,
        );
        emit(LoginSuccess(user!));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
  }
}
