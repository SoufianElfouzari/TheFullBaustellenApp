import 'package:appwrite/models.dart';
import 'package:baustellenapp/Screens/Baustellenoverview/Mobile/baustellen_overview.dart';
import 'package:baustellenapp/Screens/Chatoverview/Mobile/chat_overview.dart';
import 'package:baustellenapp/Screens/Kalender/Mobile/kalender_mobile.dart';
import 'package:baustellenapp/Screens/Settings/Mobile/settings.dart';
import 'package:baustellenapp/Screens/Zeiterfassung/Mobile/zeiterfassung_mobile.dart';
import 'package:flutter/material.dart';
import '../Widgets/bottom_navigation_bar.dart';
import 'package:baustellenapp/Constants/colors.dart';
import 'package:appwrite/appwrite.dart';

class NavigationScreen extends StatefulWidget {
  final Client client;
  final String userID;
  final Document userDocumet;

  const NavigationScreen({
    super.key,
    required this.client,
    required this.userID,
    required this.userDocumet,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize screens with required parameters
    _screens = [
      Overview(client: widget.client, userID: widget.userID),
      ChatOverviewScreen(client: client, currentUserID: widget.userID),
      SettingsScreen(currentUserDocument: widget.userDocumet),
      Zeiterfassung(client: client, currentUserDocument: widget.userDocumet),
      Kalender(userID: widget.userID),
    ];
  }

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}
