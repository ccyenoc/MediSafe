import 'package:flutter/material.dart';
import 'package:medisafe/screens/home_page.dart';
import 'package:medisafe/screens/near_me.dart';
import '../colors/color.dart';

class MedicalBottomNav extends StatelessWidget {
  const MedicalBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.trueNavy10,
      height: 80, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: _navLabel("Home Page"),
          ),
          _navLabel("Schedule"),
          
          Container(
            width: 65, 
            height: 65, 
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.royalBlue, width: 2), 
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner, 
              color: AppColors.royalBlue,
              size: 30,
            ),
          ),

          _navLabel("Chatbot"),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NearMePage()),
              );
            },
            child: _navLabel("Near Me"),
          ),
        ],
      ),
    );
  }

  Widget _navLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    );
  }
}