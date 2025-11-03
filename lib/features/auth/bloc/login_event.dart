abstract class LoginEvent {}

class LoginRequested extends LoginEvent {
  final String username;
  final String password;
  LoginRequested(this.username, this.password);
}

class AppStarted extends LoginEvent {}

class LogoutRequested extends LoginEvent {}
