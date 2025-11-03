part of 'dashboard_bloc.dart';

abstract class DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final String name;
  final String nip;
  final String role;
  final List<Map<String, dynamic>> documents;

  DashboardLoaded({
    required this.name,
    required this.nip,
    required this.role,
    required this.documents,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
