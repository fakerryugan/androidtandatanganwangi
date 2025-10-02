part of 'home_bloc.dart';

abstract class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String name;
  final String nip;
  final String role;
  final List<Map<String, dynamic>> documents;

  HomeLoaded({
    required this.name,
    required this.nip,
    required this.role,
    required this.documents,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
