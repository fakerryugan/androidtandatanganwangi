import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/network_helper.dart';
import '../../../model/model_user.dart';
import '../repository/login_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;

  LoginBloc(this.repository) : super(LoginInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(LoginLoading());
      if (!await NetworkHelper.hasConnection()) {
        emit(LoginFailure("Tidak ada koneksi internet"));
        return;
      }

      try {
        final user = await repository.login(event.username, event.password);

        await Future.wait([
          StorageService.saveUser(jsonEncode(user!.toJson())),
          FcmService.updateFcmToken(user.token),
        ]);

        emit(LoginSuccess(user));
      } catch (e) {
        emit(LoginFailure("Login gagal: ${e.toString()}"));
      }
    });

    on<AppStarted>((event, emit) async {
      final userJson = await StorageService.getUser();
      if (userJson != null) {
        final user = User.fromJson(
          jsonDecode(userJson),
          jsonDecode(userJson)['token'],
        );
        emit(LoginSuccess(user));
      } else {
        emit(LoginInitial());
      }
    });

    on<LogoutRequested>((event, emit) async {
      final userJson = await StorageService.getUser();
      if (userJson != null) {
        await Future.wait([FcmService.clearFcm(), StorageService.removeUser()]);
      }
      emit(LoginInitial());
    });
  }
}
