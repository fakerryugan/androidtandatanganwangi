import '../../model/model_user.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final User user; // ✅ simpan User, bukan String
  LoginSuccess(this.user);
}

class LoginFailure extends LoginState {
  final String error;
  LoginFailure(this.error);
}

class LogoutLoading extends LoginState {}

class LogoutSuccess extends LoginState {}

class LogoutFailure extends LoginState {
  final String error;
  LogoutFailure(this.error);
}
