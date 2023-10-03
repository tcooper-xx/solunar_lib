// ignore_for_file: non_constant_identifier_names

import 'package:solunar_lib/solunar_lib.dart';
import 'dart:math';

class AstroWorkflow {
  RiseSetTransit getRST(int object, double date, double ourlon, double ourlat) {
    MathUtil mathUtil = MathUtil();
    var sinho = [.002327, -0.014544];
    int hour = 1;
    double above = 0;
    double riseTime = 0;
    double setTime = 0;
    double transitTime = 0;
    double y0;
    double yp;
    int doesSet = 0;
    int doesRise = 0;
    int doesTransit = 0;
    int check = 0;

    int returnBody = 0;
    double returnRiseTime = 0;
    double returnSetTime = 0;
    double returnTransitTime = 0;
    int returnNoState = 0;

    double sl = mathUtil.sind(ourlat);
    double cl = mathUtil.cosd(ourlat);

    double ym = sinAlt(object, date, hour - 1, ourlon, cl, sl) - sinho[object];

    if (ym > 0) {
      above = 1;
    } else {
      above = 0;
    }
    do {
      y0 = sinAlt(object, date, hour, ourlon, cl, sl) - sinho[object];
      yp = sinAlt(object, date, hour + 1, ourlon, cl, sl) - sinho[object];

      Quad ourQuad = mathUtil.quad(ym, y0, yp);
      switch (ourQuad.nz) {
        case 0: //nothing  - go to next time slot
          break;
        case 1: //simple rise / set event
          if (ym < 0) {
            //must be a rising event
            riseTime = hour + ourQuad.z1;
            doesRise = 1;
          } else {
            //must be setting
            setTime = hour + ourQuad.z1;
            doesSet = 1;
          }
          break;
        case 2: //rises and sets within interval
          if (ourQuad.ye < 0) {
            //minimum - so set then rise
            riseTime = hour + ourQuad.z2;
            setTime = hour + ourQuad.z1;
          } else {
            //maximum - so rise then set
            riseTime = hour + ourQuad.z1;
            setTime = hour + ourQuad.z2;
          }
          doesRise = 1;
          doesSet = 1;
          break;
      }

      ym = yp; //reuse the ordinate in the next interval
      hour = hour + 2;
      check = (doesRise * doesSet);
    } while ((hour != 25) && (check != 1));
    // end rise-set loop

    //GET TRANSIT TIME
    hour = 0; //reset hour
    transitTime = getTransit(object, date, hour, ourlon);
    if (transitTime != 0.0) {
      doesTransit = 1;
    }
    if (object == 0) {
      //System.out.println("\nMOON");
      returnBody = 0;
    } else {
      //System.out.println("\n\nSUN");
      returnBody = 1;
    }
    //logic to sort the various rise, transit set states
    // nested if's...sorry
    if ((doesRise == 1) || (doesSet == 1) || (doesTransit == 1)) {
      //current object rises, sets or transits today
      if (doesRise == 1) {
        returnRiseTime = riseTime;
      } else {
        returnRiseTime = 0.0;
        //System.out.println ("\ndoes not rise");
      }
      if (doesTransit == 1) {
        returnTransitTime = transitTime;
      } else {
        returnTransitTime = 0.0;
        //System.out.println ("\ndoes not transit");
      }
      if (doesSet == 1) {
        returnSetTime = setTime;
      } else {
        returnSetTime = 0.0;
        //System.out.println ("\ndoes not set");
      }
    } else {
      //current object not so simple
      if (above == 1) {
        //System.out.println ("\nalways above horizon");
        returnNoState = 1;
      } else {
        //System.out.println ("\nalways below horizon");
        returnNoState = -1;
      }
    }
    //thats it were done.

    return RiseSetTransit(returnBody, returnRiseTime, returnSetTime,
        returnTransitTime, returnNoState);
  }

  double sinAlt(int object, double mjd0, int hour, double ourlong, double cphi,
      double sphi) {
    /*
      returns sine of the altitude of either the sun or the moon given the modified
      julian day number at midnight UT and the hour of the UT day, the longitude of
      the observer, and the sine and cosine of the latitude of the observer
      */
    MathUtil mathUtil = MathUtil();
    double locSinalt; //sine of the altitude, return value;
    double instant, t;
    double lha; //hour angle
    instant = mjd0 + hour / 24.0;
    t = (instant - 51544.5) / 36525;

    BodyPos position;
    if (object == 0) {
      position = getMoonPos(t);
    } else {
      position = getSunPos(t);
    }

    lha = 15.0 * (lmst(instant, ourlong) - position.ra); //hour angle of object
    locSinalt = sphi * mathUtil.sind(position.dec) +
        cphi * mathUtil.cosd(position.dec) * mathUtil.cosd(lha);
    return locSinalt;
  }

  BodyPos getMoonPos(double t) {
    /*
      returns ra and dec of Moon to 5 arc min (ra) and 1 arc min (dec) for a few
      centuries either side of J2000.0 Predicts rise and set times to within minutes
      for about 500 years in past - TDT and UT time diference may become significant
      for long times
      */
    MathUtil mathUtil = MathUtil();
    double ARC = 206264.8062;
    double COSEPS = 0.91748;
    double SINEPS = 0.39778;
    double L0, L, LS, d, F;
    L0 = mathUtil.fpart(.606433 + 1336.855225 * t); //'mean long Moon in revs
    L = mathUtil.twoPI *
        mathUtil.fpart(.374897 + 1325.55241 * t); //'mean anomaly of Moon
    LS = mathUtil.twoPI *
        mathUtil.fpart(.993133 + 99.997361 * t); //'mean anomaly of Sun
    d = mathUtil.twoPI *
        mathUtil
            .fpart(.827361 + 1236.853086 * t); //'diff longitude sun and moon
    F = mathUtil.twoPI *
        mathUtil.fpart(.259086 + 1342.227825 * t); //'mean arg latitude
    //' longitude correction terms
    double dL, h;
    dL = 22640 * sin(L) - 4586 * sin(L - 2 * d);
    dL = dL + 2370 * sin(2 * d) + 769 * sin(2 * L);
    dL = dL - 668 * sin(LS) - 412 * sin(2 * F);
    dL = dL - 212 * sin(2 * L - 2 * d) - 206 * sin(L + LS - 2 * d);
    dL = dL + 192 * sin(L + 2 * d) - 165 * sin(LS - 2 * d);
    dL = dL - 125 * sin(d) - 110 * sin(L + LS);
    dL = dL + 148 * sin(L - LS) - 55 * sin(2 * F - 2 * d);
    //' latitude arguments
    double S, N, lmoon, bmoon;
    S = F + (dL + 412 * sin(2 * F) + 541 * sin(LS)) / ARC;
    h = F - 2 * d;
    //' latitude correction terms
    N = -526 * sin(h) + 44 * sin(L + h) - 31 * sin(h - L) - 23 * sin(LS + h);
    N = N + 11 * sin(h - LS) - 25 * sin(F - 2 * L) + 21 * sin(F - L);
    lmoon = mathUtil.twoPI * mathUtil.fpart(L0 + dL / 1296000); //  'Lat in rads
    bmoon = (18520 * sin(S) + N) / ARC; //     'long in rads
    //' convert to equatorial coords using a fixed ecliptic
    double CB, x, V, W, y, Z, rho, DEC, RA;
    CB = cos(bmoon);
    x = CB * cos(lmoon);
    V = CB * sin(lmoon);
    W = sin(bmoon);
    y = COSEPS * V - SINEPS * W;
    Z = SINEPS * V + COSEPS * W;
    rho = sqrt(1.0 - Z * Z);
    DEC = (360.0 / mathUtil.twoPI) * atan2(Z, rho);
    RA = (48.0 / mathUtil.twoPI) * atan2(y, (x + rho));
    if (RA < 0) {
      RA = RA + 24.0;
    }

    return BodyPos(RA, DEC);
  }

  BodyPos getSunPos(double t) {
    /*
      Returns RA and DEC of Sun to roughly 1 arcmin for few hundred years either side
      of J2000.0
      */

    MathUtil mathUtil = MathUtil();
    double COSEPS = 0.91748;
    double SINEPS = 0.39778;
    double m, dL, L, rho, sl;
    double RA, DEC;
    double x, y, z;
    m = mathUtil.twoPI *
        mathUtil.fpart(0.993133 + 99.997361 * t); //Mean anomaly
    dL = 6893 * sin(m) + 72 * sin(2 * m); //Eq centre
    L = mathUtil.twoPI *
        mathUtil.fpart(
            0.7859453 + m / mathUtil.twoPI + (6191.2 * t + dL) / 1296000);
    sl = sin(L);
    x = cos(L);
    y = COSEPS * sl;
    z = SINEPS * sl;
    rho = sqrt(1 - z * z);
    DEC = (360 / mathUtil.twoPI) * atan2(z, rho);
    RA = (48 / mathUtil.twoPI) * atan2(y, (x + rho));
    if (RA < 0) {
      RA = RA + 24;
    }

    return BodyPos(RA, DEC);
  }

  double lmst(double mjd, double ourlong) {
    //returns the local siderial time for the modified julian date and longitude
    MathUtil mathUtil = MathUtil();
    double value;
    double mjd0;
    double ut;
    double t;
    double gmst;
    mjd0 = mathUtil.ipart(mjd);
    ut = (mjd - mjd0) * 24;
    t = (mjd0 - 51544.5) / 36525;
    gmst = 6.697374558 + 1.0027379093 * ut;
    gmst = gmst + (8640184.812866 + (.093104 - .0000062 * t) * t) * t / 3600;
    value = 24 * mathUtil.fpart((gmst + (ourlong / 15.0)) / 24.0);
    return (value);
  }

  double getTransit(int object, double mjd0, int hour, double ourlong) {
    //double ra = 0.0;
    double instant, t;
    double lha; //local hour angle
    double locTransit = 0; // transit time, return value.
    int min = 0;
    List<int> hourarray = List<int>.filled(255, 0);
    List<int> minarray = List<int>.filled(615, 0);
    double LA; //local angle
    int sLA; //sign of angle
    double mintime;

    //loop through all 24 hours of the day and store the sign of the angle in an array
    //actually loop through 25 hours if we reach the 25th hour with out a transit then no transit condition today.

    while (hour < 25.0) {
      instant = mjd0 + hour / 24.0;
      t = (instant - 51544.5) / 36525;
      BodyPos pos;
      if (object == 0) {
        pos = getMoonPos(t);
      } else {
        pos = getSunPos(t);
      }
      lha = (lmst(instant, ourlong) - pos.ra);
      LA = lha * 15.04107; //convert hour angle to degrees
      sLA = LA ~/ LA.abs(); //sign of angle
      hourarray[hour] = sLA;
      hour++;
    }
    //search array for the when the angle first goes from negative to positive
    int i = 0;
    while (i < 25) {
      locTransit = i.toDouble();
      if (hourarray[i] - hourarray[i + 1] == -2) {
        //we found our hour
        break;
      }

      i++;
    }
    //check for no transit, return zero
    if (locTransit > 23) {
      // no transit today
      locTransit = 0.0;
      return locTransit;
    }

    //loop through all 60 minutes of the hour and store sign of the angle in an array
    mintime = locTransit;
    while (min < 60) {
      instant = mjd0 + mintime / 24.0;
      t = (instant - 51544.5) / 36525;
      BodyPos pos;
      if (object == 0) {
        pos = getMoonPos(t);
      } else {
        pos = getSunPos(t);
      }
      lha = (lmst(instant, ourlong) - pos.ra);
      LA = lha * 15.04107;
      sLA = LA ~/ LA.abs();
      minarray[min] = sLA;
      min++;
      mintime = mintime + 0.016667; //increment 1 minute
    }

    i = 0;
    while (i < 60) {
      if (minarray[i] - minarray[i + 1] == -2) {
        //we found our min
        break;
      }
      i++;
      locTransit = locTransit + 0.016667;
    }
    return (locTransit);
  }

  UnderFoot getUnderfoot(double date, double underlong) {
    UnderFoot underFoot;
    double moonunderTime;
    moonunderTime = getTransit(0, date, 0, underlong);
    if (moonunderTime != 0.0) {
      underFoot = UnderFoot(true, moonunderTime);
    } else {
      underFoot = UnderFoot(false, 0);
    }

    return underFoot;
  }

  MoonPhase getMoonPhase(double date) {
    MoonPhase moonPhase = MoonPhase();

    int PriPhaseOccurs; //1 = yes, 0 = no
    int i = 0;
    double ourhour = 0;
    double hour = -1;
    double ls, lm, diff;
    double instant, t;
    double phase;
    List<double> hourarray = List<double>.filled(255, 0);
    List<double> minarray = List<double>.filled(255, 0);

    double illumin;
    double PriPhaseTime = 0;
    MathUtil mathUtil = MathUtil();

    /*some notes on structure of hourarray[]
        *  increment is 15mins
        * i =  0, hourarray[0] = hour -1, hour 23 of prev day.
        * i =  1, hourarry[1] = hour -0.75, hour 23.15 of prev day.
        * i = 4, hourarray[4] = hour 0 of today.
        * i = 52, hourarray[52] = hour 12 of today.
        * i = 99, hourarray[99] = hour 23.75 of today.
        * i = 100, hourarray[100] = hour 0 of nextday.
        * 
        * to convert i to todays hour = (i/4 -1)
        */

    //find and store illumination for every 1/4 hour in an array
    while (i < 104) {
      instant = date + hour / 24.0;
      t = (instant - 51544.5) / 36525;
      lm = getMoonLong(t);
      ls = getSunLong(t);
      diff = lm - ls;
      phase = (1.0 - mathUtil.cosd(lm - ls)) / 2;
      phase *= 100;
      if (diff < 0) {
        diff += 360;
      }
      if (diff > 180) {
        phase *= -1;
      }
      illumin = phase.abs();
      hourarray[i] = illumin;
      i++;
      hour += 0.25;
    }
    i = 0;
    while (i < 104) {
      ourhour = i.toDouble();
      ourhour = ((ourhour / 4) - 1);
      //check for a new moon
      if ((hourarray[i] < hourarray[i + 1]) && (hourarray[i] < 0.001)) {
        break;
      }
      //check for a full moon
      if ((hourarray[i] > hourarray[i + 1]) && (hourarray[i] > 99.9999)) {
        break;
      }
      //check for a first quarter
      if ((hourarray[i] < hourarray[i + 1]) &&
          (hourarray[i] > 50) &&
          (hourarray[i] < 50.5)) {
        break;
      }
      //check for a last quarter
      if ((hourarray[i] > hourarray[i + 1]) &&
          (hourarray[i] < 50) &&
          (hourarray[i] > 49.5)) {
        break;
      }

      i++;
    }
    if (ourhour < 0 || ourhour >= 24) {
      PriPhaseOccurs = 0;
    } else {
      PriPhaseOccurs = 1;
    }

    if (PriPhaseOccurs == 1) {
      //check every min start with the previous hour
      if (ourhour > 0) {
        hour = mathUtil.ipart(ourhour) - 1;
      } else {
        hour = mathUtil.ipart(ourhour);
      }

      PriPhaseTime = hour;
      i = 0;
      while (i < 120) {
        instant = date + hour / 24.0;
        t = (instant - 51544.5) / 36525;
        lm = getMoonLong(t);
        ls = getSunLong(t);
        diff = lm - ls;
        phase = (1.0 - mathUtil.cosd(lm - ls)) / 2;
        phase *= 100;
        if (diff < 0) {
          diff += 360;
        }
        if (diff > 180) {
          phase *= -1;
        }
        // we are getting age at the wrong time here, maybe for a primary phase
        // we should use a static age, like we do for illumin.
        //age = fabs(diff/13);
        illumin = phase.abs();
        minarray[i] = illumin;
        hour = hour + 0.016667;
        i++;
      }

      i = 0;
      while (i < 120) {
        //check for a new moon
        if ((minarray[i] < minarray[i + 1]) && (minarray[i] < 0.1)) {
          moonPhase.age = 0;
          moonPhase.illumination = 0;
          moonPhase.phaseName = moonPhase.PHASE_NEW;
          break;
        }
        //check for a full moon
        if ((minarray[i] > minarray[i + 1]) && (minarray[i] > 99)) {
          moonPhase.age = 14;
          moonPhase.illumination = 100;
          moonPhase.phaseName = moonPhase.PHASE_FULL;
          break;
        }
        //check for a first quarter
        if ((minarray[i] < minarray[i + 1]) &&
            (minarray[i] > 50) &&
            (minarray[i] < 51)) {
          moonPhase.age = 7;
          moonPhase.illumination = 50;
          moonPhase.phaseName = moonPhase.PHASE_1STQUARTER;
          break;
        }
        //check for a last quarter
        if ((minarray[i] > minarray[i + 1]) &&
            (minarray[i] < 50) &&
            (minarray[i] > 49)) {
          moonPhase.age = 21;
          moonPhase.illumination = 50;
          moonPhase.phaseName = moonPhase.PHASE_LASTQUARTER;
          break;
        }
        PriPhaseTime = PriPhaseTime + 0.016667;
        i++;
      }
    } else {
      //if we didn't find a primary phase, check the phase at noon.
      //	    date = (JD - 2400000.5);
      instant = date + .5; //check at noon
      t = (instant - 51544.5) / 36525;
      lm = getMoonLong(t);
      ls = getSunLong(t);
      diff = lm - ls;
      phase = (1.0 - mathUtil.cosd(lm - ls)) / 2;
      phase *= 100;
      if (diff < 0) {
        diff += 360;
      }
      if (diff > 180) {
        phase *= -1;
      }
      //age = fabs((lm - ls)/13);
      //age = Math.abs(diff/13);
      //illumin = Math.abs(phase);
      moonPhase.age = (diff / 13).abs();
      moonPhase.illumination = phase.abs();
      //Get phase type
      if (phase.abs() < 50 && phase < 0) {
        moonPhase.phaseName = moonPhase.PHASE_WANING_CRESCENT;
      } else if (phase.abs() < 50 && phase > 0) {
        moonPhase.phaseName = moonPhase.PHASE_WAXING_CRESCENT;
      } else if (phase.abs() < 100 && phase < 0) {
        moonPhase.phaseName = moonPhase.PHASE_WANING_GIBBOUS;
      } else if (phase.abs() < 100 && phase > 0) {
        moonPhase.phaseName = moonPhase.PHASE_WAXING_GIBBOUS;
      } else {
        moonPhase.phaseName = moonPhase.PHASE_UNKNOWN;
      }
    }
    if (PriPhaseOccurs == 1) {
      moonPhase.phaseTime = PriPhaseTime;
    }

    return moonPhase;
  }

  double getMoonLong(double t) {
    double ARC = 206264.8062;

    double L0, L, LS, d, F;
    double moonlong;

    MathUtil mathUtil = MathUtil();
    L0 = mathUtil.fpart(.606433 + 1336.855225 * t); //'mean long Moon in revs
    L = mathUtil.twoPI *
        mathUtil.fpart(.374897 + 1325.55241 * t); //'mean anomaly of Moon
    LS = mathUtil.twoPI *
        mathUtil.fpart(.993133 + 99.997361 * t); //'mean anomaly of Sun
    d = mathUtil.twoPI *
        mathUtil
            .fpart(.827361 + 1236.853086 * t); //'diff longitude sun and moon
    F = mathUtil.twoPI *
        mathUtil.fpart(.259086 + 1342.227825 * t); //'mean arg latitude
    //' longitude correction terms
    double dL, h;
    dL = 22640 * sin(L) - 4586 * sin(L - 2 * d);
    dL = dL + 2370 * sin(2 * d) + 769 * sin(2 * L);
    dL = dL - 668 * sin(LS) - 412 * sin(2 * F);
    dL = dL - 212 * sin(2 * L - 2 * d) - 206 * sin(L + LS - 2 * d);
    dL = dL + 192 * sin(L + 2 * d) - 165 * sin(LS - 2 * d);
    dL = dL - 125 * sin(d) - 110 * sin(L + LS);
    dL = dL + 148 * sin(L - LS) - 55 * sin(2 * F - 2 * d);
    //' latitude arguments
    double S, N, lmoon, bmoon;
    S = F + (dL + 412 * sin(2 * F) + 541 * sin(LS)) / ARC;
    h = F - 2 * d;
    //' latitude correction terms
    N = -526 * sin(h) + 44 * sin(L + h) - 31 * sin(h - L) - 23 * sin(LS + h);
    N = N + 11 * sin(h - LS) - 25 * sin(F - 2 * L) + 21 * sin(F - L);
    lmoon = mathUtil.twoPI * mathUtil.fpart(L0 + dL / 1296000); //  'Lat in rads
    bmoon = (18520 * sin(S) + N) / ARC; //     'long in rads
    moonlong = lmoon * mathUtil.RADEG;
    return moonlong;
  }

  double getSunLong(double t) {
    double m, dL, L;
    double sunlong;
    MathUtil mathUtil = MathUtil();

    m = mathUtil.twoPI *
        mathUtil.fpart(0.993133 + 99.997361 * t); //Mean anomaly
    dL = 6893 * sin(m) + 72 * sin(2 * m); //Eq centre
    L = mathUtil.twoPI *
        mathUtil.fpart(
            0.7859453 + m / mathUtil.twoPI + (6191.2 * t + dL) / 1296000);
    sunlong = L * mathUtil.RADEG;
    return sunlong;
  }
}
