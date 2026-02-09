import 'package:flutter/material.dart';
import 'color.dart';

class AppGradients {
  static const LinearGradient blueGradient = LinearGradient(
    colors: [
      AppColors.darkBlue,
      AppColors.blue1,
      AppColors.blue2,
      AppColors.white,
    ],
    stops: [0.0, 0.33, 0.66, 1.0], // evenly spaced
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
