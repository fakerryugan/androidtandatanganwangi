import 'package:flutter_bloc/flutter_bloc.dart';
import '../../api/token.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeLoading()) {
    on<LoadHomeData>((event, emit) async {
      emit(HomeLoading());
      try {
        final user = await fetchUserInfo();
        final documents = await fetchUserDocuments();

        emit(
          HomeLoaded(
            name: user?['name'] ?? 'Pengguna',
            nip: user?['nip'] ?? '-',
            role: user?['role_aktif']?.toUpperCase() ?? '-',
            documents: documents,
          ),
        );
      } catch (e) {
        emit(HomeError("Gagal memuat data: $e"));
      }
    });
  }
}
