// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

CalendarSystem Iso = CalendarSystem.Iso;

// These tests assume that if the method doesn't throw, it's doing the right thing - this
// is all tested elsewhere.
@Test()
void ValidateYearMonthDay_AllValues_ValidValuesDoesntThrow()
{
  Iso.ValidateYearMonthDay(20, 2, 20);
}

@Test()
void ValidateYearMonthDay_InvalidYear_Throws()
{
  expect(() => Iso.ValidateYearMonthDay(50000, 2, 20), throwsRangeError);
}

@Test()
void GetLocalInstant_InvalidMonth_Throws()
{
  expect(() => Iso.ValidateYearMonthDay(2010, 13, 20), throwsRangeError);
}

@Test()
void GetLocalInstant_29thOfFebruaryInNonLeapYear_Throws()
{
  expect(() => Iso.ValidateYearMonthDay(2010, 2, 29), throwsRangeError);
}

@Test()
void GetLocalInstant_29thOfFebruaryInLeapYear_DoesntThrow()
{
  Iso.ValidateYearMonthDay(2012, 2, 29);
}

