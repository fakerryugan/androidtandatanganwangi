import 'package:flutter/material.dart';
import 'package:android/bottom_navbar/profil.dart';
import 'package:android/bottom_navbar/home.dart';
import 'package:android/bottom_navbar/setting.dart';
import 'package:android/bottom_navbar/home_bloc.dart';
import 'package:android/signature/signature_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int myCurrentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    SignaturePage(),
    ProfilPage(),
    SettingPage(),
  ];

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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(127, 146, 248, 1),
            Color.fromRGBO(89, 117, 234, 1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          currentIndex: myCurrentIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          onTap: (index) {
            setState(() {
              myCurrentIndex = index;

              if (index == 0) {
                context.read<HomeBloc>().add(LoadHomeData());
              }
            });
          },
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.edit_outlined, Icons.edit, 1),
              label: "Signature",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outline, Icons.person, 2),
              label: "Profile",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.settings_outlined, Icons.settings, 3),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = myCurrentIndex == index;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(isSelected ? filledIcon : outlinedIcon, size: 24),
    );
  }
}
