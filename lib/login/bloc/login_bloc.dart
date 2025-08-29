import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/loginsystem.dart';
import '../../model/model_user.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;

  LoginBloc(this.repository) : super(LoginInitial()) {
    // Event LoginRequested
    on<LoginRequested>((event, emit) async {
      emit(LoginLoading());
      try {
        final user = await repository.login(event.username, event.password);

        if (user != null && user.token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(user.toJson()));

          emit(LoginSuccess(user)); // ✅ kirim User, bukan String
        } else {
          emit(LoginFailure("Token tidak ditemukan"));
        }
      } catch (e) {
        emit(LoginFailure("Terjadi kesalahan: $e"));
      }
    });

    // Event AppStarted → cek user tersimpan
    on<AppStarted>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        final user = User.fromJson(
          jsonDecode(userString),
          jsonDecode(userString)['token'],
        );
        if (user.token.isNotEmpty) {
          emit(LoginSuccess(user));
          return;
        }
      }

      emit(LoginInitial());
    });

    // Event LogoutRequested
    on<LogoutRequested>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      emit(LoginInitial());
    });
  }
}
