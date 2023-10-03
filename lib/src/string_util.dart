import 'package:solunar_lib/solunar_lib.dart';

class StringUtil {
  String convertTimeToString(double doubletime) {
    double i, d;
    MathUtil mathUtil = MathUtil();
    /*split the time into hours (i) and minutes (d)*/
    List<double> modfResults = mathUtil.myModf(doubletime);
    i = modfResults[0];
    d = modfResults[1];
    d = d * 60;
    if (d >= 59.5) {
      i = i + 1;
      d = 0.0;
    }
    /*convert times to a string*/
    if (d.toInt() < 9.5) {
      return "${i.toInt()}:0${d.toInt()}";
    } else {
      return "${i.toInt()}:${d.toInt()}";
    }
  }
}
