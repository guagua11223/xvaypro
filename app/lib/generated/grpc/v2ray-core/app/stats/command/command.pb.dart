// This is a generated file - do not edit.
//
// Generated from app/stats/command/command.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class GetStatsRequest extends $pb.GeneratedMessage {
  factory GetStatsRequest({
    $core.String? name,
    $core.bool? reset,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (reset != null) result.reset = reset;
    return result;
  }

  GetStatsRequest._();

  factory GetStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'reset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest clone() => GetStatsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest copyWith(void Function(GetStatsRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatsRequest))
          as GetStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatsRequest create() => GetStatsRequest._();
  @$core.override
  GetStatsRequest createEmptyInstance() => create();
  static $pb.PbList<GetStatsRequest> createRepeated() =>
      $pb.PbList<GetStatsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetStatsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStatsRequest>(create);
  static GetStatsRequest? _defaultInstance;

  /// Name of the stat counter.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Whether or not to reset the counter to fetching its value.
  @$pb.TagNumber(2)
  $core.bool get reset => $_getBF(1);
  @$pb.TagNumber(2)
  set reset($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReset() => $_has(1);
  @$pb.TagNumber(2)
  void clearReset() => $_clearField(2);
}

class Stat extends $pb.GeneratedMessage {
  factory Stat({
    $core.String? name,
    $fixnum.Int64? value,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (value != null) result.value = value;
    return result;
  }

  Stat._();

  factory Stat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Stat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Stat',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aInt64(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stat clone() => Stat()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stat copyWith(void Function(Stat) updates) =>
      super.copyWith((message) => updates(message as Stat)) as Stat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Stat create() => Stat._();
  @$core.override
  Stat createEmptyInstance() => create();
  static $pb.PbList<Stat> createRepeated() => $pb.PbList<Stat>();
  @$core.pragma('dart2js:noInline')
  static Stat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Stat>(create);
  static Stat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get value => $_getI64(1);
  @$pb.TagNumber(2)
  set value($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

class GetStatsResponse extends $pb.GeneratedMessage {
  factory GetStatsResponse({
    Stat? stat,
  }) {
    final result = create();
    if (stat != null) result.stat = stat;
    return result;
  }

  GetStatsResponse._();

  factory GetStatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetStatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..aOM<Stat>(1, _omitFieldNames ? '' : 'stat', subBuilder: Stat.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse clone() => GetStatsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse copyWith(void Function(GetStatsResponse) updates) =>
      super.copyWith((message) => updates(message as GetStatsResponse))
          as GetStatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatsResponse create() => GetStatsResponse._();
  @$core.override
  GetStatsResponse createEmptyInstance() => create();
  static $pb.PbList<GetStatsResponse> createRepeated() =>
      $pb.PbList<GetStatsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetStatsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStatsResponse>(create);
  static GetStatsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Stat get stat => $_getN(0);
  @$pb.TagNumber(1)
  set stat(Stat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStat() => $_has(0);
  @$pb.TagNumber(1)
  void clearStat() => $_clearField(1);
  @$pb.TagNumber(1)
  Stat ensureStat() => $_ensure(0);
}

class QueryStatsRequest extends $pb.GeneratedMessage {
  factory QueryStatsRequest({
    $core.String? pattern,
    $core.bool? reset,
    $core.Iterable<$core.String>? patterns,
    $core.bool? regexp,
  }) {
    final result = create();
    if (pattern != null) result.pattern = pattern;
    if (reset != null) result.reset = reset;
    if (patterns != null) result.patterns.addAll(patterns);
    if (regexp != null) result.regexp = regexp;
    return result;
  }

  QueryStatsRequest._();

  factory QueryStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QueryStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryStatsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'pattern')
    ..aOB(2, _omitFieldNames ? '' : 'reset')
    ..pPS(3, _omitFieldNames ? '' : 'patterns')
    ..aOB(4, _omitFieldNames ? '' : 'regexp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryStatsRequest clone() => QueryStatsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryStatsRequest copyWith(void Function(QueryStatsRequest) updates) =>
      super.copyWith((message) => updates(message as QueryStatsRequest))
          as QueryStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryStatsRequest create() => QueryStatsRequest._();
  @$core.override
  QueryStatsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryStatsRequest> createRepeated() =>
      $pb.PbList<QueryStatsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryStatsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryStatsRequest>(create);
  static QueryStatsRequest? _defaultInstance;

  /// Deprecated, use Patterns instead
  @$pb.TagNumber(1)
  $core.String get pattern => $_getSZ(0);
  @$pb.TagNumber(1)
  set pattern($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPattern() => $_has(0);
  @$pb.TagNumber(1)
  void clearPattern() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get reset => $_getBF(1);
  @$pb.TagNumber(2)
  set reset($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReset() => $_has(1);
  @$pb.TagNumber(2)
  void clearReset() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get patterns => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get regexp => $_getBF(3);
  @$pb.TagNumber(4)
  set regexp($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRegexp() => $_has(3);
  @$pb.TagNumber(4)
  void clearRegexp() => $_clearField(4);
}

class QueryStatsResponse extends $pb.GeneratedMessage {
  factory QueryStatsResponse({
    $core.Iterable<Stat>? stat,
  }) {
    final result = create();
    if (stat != null) result.stat.addAll(stat);
    return result;
  }

  QueryStatsResponse._();

  factory QueryStatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QueryStatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryStatsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..pc<Stat>(1, _omitFieldNames ? '' : 'stat', $pb.PbFieldType.PM,
        subBuilder: Stat.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryStatsResponse clone() => QueryStatsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryStatsResponse copyWith(void Function(QueryStatsResponse) updates) =>
      super.copyWith((message) => updates(message as QueryStatsResponse))
          as QueryStatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryStatsResponse create() => QueryStatsResponse._();
  @$core.override
  QueryStatsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryStatsResponse> createRepeated() =>
      $pb.PbList<QueryStatsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryStatsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryStatsResponse>(create);
  static QueryStatsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Stat> get stat => $_getList(0);
}

class SysStatsRequest extends $pb.GeneratedMessage {
  factory SysStatsRequest() => create();

  SysStatsRequest._();

  factory SysStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SysStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SysStatsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysStatsRequest clone() => SysStatsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysStatsRequest copyWith(void Function(SysStatsRequest) updates) =>
      super.copyWith((message) => updates(message as SysStatsRequest))
          as SysStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SysStatsRequest create() => SysStatsRequest._();
  @$core.override
  SysStatsRequest createEmptyInstance() => create();
  static $pb.PbList<SysStatsRequest> createRepeated() =>
      $pb.PbList<SysStatsRequest>();
  @$core.pragma('dart2js:noInline')
  static SysStatsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SysStatsRequest>(create);
  static SysStatsRequest? _defaultInstance;
}

class SysStatsResponse extends $pb.GeneratedMessage {
  factory SysStatsResponse({
    $core.int? numGoroutine,
    $core.int? numGC,
    $fixnum.Int64? alloc,
    $fixnum.Int64? totalAlloc,
    $fixnum.Int64? sys,
    $fixnum.Int64? mallocs,
    $fixnum.Int64? frees,
    $fixnum.Int64? liveObjects,
    $fixnum.Int64? pauseTotalNs,
    $core.int? uptime,
  }) {
    final result = create();
    if (numGoroutine != null) result.numGoroutine = numGoroutine;
    if (numGC != null) result.numGC = numGC;
    if (alloc != null) result.alloc = alloc;
    if (totalAlloc != null) result.totalAlloc = totalAlloc;
    if (sys != null) result.sys = sys;
    if (mallocs != null) result.mallocs = mallocs;
    if (frees != null) result.frees = frees;
    if (liveObjects != null) result.liveObjects = liveObjects;
    if (pauseTotalNs != null) result.pauseTotalNs = pauseTotalNs;
    if (uptime != null) result.uptime = uptime;
    return result;
  }

  SysStatsResponse._();

  factory SysStatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SysStatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SysStatsResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'NumGoroutine', $pb.PbFieldType.OU3,
        protoName: 'NumGoroutine')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'NumGC', $pb.PbFieldType.OU3,
        protoName: 'NumGC')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'Alloc', $pb.PbFieldType.OU6,
        protoName: 'Alloc', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'TotalAlloc', $pb.PbFieldType.OU6,
        protoName: 'TotalAlloc', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'Sys', $pb.PbFieldType.OU6,
        protoName: 'Sys', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'Mallocs', $pb.PbFieldType.OU6,
        protoName: 'Mallocs', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'Frees', $pb.PbFieldType.OU6,
        protoName: 'Frees', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'LiveObjects', $pb.PbFieldType.OU6,
        protoName: 'LiveObjects', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'PauseTotalNs', $pb.PbFieldType.OU6,
        protoName: 'PauseTotalNs', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'Uptime', $pb.PbFieldType.OU3,
        protoName: 'Uptime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysStatsResponse clone() => SysStatsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysStatsResponse copyWith(void Function(SysStatsResponse) updates) =>
      super.copyWith((message) => updates(message as SysStatsResponse))
          as SysStatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SysStatsResponse create() => SysStatsResponse._();
  @$core.override
  SysStatsResponse createEmptyInstance() => create();
  static $pb.PbList<SysStatsResponse> createRepeated() =>
      $pb.PbList<SysStatsResponse>();
  @$core.pragma('dart2js:noInline')
  static SysStatsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SysStatsResponse>(create);
  static SysStatsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get numGoroutine => $_getIZ(0);
  @$pb.TagNumber(1)
  set numGoroutine($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNumGoroutine() => $_has(0);
  @$pb.TagNumber(1)
  void clearNumGoroutine() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get numGC => $_getIZ(1);
  @$pb.TagNumber(2)
  set numGC($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNumGC() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumGC() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get alloc => $_getI64(2);
  @$pb.TagNumber(3)
  set alloc($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlloc() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlloc() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get totalAlloc => $_getI64(3);
  @$pb.TagNumber(4)
  set totalAlloc($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalAlloc() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalAlloc() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sys => $_getI64(4);
  @$pb.TagNumber(5)
  set sys($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSys() => $_has(4);
  @$pb.TagNumber(5)
  void clearSys() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get mallocs => $_getI64(5);
  @$pb.TagNumber(6)
  set mallocs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMallocs() => $_has(5);
  @$pb.TagNumber(6)
  void clearMallocs() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get frees => $_getI64(6);
  @$pb.TagNumber(7)
  set frees($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFrees() => $_has(6);
  @$pb.TagNumber(7)
  void clearFrees() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get liveObjects => $_getI64(7);
  @$pb.TagNumber(8)
  set liveObjects($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLiveObjects() => $_has(7);
  @$pb.TagNumber(8)
  void clearLiveObjects() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get pauseTotalNs => $_getI64(8);
  @$pb.TagNumber(9)
  set pauseTotalNs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPauseTotalNs() => $_has(8);
  @$pb.TagNumber(9)
  void clearPauseTotalNs() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get uptime => $_getIZ(9);
  @$pb.TagNumber(10)
  set uptime($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUptime() => $_has(9);
  @$pb.TagNumber(10)
  void clearUptime() => $_clearField(10);
}

class Config extends $pb.GeneratedMessage {
  factory Config() => create();

  Config._();

  factory Config.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'v2ray.core.app.stats.command'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config clone() => Config()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config copyWith(void Function(Config) updates) =>
      super.copyWith((message) => updates(message as Config)) as Config;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config create() => Config._();
  @$core.override
  Config createEmptyInstance() => create();
  static $pb.PbList<Config> createRepeated() => $pb.PbList<Config>();
  @$core.pragma('dart2js:noInline')
  static Config getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Config>(create);
  static Config? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
