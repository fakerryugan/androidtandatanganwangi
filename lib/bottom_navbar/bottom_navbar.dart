import 'package:flutter/material.dart';
import 'package:android/bottom_navbar/profil.dart';
import 'package:android/bottom_navbar/home.dart';
import 'package:android/bottom_navbar/setting.dart';
import 'package:android/bottom_navbar/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int myCurrentIndex = 0;

  final List<Widget> pages = const [HomePage(), ProfilPage(), SettingPage()];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(LoadHomeData()),
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: _buildBottomNav(),
        body: pages[myCurrentIndex],
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
              // kalau ke index 0 (Home), refresh data dokumen biar update terbaru
              if (index == 0) {
                context.read<HomeBloc>().add(LoadHomeData());
              }
            });
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
