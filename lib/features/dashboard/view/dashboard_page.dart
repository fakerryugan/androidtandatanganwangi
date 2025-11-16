import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/tokenapi.dart';
import '../bloc/dashboard_bloc.dart';
import 'menu_home.dart';
import 'menu_profile.dart';
import 'menu_settings.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int myCurrentIndex = 0;

  Widget getCurrentPage(int index) {
    switch (index) {
      case 0:
        return MenuHome();
      case 1:
        return MenuProfile();
      case 2:
        return MenuSettings();
      default:
        return MenuHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardBloc(apiService: ApiServiceImpl())
            ..add(LoadDashboardData()), // Load awal
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: _buildBottomNav(),
        body: getCurrentPage(myCurrentIndex),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 25, offset: Offset(8, 20)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF172B4C),
          selectedItemColor: const Color.fromRGBO(129, 132, 200, 1),
          unselectedItemColor: Colors.white,
          currentIndex: myCurrentIndex,
          onTap: (index) {
            setState(() {
              myCurrentIndex = index;
            });
            if (index == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<DashboardBloc>().add(LoadDashboardData());
              });
            }
          },
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Person"),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Setting",
            ),
          ],
        ),
      ),
    );
  }
}
