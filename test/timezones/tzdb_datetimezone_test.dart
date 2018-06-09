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

Iterable<DateTimeZone> AllTzdbZones;

Future main() async {
  AllTzdbZones = await (await DateTimeZoneProviders.Tzdb).GetAllZones();

  await runTests();
}

@Test()
@TestCaseSource(#AllTzdbZones)
void AllZonesStartAndEndOfTime(DateTimeZone zone)
{
  var firstInterval = zone.GetZoneInterval(Instant.minValue);
  expect(firstInterval.HasStart, isFalse);
  var lastInterval = zone.GetZoneInterval(Instant.maxValue);
  expect(lastInterval.HasEnd, isFalse);
}

