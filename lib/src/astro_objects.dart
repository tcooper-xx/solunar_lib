// ignore_for_file: non_constant_identifier_names
import 'package:solunar_lib/solunar_lib.dart';

StringUtil stringUtil = StringUtil();

class RiseSetTransit {
  int body = 0;
  double riseTime = 0;
  double setTime = 0;
  double transitTime = 0;
  int noState = 0;

  RiseSetTransit(
      this.body, this.riseTime, this.setTime, this.transitTime, this.noState);
  Map toJson() => {
        'body': body,
        'rise:': stringUtil.convertTimeToString(riseTime),
        'set': stringUtil.convertTimeToString(setTime),
        'transit': stringUtil.convertTimeToString(transitTime),
        'noState': noState
      };
}

class Quad {
  double xe;
  double ye;
  double z1;
  double z2;
  int nz;

  Quad(this.xe, this.ye, this.z1, this.z2, this.nz);
}

class BodyPos {
  double ra;
  double dec;

  BodyPos(this.ra, this.dec);
}

class MoonPhase {
  final String PHASE_NEW = "New";
  final String PHASE_FULL = "Full";
  final String PHASE_1STQUARTER = "First Quarter";
  final String PHASE_LASTQUARTER = "Last Quarter";
  final String PHASE_WAXING_CRESCENT = "Waxing Crescent";
  final String PHASE_WANING_CRESCENT = "Waning Crescent";
  final String PHASE_WAXING_GIBBOUS = "Waxing Gibbous";
  final String PHASE_WANING_GIBBOUS = "Waning Gibbous";
  final String PHASE_UNKNOWN = "Moon Phase Unknown";

  String phaseName = "PHASE_UNKNOWN";
  double phaseTime = 0; //Need Convert Time to String
  double illumination = 0;
  double age = 0;

  MoonPhase();

  Map toJson() => {
        'phaseName': phaseName,
        'phaseTime': phaseTime,
        'illumination': illumination,
        'age': age,
      };
}

class EventPeriod {
  static String TYPE_MAJOR = "Major";
  static String TYPE_MINOR = "Minor";

  String type;
  String start;
  String stop;

  EventPeriod(this.type, this.start, this.stop);
  Map toJson() => {
        'type': type,
        'start': start,
        'stop': stop,
      };
}

class UnderFoot {
  bool isUnderFoot;
  double underfootTime;

  UnderFoot(this.isUnderFoot, this.underfootTime);

  Map toJson() => {
        'isUnderFoot': isUnderFoot,
        'underfootTime': stringUtil.convertTimeToString(underfootTime),
      };
}

class Solunar implements Comparable<Solunar> {
  DateTime dayOf;
  double longitude;
  double latitude;
  RiseSetTransit solRST;
  RiseSetTransit moonRST;
  UnderFoot moonUnderFoot;
  MoonPhase moonPhase;
  List<EventPeriod> minors = List<EventPeriod>.empty(growable: true);
  List<EventPeriod> majors = List<EventPeriod>.empty(growable: true);
  int dayScale = 0;
  Solunar(this.dayOf, this.longitude, this.latitude, this.solRST, this.moonRST,
      this.moonUnderFoot, this.moonPhase, this.dayScale);

  @override
  int compareTo(Solunar other) {
    return dayOf.compareTo(other.dayOf);
  }

  Map toJson() => {
        'dayOf': dayOf.toLocal().toString(),
        'longitude': longitude,
        'latitude': latitude,
        'solRST': solRST,
        'moonRST': moonRST,
        'moonUnderFoot': moonUnderFoot,
        'moonPhase': moonPhase,
        'minors': minors,
        'majors': majors,
        'dayScale': dayScale
      };
}
