import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/tokenapi.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService _apiService;

  DashboardBloc({required ApiService apiService})
    : _apiService = apiService,
      super(DashboardLoading()) {
    on<LoadDashboardData>((event, emit) async {
      emit(DashboardLoading());
      try {
        final user = await _apiService.fetchUserInfo();
        final documents = await _apiService.fetchUserDocuments();

        emit(
          DashboardLoaded(
            name: user?['name'] ?? 'Pengguna',
            nip: user?['nip'] ?? '-',
            role: user?['role_aktif']?.toUpperCase() ?? '-',
            documents: documents,
          ),
        );
      } catch (e) {
        emit(DashboardError("Gagal memuat data: $e"));
      }
    });
  }
}
