// ignore_for_file: non_constant_identifier_names

import 'dart:math';

import 'package:solunar_lib/src/astro_objects.dart';

class MathUtil {
  final double twoPI = pi * 2;
  final double RADEG = 180 / pi;
  final double DEGRAD = pi / 180;

  double sind(double x) {
    return sin((x) * DEGRAD);
  }

  double cosd(double x) {
    return cos((x) * DEGRAD);
  }

  double fpart(double x)
  //returns fractional part of a number
  {
    x = x - x.floor();
    if (x < 0) {
      x = x + 1;
    }
    return x;
  }

  double ipart(double x) {
    //returns the true integer part, even for negative numbers
    double a;
    if (x != 0) {
      a = x / x.abs() * x.abs().floor();
    } else {
      a = 0;
    }
    return a;
  }

  Quad quad(double ym, double y0, double yp) {
    /*
		finds a parabola through three points and returns values of coordinates of
		extreme value (xe, ye) and zeros if any (z1, z2) assumes that the x values are
		-1, 0, +1
		*/

    double a, b, c, dx, dis, XE, YE, Z1, Z2;
    int NZ;
    NZ = 0;
    XE = 0;
    YE = 0;
    Z1 = 0;
    Z2 = 0;
    a = .5 * (ym + yp) - y0;
    b = .5 * (yp - ym);
    c = y0;
    XE = (0.0 - b) / (a * 2.0); //              'x coord of symmetry line
    YE = (a * XE + b) * XE + c; //      'extreme value for y in interval
    dis = b * b - 4.0 * a * c; //    'discriminant
    //more nested if's
    if (dis > 0.000000) {
      //'there are zeros
      dx = (0.5 * sqrt(dis)) / (a.abs());
      Z1 = XE - dx;
      Z2 = XE + dx;
      if (Z1.abs() <= 1) {
        NZ = NZ + 1; // 'This zero is in interval
      }
      if (Z2.abs() <= 1) {
        NZ = NZ + 1; //'This zero is in interval
      }
      if (Z1 < -1) {
        Z1 = Z2;
      }
    }
    Quad returnQuad = Quad(XE, YE, Z1, Z2, NZ);

    return returnQuad;
  }

  List<double> myModf(double fullDouble) {
    int intVal = fullDouble.toInt();
    double remainder = fullDouble - intVal;
    return [intVal.toDouble(), remainder];
  }
}
