// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'utility/preconditions.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_fields.dart';
import 'package:time_machine/time_machine_utilities.dart';

class LocalDate implements Comparable<LocalDate> {
  YearMonthDayCalendar _yearMonthDayCalendar;

  /// The maximum (latest) date representable in the ISO calendar system.
  static LocalDate get MaxIsoValue => new LocalDate.trusted(new YearMonthDayCalendar(GregorianYearMonthDayCalculator.maxGregorianYear, 12, 31, CalendarOrdinal.Iso));

  /// The minimum (earliest) date representable in the ISO calendar system.
  static LocalDate get MinIsoValue => new LocalDate.trusted(new YearMonthDayCalendar(GregorianYearMonthDayCalculator.minGregorianYear, 1, 1, CalendarOrdinal.Iso));

  /// Constructs an instance from values which are assumed to already have been validated.
  // todo: this one seems like it might be trouble (is this truly protected from being used as an external API?)
  @internal LocalDate.trusted(YearMonthDayCalendar yearMonthDayCalendar)
  {
    this._yearMonthDayCalendar = yearMonthDayCalendar;
  }

  /// Constructs an instance from the number of days since the unix epoch, in the ISO
  /// calendar system.
  @internal LocalDate.fromDaysSinceEpoch(int daysSinceEpoch)
  {
  Preconditions.debugCheckArgumentRange('daysSinceEpoch', daysSinceEpoch, CalendarSystem.Iso.minDays, CalendarSystem.Iso.maxDays);
  this._yearMonthDayCalendar = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(daysSinceEpoch);
  }

  /// Constructs an instance from the number of days since the unix epoch, and a calendar
  /// system. The calendar system is assumed to be non-null, but the days since the epoch are
  /// validated.
  @internal LocalDate.fromDaysSinceEpoch_forCalendar(int daysSinceEpoch, CalendarSystem calendar)
  {
  Preconditions.debugCheckNotNull(calendar, 'calendar');
  this._yearMonthDayCalendar = calendar.GetYearMonthDayCalendarFromDaysSinceEpoch(daysSinceEpoch);
  }

  /// Constructs an instance for the given year, month and day in the ISO calendar.
  ///
  /// [year]: The year. This is the "absolute year", so a value of 0 means 1 BC, for example.
  /// [month]: The month of year.
  /// [day]: The day of month.
  /// Returns: The resulting date.
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid date.
  LocalDate(int year, int month, int day)
  {
    GregorianYearMonthDayCalculator.validateGregorianYearMonthDay(year, month, day);
    _yearMonthDayCalendar = new YearMonthDayCalendar(year, month, day, CalendarOrdinal.Iso);
  }

  /// Constructs an instance for the given year, month and day in the specified calendar.
  ///
  /// [year]: The year. This is the "absolute year", so, for
  /// the ISO calendar, a value of 0 means 1 BC, for example.
  /// [month]: The month of year.
  /// [day]: The day of month.
  /// [calendar]: Calendar system in which to create the date.
  /// Returns: The resulting date.
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid date.
  LocalDate.forCalendar(int year, int month, int day, CalendarSystem calendar)
  {
  Preconditions.checkNotNull(calendar, 'calendar');
  calendar.ValidateYearMonthDay(year, month, day);
  _yearMonthDayCalendar = new YearMonthDayCalendar(year, month, day, calendar.ordinal);
  }

  /// Constructs an instance for the given era, year of era, month and day in the ISO calendar.
  ///
  /// [era]: The era within which to create a date. Must be a valid era within the ISO calendar.
  /// [yearOfEra]: The year of era.
  /// [month]: The month of year.
  /// [day]: The day of month.
  /// Returns: The resulting date.
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid date.
  LocalDate.forIsoEra(Era era, int yearOfEra, int month, int day)
      : this.forEra(era, yearOfEra, month, day, CalendarSystem.Iso);

  /// Constructs an instance for the given era, year of era, month and day in the specified calendar.
  ///
  /// [era]: The era within which to create a date. Must be a valid era within the specified calendar.
  /// [yearOfEra]: The year of era.
  /// [month]: The month of year.
  /// [day]: The day of month.
  /// [calendar]: Calendar system in which to create the date.
  /// Returns: The resulting date.
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid date.
  LocalDate.forEra(Era era, int yearOfEra, int month, int day, CalendarSystem calendar)
      : this.forCalendar(Preconditions.checkNotNull(calendar, 'calendar').GetAbsoluteYear(yearOfEra, era), month, day, calendar);

  /// Gets the calendar system associated with this local date.
  CalendarSystem get Calendar => CalendarSystem.ForOrdinal(_yearMonthDayCalendar.calendarOrdinal);

  /// Gets the year of this local date.
  /// This returns the "absolute year", so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get Year => _yearMonthDayCalendar.year;

  /// Gets the month of this local date within the year.
  int get Month => _yearMonthDayCalendar.month;

  /// Gets the day of this local date within the month.
  int get Day => _yearMonthDayCalendar.day;

  /// Gets the number of days since the Unix epoch for this date.
  @internal int get DaysSinceEpoch => Calendar.GetDaysSinceEpoch(_yearMonthDayCalendar.toYearMonthDay());

  /// Gets the week day of this local date expressed as an [IsoDayOfWeek] value.
  IsoDayOfWeek get DayOfWeek => Calendar.GetDayOfWeek(_yearMonthDayCalendar.toYearMonthDay());

  /// Gets the year of this local date within the era.
  int get YearOfEra => Calendar.GetYearOfEra(_yearMonthDayCalendar.year);

  /// Gets the era of this local date.
  Era get era => Calendar.GetEra(_yearMonthDayCalendar.year);

  /// Gets the day of this local date within the year.
  int get DayOfYear => Calendar.GetDayOfYear(_yearMonthDayCalendar.toYearMonthDay());

  @internal YearMonthDay get yearMonthDay => _yearMonthDayCalendar.toYearMonthDay();

  @internal YearMonthDayCalendar get yearMonthDayCalendar => _yearMonthDayCalendar;

  /// Gets a [LocalDateTime] at midnight on the date represented by this local date.
  ///
  /// The [LocalDateTime] representing midnight on this local date, in the same calendar
  /// system.
  // todo: this should probably be a method? Check style guide.
  LocalDateTime get AtMidnight => new LocalDateTime(this, LocalTime.Midnight);

  /// Constructs a [DateTime] from this value which has a [DateTime.Kind]
  /// of [DateTimeKind.Unspecified]. The result is midnight on the day represented
  /// by this value.
  ///
  /// [DateTimeKind.Unspecified] is slightly odd - it can be treated as UTC if you use [DateTime.ToLocalTime]
  /// or as system local time if you use [DateTime.ToUniversalTime], but it's the only kind which allows
  /// you to construct a [DateTimeOffset] with an arbitrary offset, which makes it as close to
  /// the Noda Time non-system-specific "local" concept as exists in .NET.
  ///
  /// Returns: A [DateTime] value for the same date and time as this value.
  DateTime toDateTimeUnspecified() =>
      new DateTime(Year, Month, Day);
// new DateTime.fromMicrosecondsSinceEpoch(DaysSinceEpoch * TimeConstants.microsecondsPerDay);
// + TimeConstants.BclTicksAtUnixEpoch ~/ TimeConstants.ticksPerMicrosecond); //, DateTimeKind.Unspecified);

  // Helper method used by both FromDateTime overloads.
  // todo: private
  static int NonNegativeMicrosecondsToDays(int microseconds) => microseconds ~/ TimeConstants.microsecondsPerDay;
// ((ticks >> 14) ~/ 52734375);

  /// Converts a [DateTime] of any kind to a LocalDate in the ISO calendar, ignoring the time of day.
  /// This does not perform any time zone conversions, so a DateTime with a [DateTime.Kind] of
  /// [DateTimeKind.Utc] will still represent the same year/month/day - it won't be converted into the local system time.
  ///
  /// [dateTime]: Value to convert into a Noda Time local date
  /// Returns: A new [LocalDate] with the same values as the specified `DateTime`.
  static LocalDate FromDateTime(DateTime dateTime)
  {
    // todo: we might want to make this so it's microseconds on VM and milliseconds on JS -- but I don't know how .. yet
    int days = NonNegativeMicrosecondsToDays(dateTime.microsecondsSinceEpoch);
    return new LocalDate.fromDaysSinceEpoch(days);
  }

  /// Converts a [DateTime] of any kind to a LocalDate in the specified calendar, ignoring the time of day.
  /// This does not perform any time zone conversions, so a DateTime with a [DateTime.Kind] of
  /// [DateTimeKind.Utc] will still represent the same year/month/day - it won't be converted into the local system time.
  ///
  /// [dateTime]: Value to convert into a Noda Time local date
  /// [calendar]: The calendar system to convert into
  /// Returns: A new [LocalDate] with the same values as the specified `DateTime`.
  static LocalDate FromDateTimeAndCalendar(DateTime dateTime, CalendarSystem calendar)
  {
  int days = NonNegativeMicrosecondsToDays(dateTime.microsecondsSinceEpoch); // - TimeConstants.BclDaysAtUnixEpoch;
  return new LocalDate.fromDaysSinceEpoch_forCalendar(days, calendar);
  }

  /// Returns the local date corresponding to the given "week year", "week of week year", and "day of week"
  /// in the ISO calendar system, using the ISO week-year rules.
  ///
  /// [weekYear]: ISO-8601 week year of value to return
  /// [weekOfWeekYear]: ISO-8601 week of week year of value to return
  /// [dayOfWeek]: ISO-8601 day of week to return
  /// Returns: The date corresponding to the given week year / week of week year / day of week.
  static LocalDate FromWeekYearWeekAndDay(int weekYear, int weekOfWeekYear, IsoDayOfWeek dayOfWeek)
  => WeekYearRules.Iso.GetLocalDate(weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.Iso);

  /// Returns the local date corresponding to a particular occurrence of a day-of-week
  /// within a year and month. For example, this method can be used to ask for "the third Monday in April 2012".
  ///
  /// The returned date is always in the ISO calendar. This method is unrelated to week-years and any rules for
  /// "business weeks" and the like - if a month begins on a Friday, then asking for the first Friday will give
  /// that day, for example.
  ///
  /// [year]: The year of the value to return.
  /// [month]: The month of the value to return.
  /// [occurrence]: The occurrence of the value to return, which must be in the range [1, 5]. The value 5 can
  /// be used to always return the last occurrence of the specified day-of-week, even if there are only 4
  /// occurrences of that day-of-week in the month.
  /// [dayOfWeek]: The day-of-week of the value to return.
  /// The date corresponding to the given year and month, on the given occurrence of the
  /// given day of week.
  static LocalDate FromYearMonthWeekAndDay(int year, int month, int occurrence, IsoDayOfWeek dayOfWeek)
  {
    // This validates year and month as well as getting us a useful date.
    LocalDate startOfMonth = new LocalDate(year, month, 1);
    Preconditions.checkArgumentRange('occurrence', occurrence, 1, 5);
    Preconditions.checkArgumentRange('dayOfWeek', dayOfWeek.value, 1, 7);

    // Correct day of week, 1st week of month.
    int week1Day = dayOfWeek - startOfMonth.DayOfWeek + 1;
    if (week1Day <= 0)
    {
      week1Day += 7;
    }
    int targetDay = week1Day + (occurrence - 1) * 7;
    if (targetDay > CalendarSystem.Iso.GetDaysInMonth(year, month))
    {
      targetDay -= 7;
    }
    return new LocalDate(year, month, targetDay);
  }

  /// Adds the specified period to the date. Friendly alternative to `operator+()`.
  ///
  /// [date]: The date to add the period to
  /// [period]: The period to add. Must not contain any (non-zero) time units.
  /// Returns: The sum of the given date and period
  static LocalDate Add(LocalDate date, Period period) => date + period;

  /// Adds the specified period to this date. Fluent alternative to `operator+()`.
  ///
  /// [period]: The period to add. Must not contain any (non-zero) time units.
  /// Returns: The sum of this date and the given period
  LocalDate Plus(Period period) => this + period;

  /// Adds the specified period to the date.
  ///
  /// [date]: The date to add the period to
  /// [period]: The period to add. Must not contain any (non-zero) time units.
  /// Returns: The sum of the given date and period
  LocalDate operator +(Period period)
  {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.HasTimeComponent, 'period', "Cannot add a period with a time component to a date");
    return period.AddDateTo(this, 1);
  }

//  /// <summary>
//  /// Combines the given <see cref="LocalDate"/> and <see cref="LocalTime"/> components
//  /// into a single <see cref="LocalDateTime"/>.
//  /// </summary>
//  /// <param name="date">The date to add the time to</param>
//  /// <param name="time">The time to add</param>
//  /// <returns>The sum of the given date and time</returns>
//  LocalDateTime AtTime(LocalTime time) => new LocalDateTime(this, time);

  /// Subtracts the specified period from the date. Friendly alternative to `operator-()`.
  ///
  /// [date]: The date to subtract the period from
  /// [period]: The period to subtract. Must not contain any (non-zero) time units.
  /// Returns: The result of subtracting the given period from the date.
  static LocalDate Subtract(LocalDate date, Period period) => date - period;

  /// Subtracts one date from another, returning the result as a [Period] with units of years, months and days.
  ///
  /// This is simply a convenience method for calling [Period.Between(LocalDate,LocalDate)].
  /// The calendar systems of the two dates must be the same.
  ///
  /// [lhs]: The date to subtract from
  /// [rhs]: The date to subtract
  /// Returns: The result of subtracting one date from another.
  static Period Between(LocalDate lhs, LocalDate rhs) => lhs - rhs;

  /// Subtracts the specified period from this date. Fluent alternative to `operator-()`.
  ///
  /// [period]: The period to subtract. Must not contain any (non-zero) time units.
  /// Returns: The result of subtracting the given period from this date.
  LocalDate MinusPeriod(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.HasTimeComponent, 'period', "Cannot subtract a period with a time component from a date");
    return period.AddDateTo(this, -1);
  }

  /// Subtracts the specified date from this date, returning the result as a [Period] with units of years, months and days.
  /// Fluent alternative to `operator-()`.
  ///
  /// The specified date must be in the same calendar system as this.
  /// [date]: The date to subtract from this
  /// Returns: The difference between the specified date and this one
  Period MinusDate(LocalDate date) => Period.BetweenDates(date, this); // this - date;

  /// Subtracts one date from another, returning the result as a [Period] with units of years, months and days.
  ///
  /// This is simply a convenience operator for calling [Period.Between(LocalDate,LocalDate)].
  /// The calendar systems of the two dates must be the same; an exception will be thrown otherwise.
  ///
  /// [lhs]: The date to subtract from
  /// [rhs]: The date to subtract
  /// Returns: The result of subtracting one date from another.
  /// [ArgumentException]: 
  /// [lhs] and [rhs] are not in the same calendar system.
  ///
  /// Subtracts the specified period from the date.
  /// This is a convenience operator over the [Minus(Period)] method.
  ///
  /// [date]: The date to subtract the period from
  /// [period]: The period to subtract. Must not contain any (non-zero) time units.
  /// Returns: The result of subtracting the given period from the date
  // todo: still hate dynamic dispatch
  dynamic operator -(dynamic rhs) => rhs is LocalDate ? MinusDate(rhs) : rhs is Period ? MinusPeriod(rhs) : throw new TypeError();

  /// Compares two [LocalDate] values for equality. This requires
  /// that the dates be the same, within the same calendar.
  ///
  /// [lhs]: The first value to compare
  /// [rhs]: The second value to compare
  /// Returns: True if the two dates are the same and in the same calendar; false otherwise
  bool operator ==(dynamic rhs) => rhs is LocalDate && this._yearMonthDayCalendar == rhs._yearMonthDayCalendar;

// Comparison operators: note that we can't use YearMonthDayCalendar.Compare, as only the calendar knows whether it can use
// naive comparisons.

  /// Compares two dates to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is strictly earlier than [rhs], false otherwise.
  bool operator <(LocalDate rhs)
  {
    Preconditions.checkArgument(this.Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) < 0;
  }

  /// Compares two dates to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is earlier than or equal to [rhs], false otherwise.
  bool operator <=(LocalDate rhs)
  {
    Preconditions.checkArgument(this.Calendar== rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) <= 0;
  }

  /// Compares two dates to see if the left one is strictly later than the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is strictly later than [rhs], false otherwise.
  bool operator >(LocalDate rhs)
  {
    Preconditions.checkArgument(this.Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) > 0;
  }

  /// Compares two dates to see if the left one is later than or equal to the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is later than or equal to [rhs], false otherwise.
  bool operator >=(LocalDate rhs)
  {
    Preconditions.checkArgument(Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) >= 0;
  }

  /// Indicates whether this date is earlier, later or the same as another one.
  ///
  /// Only dates within the same calendar systems can be compared with this method. Attempting to compare
  /// dates within different calendars will fail with an [ArgumentException]. Ideally, comparisons
  /// between values in different calendars would be a compile-time failure, but failing at execution time
  /// is almost always preferable to continuing.
  ///
  /// [other]: The other date to compare this one with
  /// [ArgumentException]: The calendar system of [other] is not the
  /// same as the calendar system of this value.
  /// A value less than zero if this date is earlier than [other];
  /// zero if this date is the same as [other]; a value greater than zero if this date is
  /// later than [other].
  int compareTo(LocalDate other)
  {
    Preconditions.checkArgument(Calendar == other?.Calendar, 'other', "Only values with the same calendar system can be compared");
    return Calendar.Compare(yearMonthDay, other.yearMonthDay);
  }

  /// Implementation of [IComparable.CompareTo] to compare two LocalDates.
  ///
  /// This uses explicit interface implementation to avoid it being called accidentally. The generic implementation should usually be preferred.
  ///
  /// [ArgumentException]: [obj] is non-null but does not refer to an instance of [LocalDate], or refers
  /// to a date in a different calendar system.
  /// [obj]: The object to compare this value with.
  /// The result of comparing this LocalDate with another one; see [CompareTo(LocalDate)] for general details.
  /// If [obj] is null, this method returns a value greater than 0.
  // todo: Dart has a Comparable<T> something or another
  int IComparable_CompareTo(dynamic obj)
  {
    if (obj == null)
    {
      return 1;
    }
    Preconditions.checkArgument(obj is LocalDate, 'obj', "Object must be of type NodaTime.LocalDate.");
    return compareTo(obj as LocalDate);
  }

  /// Returns the later date of the given two.
  ///
  /// [x]: The first date to compare.
  /// [y]: The second date to compare.
  /// [ArgumentException]: The two dates have different calendar systems.
  /// Returns: The later date of [x] or [y].
  static LocalDate Max(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.Calendar == y.Calendar, 'y', "Only values with the same calendar system can be compared");
    return x > y ? x : y;
  }

  /// Returns the earlier date of the given two.
  ///
  /// [x]: The first date to compare.
  /// [y]: The second date to compare.
  /// [ArgumentException]: The two dates have different calendar systems.
  /// Returns: The earlier date of [x] or [y].
  static LocalDate Min(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.Calendar == y.Calendar, 'y', "Only values with the same calendar system can be compared");
    return x < y ? x : y;
  }

  /// Returns a hash code for this local date.
  ///
  /// Returns: A hash code for this local date.
  @override int get hashCode => _yearMonthDayCalendar.hashCode;

//  /// <summary>
//  /// Compares two <see cref="LocalDate"/> values for equality. This requires
//  /// that the dates be the same, within the same calendar.
//  /// </summary>
//  /// <param name="obj">The object to compare this date with.</param>
//  /// <returns>True if the given value is another local date equal to this one; false otherwise.</returns>
//  bool Equals(dynamic obj) => obj is LocalDate && this == obj;

  /// Compares two [LocalDate] values for equality. This requires
  /// that the dates be the same, within the same calendar.
  ///
  /// [other]: The value to compare this date with.
  /// Returns: True if the given value is another local date equal to this one; false otherwise.
  bool Equals(LocalDate other) => this == other;

  /// Resolves this local date into a [ZonedDateTime] in the given time zone representing the
  /// start of this date in the given zone.
  ///
  /// This is a convenience method for calling [DateTimeZone.AtStartOfDay(LocalDate)].
  ///
  /// [zone]: The time zone to map this local date into
  /// [SkippedTimeException]: The entire day was skipped due to a very large time zone transition.
  /// (This is extremely rare.)
  /// Returns: The [ZonedDateTime] representing the earliest time on this date, in the given time zone.
  ZonedDateTime AtStartOfDayInZone(DateTimeZone zone)
  {
  Preconditions.checkNotNull(zone, 'zone');
  return zone.AtStartOfDay(this);
  }

  /// Creates a new LocalDate representing the same physical date, but in a different calendar.
  /// The returned LocalDate is likely to have different field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// [calendar]: The calendar system to convert this local date to.
  /// Returns: The converted LocalDate
  LocalDate WithCalendar(CalendarSystem calendar)
  {
  Preconditions.checkNotNull(calendar, 'calendar');
  return new LocalDate.fromDaysSinceEpoch_forCalendar(DaysSinceEpoch, calendar);
  }

  /// Returns a new LocalDate representing the current value with the given number of years added.
  ///
  /// If the resulting date is invalid, lower fields (typically the day of month) are reduced to find a valid value.
  /// For example, adding one year to February 29th 2012 will return February 28th 2013; subtracting one year from
  /// February 29th 2012 will return February 28th 2011.
  ///
  /// [years]: The number of years to add
  /// Returns: The current value plus the given number of years.
  LocalDate PlusYears(int years) => DatePeriodFields.YearsField.Add(this, years);

  /// Returns a new LocalDate representing the current value with the given number of months added.
  ///
  /// This method does not try to maintain the year of the current value, so adding four months to a value in 
  /// October will result in a value in the following February.
  ///
  /// If the resulting date is invalid, the day of month is reduced to find a valid value.
  /// For example, adding one month to January 30th 2011 will return February 28th 2011; subtracting one month from
  /// March 30th 2011 will return February 28th 2011.
  ///
  /// [months]: The number of months to add
  /// Returns: The current date plus the given number of months
  LocalDate PlusMonths(int months) => DatePeriodFields.MonthsField.Add(this, months);

  /// Returns a new LocalDate representing the current value with the given number of days added.
  ///
  /// This method does not try to maintain the month or year of the current value, so adding 3 days to a value of January 30th
  /// will result in a value of February 2nd.
  ///
  /// [days]: The number of days to add
  /// Returns: The current value plus the given number of days.
  LocalDate PlusDays(int days) => DatePeriodFields.DaysField.Add(this, days);

  /// Returns a new LocalDate representing the current value with the given number of weeks added.
  ///
  /// [weeks]: The number of weeks to add
  /// Returns: The current value plus the given number of weeks.
  LocalDate PlusWeeks(int weeks) => DatePeriodFields.WeeksField.Add(this, weeks);

  /// Returns the next [LocalDate] falling on the specified [IsoDayOfWeek].
  /// This is a strict "next" - if this date on already falls on the target
  /// day of the week, the returned value will be a week later.
  ///
  /// [targetDayOfWeek]: The ISO day of the week to return the next date of.
  /// Returns: The next [LocalDate] falling on the specified day of the week.
  /// [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDate Next(IsoDayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < IsoDayOfWeek.monday || targetDayOfWeek > IsoDayOfWeek.sunday)
    {
      throw new RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    IsoDayOfWeek thisDay = DayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference <= 0)
    {
      difference += 7;
    }
    return PlusDays(difference);
  }

  /// Returns the previous [LocalDate] falling on the specified [IsoDayOfWeek].
  /// This is a strict "previous" - if this date on already falls on the target
  /// day of the week, the returned value will be a week earlier.
  ///
  /// [targetDayOfWeek]: The ISO day of the week to return the previous date of.
  /// Returns: The previous [LocalDate] falling on the specified day of the week.
  /// [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDate Previous(IsoDayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < IsoDayOfWeek.monday || targetDayOfWeek > IsoDayOfWeek.sunday)
    {
      throw new RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    IsoDayOfWeek thisDay = DayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference >= 0)
    {
      difference -= 7;
    }
    return PlusDays(difference);
  }

  /// Returns an [OffsetDate] for this local date with the given offset.
  ///
  /// This method is purely a convenient alternative to calling the [OffsetDate] constructor directly.
  /// [offset]: The offset to apply.
  /// Returns: The result of this date offset by the given amount.
  OffsetDate WithOffset(Offset offset) => new OffsetDate(this, offset);

  /// Combines this [LocalDate] with the given [LocalTime]
  /// into a single [LocalDateTime].
  /// Fluent alternative to `operator+()`.
  ///
  /// [time]: The time to combine with this date.
  /// Returns: The [LocalDateTime] representation of the given time on this date
  LocalDateTime At(LocalTime time) => new LocalDateTime(this, time);

  LocalDate With(LocalDate Function(LocalDate) adjuster) => adjuster(this);

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ("D"), using the current thread's
  /// culture to obtain a format provider.
  // @override String toString() => TextShim.toStringLocalDate(this); // LocalDatePattern.BclSupport.Format(this, null, CultureInfo.CurrentCulture);
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      LocalDatePattern.BclSupport.Format(this, patternText, formatProvider ?? CultureInfo.currentCulture);

/// Formats the value of the current instance using the specified pattern.
///
/// A [String] containing the value of the current instance in the specified format.
///
/// [patternText]: The [String] specifying the pattern to use,
/// or null to use the default format pattern ("D").
///
/// [formatProvider]: The [IIFormatProvider] to use when formatting the value,
/// or null to use the current thread's culture to obtain a format provider.
///
/// <filterpriority>2</filterpriority>
//  String ToStringFormatted(string patternText, IFormatProvider formatProvider) =>
//      LocalDatePattern.BclSupport.Format(this, patternText, formatProvider);

}

