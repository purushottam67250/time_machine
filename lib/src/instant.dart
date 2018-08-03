// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class IInstant {
  // NodaTime enforces a range of -9998-01-01 and 9999-12-31 ... Is this related to CalendarCalculators?
  // These correspond to -9998-01-01 and 9999-12-31 respectively.
  static const int minDays = -4371222;
  static const int maxDays = 2932896; // 104249991

  static Instant trusted(Time time) => new Instant._trusted(time);
  static Instant untrusted(Time time) => new Instant.epochTime(time);

  /// Instant which is invalid *except* for comparison purposes; it is earlier than any valid value.
  /// This must never be exposed.
  static final Instant beforeMinValue = new Instant._trusted(new Time(days: ITime.minDays)); //, deliberatelyInvalid: true);
  /// Instant which is invalid *except* for comparison purposes; it is later than any valid value.
  /// This must never be exposed.
  static final Instant afterMaxValue = new Instant._trusted(new Time(days: ITime.maxDays)); //, deliberatelyInvalid: true);

  // note: Extensions would be `better than sliced bread` here!!!!
  static LocalInstant plusOffset(Instant instant, Offset offset) => instant._plusOffset(offset);
  static LocalInstant safePlus(Instant instant, Offset offset) => instant._safePlus(offset);
}

/// Represents an instant on the global timeline, with nanosecond resolution.
///
/// An [Instant] has no concept of a particular time zone or calendar: it simply represents a point in
/// time that can be globally agreed-upon.
///
/// This type is immutable.
@immutable
class Instant implements Comparable<Instant> {
  /// Represents the smallest possible [Instant].
  /// This value is equivalent to -9998-01-01T00:00:00Z
  static final Instant minValue = new Instant._trusted(new Time(days: IInstant.minDays));
  /// Represents the largest possible [Instant].
  /// This value is equivalent to 9999-12-31T23:59:59.999999999Z
  static final Instant maxValue = new Instant._trusted(new Time(days: IInstant.maxDays, nanoseconds: TimeConstants.nanosecondsPerDay - 1));

  static const Instant unixEpoch = const Instant._trusted(Time.zero);

  final Time timeSinceEpoch;

  // todo: investigate if this is okay ... see Instant.cs#115
  factory Instant.epochTime(Time time) {
    if (time < minValue.timeSinceEpoch) return IInstant.beforeMinValue;
    if (time > maxValue.timeSinceEpoch) return IInstant.afterMaxValue;
    return new Instant._trusted(time);
  }

  /// [Clock.getCurrentInstant] for [Clock.current].
  factory Instant.now() {
    return Clock.current.getCurrentInstant();
  }

  const Instant._trusted(this.timeSinceEpoch);

  // todo: this is dumb. ... this was really just for FromUnixTimeSeconds, etc... and got out of control
  /// Time since the [unixEpoch]
//  factory Instant({int seconds = 0, int milliseconds = 0, int microseconds = 0, /*int nanoseconds = 0*/}) =>
//      Instant.epochTime(
//          Time(/*days: days, hours:hours, minutes: minutes, */seconds: seconds,
//              milliseconds: milliseconds, microseconds: microseconds, /*nanoseconds: nanoseconds*/));

  // todo: something else?
  factory Instant() => Instant.fromEpochSeconds(0);

  factory Instant.fromEpochSeconds(int seconds) => Instant.epochTime(ITime.trusted(seconds * TimeConstants.millisecondsPerSecond));
  factory Instant.fromEpochMilliseconds(int milliseconds) => Instant.epochTime(ITime.trusted(milliseconds));
  factory Instant.fromEpochMicroseconds(int microseconds) {
    var milliseconds = 0;

    // todo: this is copied from Time constructor, can probably combine code paths
    // note: this is here to deal with extreme values
    if (microseconds.abs() > Platform.maxMicrosecondsToNanoseconds) {
      milliseconds = microseconds ~/ TimeConstants.microsecondsPerMillisecond;
      microseconds -= milliseconds * TimeConstants.microsecondsPerMillisecond;
    }

    var nanoseconds = microseconds * TimeConstants.nanosecondsPerMicrosecond;
    return Instant.epochTime(ITime.untrusted(milliseconds, nanoseconds));
  }
  factory Instant.fromEpochNanoseconds(int nanoseconds) => Instant.epochTime(ITime.trusted(0, nanoseconds));
  factory Instant.fromEpochBigIntNanoseconds(BigInt nanoseconds) => Instant.epochTime(Time.bigIntNanoseconds(nanoseconds));

  // Convenience methods from NodaTime -- evaluate if I want to keep these, todo: convert to be like LocalDateTime?
  factory Instant.utc(int year, int monthOfYear, int dayOfMonth, int hourOfDay, int minuteOfHour, [int secondOfMinute = 0]) {
    var days = ILocalDate.daysSinceEpoch(new LocalDate(year, monthOfYear, dayOfMonth));
    var nanoOfDay = new LocalTime(hourOfDay, minuteOfHour, secondOfMinute).nanosecondOfDay;
    return new Instant._trusted(new Time(days: days, nanoseconds:  nanoOfDay));
  }

  factory Instant.julianDate(double julianDate) => TimeConstants.julianEpoch + new Time(days: julianDate);

  factory Instant.dateTime(DateTime dateTime) {
    if (Platform.isVM) return new Instant._trusted(new Time(microseconds: dateTime.microsecondsSinceEpoch));
    return new Instant._trusted(new Time(milliseconds: dateTime.millisecondsSinceEpoch));
  }


  int compareTo(Instant other) => timeSinceEpoch.compareTo(other.timeSinceEpoch);
  @wasInternal bool get isValid => this >= minValue && this <= maxValue;

  @override int get hashCode => timeSinceEpoch.hashCode;
  @override bool operator==(dynamic other) => other is Instant && timeSinceEpoch == other.timeSinceEpoch;

  Instant operator+(Time time) => this.add(time);
  Instant operator-(Time time) => this.subtract(time);
  Instant add(Time time) => new Instant.epochTime(timeSinceEpoch + time);
  Instant subtract(Time time) => new Instant.epochTime(timeSinceEpoch - time);

  LocalInstant _plusOffset(Offset offset) {
    return new LocalInstant(timeSinceEpoch + offset.toTime());
  }

  LocalInstant _safePlus(Offset offset) {
    var days = epochDay;
    // plusOffset(offset);
    // If we can do the arithmetic safely, do so.
    if (days > IInstant.minDays && days < IInstant.maxDays)
    {
      return _plusOffset(offset);
    }
    // Handle BeforeMinValue and BeforeMaxValue simply.
    if (days < IInstant.minDays)
    {
      return LocalInstant.beforeMinValue;
    }
    if (days > IInstant.maxDays)
    {
      return LocalInstant.afterMaxValue;
    }
    // Okay, do the arithmetic as a Duration, then check the result for overflow, effectively.
    // var asDuration = ITime.plusSmallNanoseconds(timeSinceEpoch, offset.nanoseconds);
    // todo: much simplify
    var asDuration = Instant._trusted(ITime.plusSmallNanoseconds(timeSinceEpoch, offset.nanoseconds));
    days = asDuration.epochDay;
    if (days < IInstant.minDays)
    {
      return LocalInstant.beforeMinValue;
    }
    if (days > IInstant.maxDays)
    {
      return LocalInstant.afterMaxValue;
    }
    return new LocalInstant(asDuration.timeSinceEpoch);
  }

  /*
  // Span operator-(Instant instant) => _span - instant._span;
  // todo: is there any clever way to add type annotations to this?
  dynamic operator-(dynamic other) =>
      other is Instant ? timeUntil(other) :
      other is Time ? minus(other) :
      throw new ArgumentError('Expected Time or Instant.');*/

  // todo: this name is really bad
  // todo: think about this name ... it's not good
  // Instant minusSpan(Span span) => new Instant._trusted(_span - span);

  /// Calculates the time until [this] would become [instant].
  /// [this] + [Time] = [instant] or `start + Time = end`
  Time timeUntil(Instant instant) => instant.timeSinceEpoch.subtract(timeSinceEpoch);

  /// The fluent opposite of [timeUntil]
  Time timeSince(Instant instant) => timeSinceEpoch.subtract(instant.timeSinceEpoch);

  bool operator<(Instant other) => timeSinceEpoch < other.timeSinceEpoch;
  bool operator<=(Instant other) => timeSinceEpoch <= other.timeSinceEpoch;
  bool operator>(Instant other) => timeSinceEpoch > other.timeSinceEpoch;
  bool operator>=(Instant other) => timeSinceEpoch >= other.timeSinceEpoch;

  bool isAfter(Instant other) => timeSinceEpoch > other.timeSinceEpoch;
  bool isBefore(Instant other) => timeSinceEpoch < other.timeSinceEpoch;

  static Instant max(Instant x, Instant y) => x > y ? x : y;
  static Instant min(Instant x, Instant y) => x < y ? x : y;
  static Instant plus(Instant x, Time y) => x.add(y);
  static Instant minus(Instant x, Time y) => x.subtract(y);
  static Time difference(Instant start, Instant end) => start.timeSince(end);

  // @override toString() => TextShim.toStringInstant(this); // '${_span.totalSeconds} seconds since epoch.';
  @override String toString([String patternText, Culture culture]) =>
      InstantPatterns.format(this, patternText, culture);

  // On Dart2: this is still required, but I can't reproduce a minimal test case -- I am lost.
  @ddcSupportHack String toStringDDC([String patternText, Culture culture]) =>
      InstantPatterns.format(this, patternText, culture);

  double toJulianDate() => (TimeConstants.julianEpoch.timeUntil(this)).totalDays;

  DateTime toDateTimeUtc() {
    if (Platform.isVM) return new DateTime.fromMicrosecondsSinceEpoch(timeSinceEpoch.totalMicroseconds.toInt(), isUtc: true);
    return new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch.totalMilliseconds.toInt(), isUtc: true);
  }

  // DateTime toDateTimeLocal() => inLocalZone().toDateTimeLocal();
  // todo: verify this is equivalent to above? ... detect platform and do microseconds where appropriate
  DateTime toDateTimeLocal() => new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch.totalMilliseconds.toInt());

  // int get daysSinceEpoch => timeSinceEpoch.inDays; //days;
  // int get nanosecondOfDay => epochDayTime.inNanoseconds; // timeSinceEpoch.nanosecondOfFloorDay; //nanosecondOfDay;

  int get epochSeconds => timeSinceEpoch.totalSeconds.floor(); // epochDay*TimeConstants.secondsPerDay + timeOfEpochDay.inSeconds;
  int get epochMilliseconds => timeSinceEpoch.totalMilliseconds.floor(); // epochDay*TimeConstants.millisecondsPerDay + timeOfEpochDay.inMilliseconds;
  int get epochMicroseconds => timeSinceEpoch.totalMicroseconds.floor();
  int get epochNanoseconds => timeSinceEpoch.inNanoseconds;
  bool get canEpochNanosecondsBeInteger => timeSinceEpoch.canNanosecondsBeInteger;
  BigInt epochNanosecondsAsBigInt() => timeSinceEpoch.inNanosecondsAsBigInt;

  // epochDay
  // epochTimeOfDay
  // timeSinceEpoch

  // epochDay
  // epochTimeOfDay
  // epochTime <-- technically correct, but, I can see a lot of problems with this

  // daysSinceEpoch <-- I really like this (I also like epochDay)
  // timeOfEpochDay <-- but, I don't like this, so, it pushes me back to the first set;
  // timeSinceEpoch

  // epochDay
  // timeOfEpochDay
  // timeSinceEpoch

  // epochDay
  // epochDayTime
  // timeSinceEpoch <-- this is the format used by core:Duration

  // epochDay
  // epochDayTime
  // epochTime

  // timeSinceEpoch <-- this is the format used by core:Duration
  // daysSinceEpoch <-- but these aren't really the same thing daysSinceEpoch != timeSinceEpoch.inDays()
  //    <--- I think cognitively, this breaks down in the negatives, since, `-1` ends at 1 moment before the epoch.
  // secondsSinceEpoch
  // millisecondsSinceEpoch
  // microsecondsSinceEpoch
  // timeOfDaySinceEpoch ????????????

  // timeSinceEpoch <-- this is the format used by core:Duration
  // epochDay
  // epochDayTime or epochTimeOfDay or timeOfEpochDay or epochDayClockTime or epochDayTimeSinceMidnight
  // epochSeconds
  // epochMilliseconds
  // epochMicroseconds

  // todo: we do this a lot just to get Time.epochDay --> should we have a shortcut for this?
  int get epochDay {
    var ms = ITime.millisecondsOf(timeSinceEpoch);
    var ns = ITime.nanosecondsIntervalOf(timeSinceEpoch);

    // todo: determine if there are other corner-cases here
    if (ms == 0 && ns < 0) return -1;
    var days = ms ~/ TimeConstants.millisecondsPerDay;
    if (ms < 0 && ms % TimeConstants.millisecondsPerDay != 0) return days - 1;

    return days;
  }

  LocalTime get epochDayLocalTime => LocalTime.sinceMidnight(epochDayTime);

  Time get epochDayTime {
    // todo: much simplify
    // return timeSinceEpoch.subtract(Time(days: epochDay));
    var ms = ITime.millisecondsOf(timeSinceEpoch);
    var ns = ITime.nanosecondsIntervalOf(timeSinceEpoch);

    return ITime.untrusted(ms - epochDay * TimeConstants.millisecondsPerDay, ns);
  }

  // todo: should be toUtc iaw Dart Style Guide ~ leaving like it is in Nodatime for ease of porting
  //  ?? maybe the same for the 'WithOffset' ??? --< toOffsetDateTime
  ZonedDateTime inUtc() {
    // Bypass any determination of offset and arithmetic, as we know the offset is zero.
    var ymdc = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(epochDay);
    var offsetDateTime = IOffsetDateTime.fullTrust(ymdc, epochDayTime.inNanoseconds, Offset.zero);
    return IZonedDateTime.trusted(offsetDateTime, DateTimeZone.utc);
  }

  ZonedDateTime inZone(DateTimeZone zone, [CalendarSystem calendar]) =>
      // zone is checked for nullity by the constructor.
      // constructor also checks and corrects for calendar being null
    new ZonedDateTime(this, zone, calendar);

  // todo: get the correct calendar for the local timezone / culture
  /// Get the [ZonedDateTime] that corresponds to this [Instant] within in the zone [DateTimeZone.local].
  ZonedDateTime inLocalZone([CalendarSystem calendar]) => new ZonedDateTime(this, DateTimeZone.local, calendar);

  OffsetDateTime withOffset(Offset offset, [CalendarSystem calendar]) => IOffsetDateTime.fromInstant(this, offset, calendar);
}