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

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

//void InstanceNow()
//{
//  int frameworkNowTicks = TimeConstants.bclEpoch.plus(DateTime.UtcNow).ToUnixTimeTicks();
//  int nodaTicks = SystemClock.instance.getCurrentInstant().toUnixTimeTicks();
//  assert((nodaTicks - frameworkNowTicks).abs() == new Span(seconds: 1).totalTicks);
//  // Assert.Less(Math.Abs(nodaTicks - frameworkNowTicks), Duration.FromSeconds(1).BclCompatibleTicks);
//}

@Test()
void Sanity()
{
  // Previously all the conversions missed the SystemConversions.DateTimeEpochTicks,
  // so they were self-consistent but not consistent with sanity.
  Instant minimumExpected = new Instant.fromUtc(2011, 8, 1, 0, 0);
  Instant maximumExpected = new Instant.fromUtc(2020, 1, 1, 0, 0);
  Instant now = SystemClock.instance.getCurrentInstant();
  expect(minimumExpected.toUnixTimeTicks(), lessThan(now.toUnixTimeTicks()));
  expect(now.toUnixTimeTicks(), lessThan(maximumExpected.toUnixTimeTicks()));
}


