import 'package:flutter/material.dart';

class WeekdayDateCard extends StatelessWidget {
  final String weekday;
  final String date;
  final Color backgroundColor;
  final Color textColor;
  final bool isSelected;

  const WeekdayDateCard({
    super.key,
    required this.weekday,
    required this.date,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
