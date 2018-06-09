// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';

/// Factory class for time adjusters: functions from [LocalTime] to `LocalTime`,
/// which can be applied to [LocalTime], [LocalDateTime], and [OffsetDateTime].
@immutable
class TimeAdjusters {
  /// Gets a time adjuster to truncate the time to the second, discarding fractional seconds.
  static LocalTime Function(LocalTime) TruncateToSecond
  = (time) => new LocalTime(time.Hour, time.Minute, time.Second);

  /// Gets a time adjuster to truncate the time to the minute, discarding fractional minutes.
  static LocalTime Function(LocalTime) TruncateToMinute
  = (time) => new LocalTime(time.Hour, time.Minute);

  /// Get a time adjuster to truncate the time to the hour, discarding fractional hours.
  static LocalTime Function(LocalTime) TruncateToHour
  = (time) => new LocalTime(time.Hour, 0);
}
