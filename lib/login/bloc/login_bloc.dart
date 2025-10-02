import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
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
        emit(LoginFailure("Kredensial ini tidak cocok dengan catatan kami."));
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

      final userString = prefs.getString('user');
      if (userString != null) {
        final userMap = jsonDecode(userString);
        final tokenLogin = userMap['token'];

        try {
          // panggil API logout di server
          final url = Uri.parse('http://fakerryugan.my.id/api/logout');
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tokenLogin',
            },
          );
          if (response.statusCode == 200) {
            print("✅ Logout API berhasil");
          } else {
            print("❌ Logout API gagal: ${response.body}");
          }

          // hapus FCM token di server
          await LoginRepository().updateFcmToken(tokenLogin, "");
          print("✅ FCM token dihapus dari server");

          // hapus FCM token di device
          await FirebaseMessaging.instance.deleteToken();
          print("✅ FCM token dihapus dari device");
        } catch (e) {
          print("❌ Error saat logout: $e");
        }
      }

      await prefs.remove('user'); // hapus data user lokal
      emit(LoginInitial());
    });
  }
}
