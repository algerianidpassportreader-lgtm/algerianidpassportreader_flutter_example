import 'package:flutter/widgets.dart';

class ScreenHelper {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double screenWidthPercentage(BuildContext context, double percentage) {
    return screenWidth(context) * percentage;
  }

  static double screenHeightPercentage(
    BuildContext context,
    double percentage,
  ) {
    return screenHeight(context) * percentage;
  }
}
