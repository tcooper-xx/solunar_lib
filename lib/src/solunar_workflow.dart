import 'package:solunar_lib/solunar_lib.dart';

class SolunarWorkflow {
  AstroWorkflow astroWorkflow = AstroWorkflow();

  Solunar getForDate(DateTime dayOf, double lat, double lon) {
    //Solunar s = Solunar();

    DateTime myDayOf = dayOf;
    double myLatitude = lat;
    double myLongitude = lon;

    double adjustedJulianDate = getAdjustedJulianDay(dayOf);

    RiseSetTransit mySolRST =
        AstroWorkflow().getRST(1, adjustedJulianDate, lon, lat);
    RiseSetTransit myMoonRST =
        AstroWorkflow().getRST(0, adjustedJulianDate, lon, lat);
    UnderFoot myMoonUnderFoot =
        (AstroWorkflow().getUnderfoot(adjustedJulianDate, lon));
    MoonPhase myMoonPhase = (AstroWorkflow().getMoonPhase(adjustedJulianDate));

    int moonPhaseScale = getMoonPhaseScale(myMoonPhase.illumination);
    int dayScale = getDayScale(
        myMoonRST.riseTime,
        myMoonRST.setTime,
        myMoonRST.transitTime,
        myMoonUnderFoot.underfootTime,
        mySolRST.riseTime,
        mySolRST.setTime);

    int myDayScale = moonPhaseScale + dayScale;

    Solunar s = Solunar(myDayOf, myLongitude, myLatitude, mySolRST, myMoonRST,
        myMoonUnderFoot, myMoonPhase, myDayScale);

    if (s.moonRST.riseTime >= 1 && s.moonRST.riseTime <= 23) {
      s.minors.add(getMinor(s.moonRST.riseTime));
    }
    if (s.moonRST.setTime >= 1 && s.moonRST.setTime <= 23) {
      s.minors.add(getMinor(s.moonRST.setTime));
    }
    if (s.moonRST.transitTime >= 1.5 && s.moonRST.transitTime <= 22.5) {
      s.majors.add(getMajor(s.moonRST.transitTime));
    }
    if (s.moonUnderFoot.underfootTime >= 1.5 &&
        s.moonUnderFoot.underfootTime <= 22.5) {
      s.majors.add(getMajor(s.moonUnderFoot.underfootTime));
    }
    return s;
  }

  int getJulianDay(DateTime date) {
    final julianEpoch = DateTime.utc(-4713, 11, 24, 12, 0, 0);

    return date.difference(julianEpoch).inDays;
  }

  double getAdjustedJulianDay(DateTime date) {
    int tzoffset = date.timeZoneOffset.inHours;
    double zone = tzoffset / 24;
    int jd = getJulianDay(date);

    return jd - 2400000 - zone;
  }

  EventPeriod getMinor(double moonRiseOrSet) {
    StringUtil stringUtil = StringUtil();

    double minorstart, minorstop;
    minorstart = moonRiseOrSet - 1.0;
    minorstop = moonRiseOrSet + 1.0;
    return EventPeriod(
        EventPeriod.TYPE_MINOR,
        stringUtil.convertTimeToString(minorstart),
        stringUtil.convertTimeToString(minorstop));
  }

  EventPeriod getMajor(double moontransit) {
    StringUtil stringUtil = StringUtil();

    double majorstart, majorstop;
    majorstart = moontransit - 1.5;
    majorstop = moontransit + 1.5;
    return EventPeriod(
        EventPeriod.TYPE_MAJOR,
        stringUtil.convertTimeToString(majorstart),
        stringUtil.convertTimeToString(majorstop));
  }

  int getMoonPhaseScale(double moonphase) {
    int scale = 0;
    if (moonphase.abs() < 0.9) {
      //new
      scale = 3;
    } else if (moonphase.abs() < 6.0) {
      scale = 2;
    } else if (moonphase.abs() < 9.9) {
      scale = 1;
    } else if (moonphase.abs() > 99) {
      //full
      scale = 3;
    } else if (moonphase.abs() > 94) {
      scale = 2;
    } else if (moonphase.abs() > 90.1) {
      scale = 1;
    } else {
      scale = 0;
    }

    return scale;
  }

  int getDayScale(double moonrise, double moonset, double moontransit,
      double moonunder, double sunrise, double sunset) {
    int locsoldayscale = 0;
    //check minor1 and sunrise
    if ((sunrise >= (moonrise - 1.0)) && (sunrise <= (moonrise + 1.0))) {
      locsoldayscale++;
    }
    //check minor1 and sunset
    if ((sunset >= (moonrise - 1.0)) && (sunset <= (moonrise + 1.0))) {
      locsoldayscale++;
    }
    //check minor2 and sunrise
    if ((sunrise >= (moonset - 1.0)) && (sunrise <= (moonset + 1.0))) {
      locsoldayscale++;
    }
    //check minor2 and sunset
    if ((sunset >= (moonset - 1.0)) && (sunset <= (moonset + 1.0))) {
      locsoldayscale++;
    }
    //check major1 and sunrise
    if ((sunrise >= (moontransit - 2.0)) && (sunrise <= (moontransit + 2.0))) {
      locsoldayscale++;
    }
    //check major1 and sunset
    if ((sunset >= (moontransit - 2.0)) && (sunset <= (moontransit + 2.0))) {
      locsoldayscale++;
    }
    //check major2 and sunrise
    if ((sunrise >= (moonunder - 2.0)) && (sunrise <= (moonunder + 2.0))) {
      locsoldayscale++;
    }
    //check major2 and sunset
    if ((sunset >= (moonunder - 2.0)) && (sunset <= (moonunder + 2.0))) {
      locsoldayscale++;
    }

    //catch a >2 scale, tho this shouldn't happen.
    if (locsoldayscale > 2) {
      locsoldayscale = 2;
    }

    return locsoldayscale;
  }
}
