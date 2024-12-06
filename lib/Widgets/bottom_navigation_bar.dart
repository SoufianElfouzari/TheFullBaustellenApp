import 'package:baustellenapp/Constants/colors.dart';
import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = [
      Icons.home_outlined,
      Icons.chat_outlined,
      Icons.settings,
      Icons.manage_accounts_outlined,
      Icons.calendar_month,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 25.0),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.secondColor, // Use defined second color
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            return GestureDetector(
              onTap: () => onItemSelected(index),
              child: Icon(
                icons[index],
                size: 35,
                color: currentIndex == index
                    ? AppColors.mainColor // Highlighted icon color
                    : AppColors.inactiveIconColor, // Default icon color
              ),
            );
          }),
        ),
      ),
    );
  }
}
