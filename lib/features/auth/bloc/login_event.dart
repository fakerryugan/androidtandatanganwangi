abstract class LoginEvent {}

class LoginRequested extends LoginEvent {
  final String username;
  final String password;
  final String nama;
  final String nim;

  LoginRequested(
    this.username,
    this.password, {
    required this.nama,
    required this.nim,
  });
}
