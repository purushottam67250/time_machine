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

IDateTimeZoneProvider Tzdb;

/// Tests for DateTimeZoneCache.
Future main() async {
  Tzdb = await DateTimeZoneProviders.Tzdb;

  await runTests();
}

void Construction_NullProvider()
{
  expect(() async => await DateTimeZoneCache.getCache(null), throwsArgumentError);
}

@Test()
void InvalidSource_NullVersionId()
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2"])..VersionId = null;
  expect(DateTimeZoneCache.getCache(source), willThrow<InvalidDateTimeZoneSourceError>());
}

@Test()
Future InvalidSource_NullIdSequence() async
{
  List<String> ids = null;
  var source = new TestDateTimeZoneSource(ids);
  expect(DateTimeZoneCache.getCache(source), willThrow<InvalidDateTimeZoneSourceError>());
}

@Test()
Future InvalidSource_ReturnsNullForAdvertisedId() async
{
  var source = new NullReturningTestDateTimeZoneSource(["foo", "bar"]);
  var cache = await DateTimeZoneCache.getCache(source);
  expect(() => cache.GetZoneOrNull("foo"), willThrow<InvalidDateTimeZoneSourceError>());
}

@Test()
void InvalidProvider_NullIdWithinSequence()
{
  var source = new TestDateTimeZoneSource(["Test1", null]);
  expect(DateTimeZoneCache.getCache(source), willThrow<InvalidDateTimeZoneSourceError>());
}

@Test()
Future CachingForPresentValues() async
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  var zone1a = await provider["Test1"];
  expect(zone1a, isNotNull);
  expect("Test1", source.LastRequestedId);

  // Hit up the cache (and thus the source) for Test2
  expect(await provider["Test2"], isNotNull);
  expect("Test2", source.LastRequestedId);

  // Ask for Test1 again
  var zone1b = await provider["Test1"];
  // We won't have consulted the source again
  expect("Test2", source.LastRequestedId);

  expect(identical(zone1a, zone1b), isTrue);
}

@Test()
Future SourceIsNotAskedForUtcIfNotAdvertised() async
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  var zone = await provider[DateTimeZone.UtcId];
  expect(zone, isNotNull);
  expect(source.LastRequestedId, isNull);
}

@Test()
Future SourceIsAskedForUtcIfAdvertised() async
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2", "UTC"]);
  var provider = await DateTimeZoneCache.getCache(source);
  var zone = await provider[DateTimeZone.UtcId];
  expect(zone, isNotNull);
  expect("UTC", source.LastRequestedId);
}

@Test()
Future SourceIsNotAskedForUnknownIds() async
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  expect(provider["Unknown"], willThrow<InvalidDateTimeZoneSourceError>());
  expect(source.LastRequestedId, isNull);
}

@Test()
Future UtcIsReturnedInIdsIfAdvertisedByProvider() async
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2", "UTC"]);
  var provider = await DateTimeZoneCache.getCache(source);
  expect(provider.Ids.contains(DateTimeZone.UtcId), isTrue);
}

@Test()
Future UtcIsNotReturnedInIdsIfNotAdvertisedByProvider() async
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  expect(provider.Ids.contains(DateTimeZone.UtcId), isFalse);
}

@Test()
Future FixedOffsetSucceedsWhenNotAdvertised() async
{
  var source = new TestDateTimeZoneSource(["Test1", "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  String id = "UTC+05:30";
  DateTimeZone zone = await provider[id];
  expect(DateTimeZone.ForOffset(new Offset.fromHoursAndMinutes(5, 30)), zone);
  expect(id, zone.id);
  expect(source.LastRequestedId, isNull);
}

@Test()
Future FixedOffsetConsultsSourceWhenAdvertised() async
{
  String id = "UTC+05:30";
  var source = new TestDateTimeZoneSource(["Test1", "Test2", id]);
  var provider = await DateTimeZoneCache.getCache(source);
  DateTimeZone zone = await provider[id];
  expect(id, zone.id);
  expect(id, source.LastRequestedId);
}

@Test()
Future FixedOffsetUncached() async
{
  String id = "UTC+05:26";
  var source = new TestDateTimeZoneSource(["Test1", "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  DateTimeZone zone1 = await provider[id];
  DateTimeZone zone2 = await provider[id];
  expect(identical(zone1, zone2), isFalse);
  expect(zone1, zone2);
}

@Test()
Future FixedOffsetZeroReturnsUtc() async
{
  String id = "UTC+00:00";
  var source = new TestDateTimeZoneSource(["Test1", "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  DateTimeZone zone = await provider[id];
  expect(DateTimeZone.Utc, zone);
  expect(source.LastRequestedId, isNull);
}

@Test()
void Tzdb_Indexer_InvalidFixedOffset()
{
  expect(Tzdb["UTC+5Months"], willThrow<DateTimeZoneNotFoundException>());
}

@Test()
Future NullIdRejected() async
{
  var provider = await DateTimeZoneCache.getCache(new TestDateTimeZoneSource(["Test1", "Test2"]));
  expect(provider[null], throwsArgumentError);
}

@Test()
Future EmptyIdAccepted() async
{
  var provider = await DateTimeZoneCache.getCache(new TestDateTimeZoneSource(["Test1", "Test2"]));
  expect(provider[""], willThrow<DateTimeZoneNotFoundException>());
}

@Test()
Future VersionIdPassThrough() async
{
  var provider = await DateTimeZoneCache.getCache(new TestDateTimeZoneSource(["Test1", "Test2"])..VersionId = new Future(() => "foo"));
  expect("foo", provider.VersionId);
}

@Test("Test for issue 7 in bug tracker")
Future Tzdb_IterateOverIds() async
{
  // According to bug, this would go bang
  int count = Tzdb.Ids.length;

  expect(count > 1, isTrue);
  int utcCount = Tzdb.Ids.where((id) => id == DateTimeZone.UtcId).length;
  expect(1, utcCount);
}

@Test()
Future Tzdb_Indexer_UtcId() async
{
  expect(DateTimeZone.Utc, await Tzdb[DateTimeZone.UtcId]);
}

@Test()
Future Tzdb_Indexer_AmericaLosAngeles() async
{
  const String americaLosAngeles = "America/Los_Angeles";
  var actual = await Tzdb[americaLosAngeles];
  expect(actual, isNotNull);
  expect(DateTimeZone.Utc, isNot(actual));
  expect(americaLosAngeles, actual.id);
}

@Test()
Future Tzdb_Ids_All() async
{
  // todo: we don't have Utc in here.... is this what we want? Need to refer to our faux TZDB
  var actual = Tzdb.Ids;
  var actualCount = actual.length;
  expect(actualCount > 1, isTrue);
  var utc = actual.firstWhere((id) => id == DateTimeZone.UtcId);
  expect(DateTimeZone.UtcId, utc);
}

/// Simply tests that every ID in the built-in database can be fetched. This is also
/// helpful for diagnostic debugging when we want to check that some potential
/// invariant holds for all time zones...
@Test()
void Tzdb_Indexer_AllIds()
{
  for (String id in Tzdb.Ids)
  {
    expect(Tzdb[id], isNotNull);
  }
}

@Test()
Future GetSystemDefault_SourceReturnsNullId() async
{
  var source = new NullReturningTestDateTimeZoneSource(["foo", "bar"]);
  var cache = await DateTimeZoneCache.getCache(source);
  expect(cache.GetSystemDefault(), willThrow<DateTimeZoneNotFoundException>());
}


class TestDateTimeZoneSource extends IDateTimeZoneSource {
  String LastRequestedId;
  final List<String> ids;

  TestDateTimeZoneSource(this.ids) {
    VersionId = new Future(() => "test version");
  }

  Future<Iterable<String>> GetIds() => new Future(() => ids);

  Future<DateTimeZone> ForId(String id) {
    return new Future(() => ForIdSync(id));
  }

  DateTimeZone ForIdSync(String id) {
    LastRequestedId = id;
    return new SingleTransitionDateTimeZone.withId(TimeConstants.unixEpoch, Offset.zero, new Offset.fromHours(id.hashCode % 18), id);
  }

  Future<String> VersionId;

  String GetSystemDefaultId() => "map";
}

// A test source that returns null from ForId and GetSystemDefaultId()
class NullReturningTestDateTimeZoneSource extends TestDateTimeZoneSource {
  NullReturningTestDateTimeZoneSource(List<String> ids) : super(ids) {
  }

  @override Future<DateTimeZone> ForId(String id) {
    // Still remember what was requested.
    var _id = super.ForId(id);
    return new Future(() => null);
  }

  @override String GetSystemDefaultId() => null;

  @override DateTimeZone ForIdSync(String id) {
    var _id = super.ForIdSync(id);
    return null;
  }
}
