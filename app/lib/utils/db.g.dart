// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $AssetTable extends Asset with drift.TableInfo<$AssetTable, AssetData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const drift.VerificationMeta _nameMeta = const drift.VerificationMeta(
    'name',
  );
  @override
  late final drift.GeneratedColumn<String> name = drift.GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final drift.GeneratedColumnWithTypeConverter<AssetType, int> type =
      drift.GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AssetType>($AssetTable.$convertertype);
  static const drift.VerificationMeta _pathMeta = const drift.VerificationMeta(
    'path',
  );
  @override
  late final drift.GeneratedColumn<String> path = drift.GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const drift.VerificationMeta _updatedAtMeta =
      const drift.VerificationMeta('updatedAt');
  @override
  late final drift.GeneratedColumn<DateTime> updatedAt =
      drift.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [id, name, type, path, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<AssetData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  AssetData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: $AssetTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AssetTable createAlias(String alias) {
    return $AssetTable(attachedDatabase, alias);
  }

  static drift.TypeConverter<AssetType, int> $convertertype =
      const AssetTypeConverter();
}

class AssetData extends drift.DataClass implements drift.Insertable<AssetData> {
  final int id;
  final String? name;

  /// remote, local
  final AssetType type;
  final String path;
  final DateTime updatedAt;
  const AssetData({
    required this.id,
    this.name,
    required this.type,
    required this.path,
    required this.updatedAt,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = drift.Variable<String>(name);
    }
    {
      map['type'] = drift.Variable<int>($AssetTable.$convertertype.toSql(type));
    }
    map['path'] = drift.Variable<String>(path);
    map['updated_at'] = drift.Variable<DateTime>(updatedAt);
    return map;
  }

  AssetCompanion toCompanion(bool nullToAbsent) {
    return AssetCompanion(
      id: drift.Value(id),
      name: name == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(name),
      type: drift.Value(type),
      path: drift.Value(path),
      updatedAt: drift.Value(updatedAt),
    );
  }

  factory AssetData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return AssetData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<AssetType>(json['type']),
      path: serializer.fromJson<String>(json['path']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<AssetType>(type),
      'path': serializer.toJson<String>(path),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AssetData copyWith({
    int? id,
    drift.Value<String?> name = const drift.Value.absent(),
    AssetType? type,
    String? path,
    DateTime? updatedAt,
  }) => AssetData(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    type: type ?? this.type,
    path: path ?? this.path,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AssetData copyWithCompanion(AssetCompanion data) {
    return AssetData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      path: data.path.present ? data.path.value : this.path,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, path, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetData &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.path == this.path &&
          other.updatedAt == this.updatedAt);
}

class AssetCompanion extends drift.UpdateCompanion<AssetData> {
  final drift.Value<int> id;
  final drift.Value<String?> name;
  final drift.Value<AssetType> type;
  final drift.Value<String> path;
  final drift.Value<DateTime> updatedAt;
  const AssetCompanion({
    this.id = const drift.Value.absent(),
    this.name = const drift.Value.absent(),
    this.type = const drift.Value.absent(),
    this.path = const drift.Value.absent(),
    this.updatedAt = const drift.Value.absent(),
  });
  AssetCompanion.insert({
    this.id = const drift.Value.absent(),
    this.name = const drift.Value.absent(),
    required AssetType type,
    required String path,
    required DateTime updatedAt,
  }) : type = drift.Value(type),
       path = drift.Value(path),
       updatedAt = drift.Value(updatedAt);
  static drift.Insertable<AssetData> custom({
    drift.Expression<int>? id,
    drift.Expression<String>? name,
    drift.Expression<int>? type,
    drift.Expression<String>? path,
    drift.Expression<DateTime>? updatedAt,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (path != null) 'path': path,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AssetCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<String?>? name,
    drift.Value<AssetType>? type,
    drift.Value<String>? path,
    drift.Value<DateTime>? updatedAt,
  }) {
    return AssetCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      path: path ?? this.path,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = drift.Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = drift.Variable<int>(
        $AssetTable.$convertertype.toSql(type.value),
      );
    }
    if (path.present) {
      map['path'] = drift.Variable<String>(path.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = drift.Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AssetLocalTable extends AssetLocal
    with drift.TableInfo<$AssetLocalTable, AssetLocalData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetLocalTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _assetIdMeta =
      const drift.VerificationMeta('assetId');
  @override
  late final drift.GeneratedColumn<int> assetId = drift.GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [assetId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_local';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<AssetLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {assetId};
  @override
  AssetLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetLocalData(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
    );
  }

  @override
  $AssetLocalTable createAlias(String alias) {
    return $AssetLocalTable(attachedDatabase, alias);
  }
}

class AssetLocalData extends drift.DataClass
    implements drift.Insertable<AssetLocalData> {
  final int assetId;
  const AssetLocalData({required this.assetId});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['asset_id'] = drift.Variable<int>(assetId);
    return map;
  }

  AssetLocalCompanion toCompanion(bool nullToAbsent) {
    return AssetLocalCompanion(assetId: drift.Value(assetId));
  }

  factory AssetLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return AssetLocalData(assetId: serializer.fromJson<int>(json['assetId']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'assetId': serializer.toJson<int>(assetId)};
  }

  AssetLocalData copyWith({int? assetId}) =>
      AssetLocalData(assetId: assetId ?? this.assetId);
  AssetLocalData copyWithCompanion(AssetLocalCompanion data) {
    return AssetLocalData(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetLocalData(')
          ..write('assetId: $assetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => assetId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetLocalData && other.assetId == this.assetId);
}

class AssetLocalCompanion extends drift.UpdateCompanion<AssetLocalData> {
  final drift.Value<int> assetId;
  const AssetLocalCompanion({this.assetId = const drift.Value.absent()});
  AssetLocalCompanion.insert({this.assetId = const drift.Value.absent()});
  static drift.Insertable<AssetLocalData> custom({
    drift.Expression<int>? assetId,
  }) {
    return drift.RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
    });
  }

  AssetLocalCompanion copyWith({drift.Value<int>? assetId}) {
    return AssetLocalCompanion(assetId: assetId ?? this.assetId);
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (assetId.present) {
      map['asset_id'] = drift.Variable<int>(assetId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetLocalCompanion(')
          ..write('assetId: $assetId')
          ..write(')'))
        .toString();
  }
}

class $AssetRemoteTable extends AssetRemote
    with drift.TableInfo<$AssetRemoteTable, AssetRemoteData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetRemoteTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _assetIdMeta =
      const drift.VerificationMeta('assetId');
  @override
  late final drift.GeneratedColumn<int> assetId = drift.GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset (id) ON DELETE CASCADE',
    ),
  );
  static const drift.VerificationMeta _urlMeta = const drift.VerificationMeta(
    'url',
  );
  @override
  late final drift.GeneratedColumn<String> url = drift.GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const drift.VerificationMeta _metaMeta = const drift.VerificationMeta(
    'meta',
  );
  @override
  late final drift.GeneratedColumn<String> meta = drift.GeneratedColumn<String>(
    'meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const drift.Constant("{}"),
  );
  static const drift.VerificationMeta _autoUpdateIntervalMeta =
      const drift.VerificationMeta('autoUpdateInterval');
  @override
  late final drift.GeneratedColumn<int> autoUpdateInterval =
      drift.GeneratedColumn<int>(
        'auto_update_interval',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const drift.VerificationMeta _downloadedFilePathMeta =
      const drift.VerificationMeta('downloadedFilePath');
  @override
  late final drift.GeneratedColumn<String> downloadedFilePath =
      drift.GeneratedColumn<String>(
        'downloaded_file_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const drift.VerificationMeta _checkedAtMeta =
      const drift.VerificationMeta('checkedAt');
  @override
  late final drift.GeneratedColumn<DateTime> checkedAt =
      drift.GeneratedColumn<DateTime>(
        'checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [
    assetId,
    url,
    meta,
    autoUpdateInterval,
    downloadedFilePath,
    checkedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_remote';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<AssetRemoteData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('meta')) {
      context.handle(
        _metaMeta,
        meta.isAcceptableOrUnknown(data['meta']!, _metaMeta),
      );
    }
    if (data.containsKey('auto_update_interval')) {
      context.handle(
        _autoUpdateIntervalMeta,
        autoUpdateInterval.isAcceptableOrUnknown(
          data['auto_update_interval']!,
          _autoUpdateIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoUpdateIntervalMeta);
    }
    if (data.containsKey('downloaded_file_path')) {
      context.handle(
        _downloadedFilePathMeta,
        downloadedFilePath.isAcceptableOrUnknown(
          data['downloaded_file_path']!,
          _downloadedFilePathMeta,
        ),
      );
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {assetId};
  @override
  AssetRemoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRemoteData(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      meta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta'],
      )!,
      autoUpdateInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_update_interval'],
      )!,
      downloadedFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}downloaded_file_path'],
      ),
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_at'],
      ),
    );
  }

  @override
  $AssetRemoteTable createAlias(String alias) {
    return $AssetRemoteTable(attachedDatabase, alias);
  }
}

class AssetRemoteData extends drift.DataClass
    implements drift.Insertable<AssetRemoteData> {
  final int assetId;

  /// github://owner/repo/asset.ext/sub/path
  final String url;
  final String meta;
  final int autoUpdateInterval;
  final String? downloadedFilePath;
  final DateTime? checkedAt;
  const AssetRemoteData({
    required this.assetId,
    required this.url,
    required this.meta,
    required this.autoUpdateInterval,
    this.downloadedFilePath,
    this.checkedAt,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['asset_id'] = drift.Variable<int>(assetId);
    map['url'] = drift.Variable<String>(url);
    map['meta'] = drift.Variable<String>(meta);
    map['auto_update_interval'] = drift.Variable<int>(autoUpdateInterval);
    if (!nullToAbsent || downloadedFilePath != null) {
      map['downloaded_file_path'] = drift.Variable<String>(downloadedFilePath);
    }
    if (!nullToAbsent || checkedAt != null) {
      map['checked_at'] = drift.Variable<DateTime>(checkedAt);
    }
    return map;
  }

  AssetRemoteCompanion toCompanion(bool nullToAbsent) {
    return AssetRemoteCompanion(
      assetId: drift.Value(assetId),
      url: drift.Value(url),
      meta: drift.Value(meta),
      autoUpdateInterval: drift.Value(autoUpdateInterval),
      downloadedFilePath: downloadedFilePath == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(downloadedFilePath),
      checkedAt: checkedAt == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(checkedAt),
    );
  }

  factory AssetRemoteData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return AssetRemoteData(
      assetId: serializer.fromJson<int>(json['assetId']),
      url: serializer.fromJson<String>(json['url']),
      meta: serializer.fromJson<String>(json['meta']),
      autoUpdateInterval: serializer.fromJson<int>(json['autoUpdateInterval']),
      downloadedFilePath: serializer.fromJson<String?>(
        json['downloadedFilePath'],
      ),
      checkedAt: serializer.fromJson<DateTime?>(json['checkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<int>(assetId),
      'url': serializer.toJson<String>(url),
      'meta': serializer.toJson<String>(meta),
      'autoUpdateInterval': serializer.toJson<int>(autoUpdateInterval),
      'downloadedFilePath': serializer.toJson<String?>(downloadedFilePath),
      'checkedAt': serializer.toJson<DateTime?>(checkedAt),
    };
  }

  AssetRemoteData copyWith({
    int? assetId,
    String? url,
    String? meta,
    int? autoUpdateInterval,
    drift.Value<String?> downloadedFilePath = const drift.Value.absent(),
    drift.Value<DateTime?> checkedAt = const drift.Value.absent(),
  }) => AssetRemoteData(
    assetId: assetId ?? this.assetId,
    url: url ?? this.url,
    meta: meta ?? this.meta,
    autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
    downloadedFilePath: downloadedFilePath.present
        ? downloadedFilePath.value
        : this.downloadedFilePath,
    checkedAt: checkedAt.present ? checkedAt.value : this.checkedAt,
  );
  AssetRemoteData copyWithCompanion(AssetRemoteCompanion data) {
    return AssetRemoteData(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      url: data.url.present ? data.url.value : this.url,
      meta: data.meta.present ? data.meta.value : this.meta,
      autoUpdateInterval: data.autoUpdateInterval.present
          ? data.autoUpdateInterval.value
          : this.autoUpdateInterval,
      downloadedFilePath: data.downloadedFilePath.present
          ? data.downloadedFilePath.value
          : this.downloadedFilePath,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRemoteData(')
          ..write('assetId: $assetId, ')
          ..write('url: $url, ')
          ..write('meta: $meta, ')
          ..write('autoUpdateInterval: $autoUpdateInterval, ')
          ..write('downloadedFilePath: $downloadedFilePath, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    url,
    meta,
    autoUpdateInterval,
    downloadedFilePath,
    checkedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRemoteData &&
          other.assetId == this.assetId &&
          other.url == this.url &&
          other.meta == this.meta &&
          other.autoUpdateInterval == this.autoUpdateInterval &&
          other.downloadedFilePath == this.downloadedFilePath &&
          other.checkedAt == this.checkedAt);
}

class AssetRemoteCompanion extends drift.UpdateCompanion<AssetRemoteData> {
  final drift.Value<int> assetId;
  final drift.Value<String> url;
  final drift.Value<String> meta;
  final drift.Value<int> autoUpdateInterval;
  final drift.Value<String?> downloadedFilePath;
  final drift.Value<DateTime?> checkedAt;
  const AssetRemoteCompanion({
    this.assetId = const drift.Value.absent(),
    this.url = const drift.Value.absent(),
    this.meta = const drift.Value.absent(),
    this.autoUpdateInterval = const drift.Value.absent(),
    this.downloadedFilePath = const drift.Value.absent(),
    this.checkedAt = const drift.Value.absent(),
  });
  AssetRemoteCompanion.insert({
    this.assetId = const drift.Value.absent(),
    required String url,
    this.meta = const drift.Value.absent(),
    required int autoUpdateInterval,
    this.downloadedFilePath = const drift.Value.absent(),
    this.checkedAt = const drift.Value.absent(),
  }) : url = drift.Value(url),
       autoUpdateInterval = drift.Value(autoUpdateInterval);
  static drift.Insertable<AssetRemoteData> custom({
    drift.Expression<int>? assetId,
    drift.Expression<String>? url,
    drift.Expression<String>? meta,
    drift.Expression<int>? autoUpdateInterval,
    drift.Expression<String>? downloadedFilePath,
    drift.Expression<DateTime>? checkedAt,
  }) {
    return drift.RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (url != null) 'url': url,
      if (meta != null) 'meta': meta,
      if (autoUpdateInterval != null)
        'auto_update_interval': autoUpdateInterval,
      if (downloadedFilePath != null)
        'downloaded_file_path': downloadedFilePath,
      if (checkedAt != null) 'checked_at': checkedAt,
    });
  }

  AssetRemoteCompanion copyWith({
    drift.Value<int>? assetId,
    drift.Value<String>? url,
    drift.Value<String>? meta,
    drift.Value<int>? autoUpdateInterval,
    drift.Value<String?>? downloadedFilePath,
    drift.Value<DateTime?>? checkedAt,
  }) {
    return AssetRemoteCompanion(
      assetId: assetId ?? this.assetId,
      url: url ?? this.url,
      meta: meta ?? this.meta,
      autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (assetId.present) {
      map['asset_id'] = drift.Variable<int>(assetId.value);
    }
    if (url.present) {
      map['url'] = drift.Variable<String>(url.value);
    }
    if (meta.present) {
      map['meta'] = drift.Variable<String>(meta.value);
    }
    if (autoUpdateInterval.present) {
      map['auto_update_interval'] = drift.Variable<int>(
        autoUpdateInterval.value,
      );
    }
    if (downloadedFilePath.present) {
      map['downloaded_file_path'] = drift.Variable<String>(
        downloadedFilePath.value,
      );
    }
    if (checkedAt.present) {
      map['checked_at'] = drift.Variable<DateTime>(checkedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetRemoteCompanion(')
          ..write('assetId: $assetId, ')
          ..write('url: $url, ')
          ..write('meta: $meta, ')
          ..write('autoUpdateInterval: $autoUpdateInterval, ')
          ..write('downloadedFilePath: $downloadedFilePath, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }
}

class $CoreTypeTable extends CoreType
    with drift.TableInfo<$CoreTypeTable, CoreTypeData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoreTypeTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const drift.VerificationMeta _nameMeta = const drift.VerificationMeta(
    'name',
  );
  @override
  late final drift.GeneratedColumn<String> name = drift.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'core_type';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<CoreTypeData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  CoreTypeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoreTypeData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CoreTypeTable createAlias(String alias) {
    return $CoreTypeTable(attachedDatabase, alias);
  }
}

class CoreTypeData extends drift.DataClass
    implements drift.Insertable<CoreTypeData> {
  final int id;
  final String name;
  const CoreTypeData({required this.id, required this.name});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    map['name'] = drift.Variable<String>(name);
    return map;
  }

  CoreTypeCompanion toCompanion(bool nullToAbsent) {
    return CoreTypeCompanion(id: drift.Value(id), name: drift.Value(name));
  }

  factory CoreTypeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return CoreTypeData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  CoreTypeData copyWith({int? id, String? name}) =>
      CoreTypeData(id: id ?? this.id, name: name ?? this.name);
  CoreTypeData copyWithCompanion(CoreTypeCompanion data) {
    return CoreTypeData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoreTypeData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreTypeData && other.id == this.id && other.name == this.name);
}

class CoreTypeCompanion extends drift.UpdateCompanion<CoreTypeData> {
  final drift.Value<int> id;
  final drift.Value<String> name;
  const CoreTypeCompanion({
    this.id = const drift.Value.absent(),
    this.name = const drift.Value.absent(),
  });
  CoreTypeCompanion.insert({
    this.id = const drift.Value.absent(),
    required String name,
  }) : name = drift.Value(name);
  static drift.Insertable<CoreTypeData> custom({
    drift.Expression<int>? id,
    drift.Expression<String>? name,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  CoreTypeCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<String>? name,
  }) {
    return CoreTypeCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = drift.Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoreTypeCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $CoreTable extends Core with drift.TableInfo<$CoreTable, CoreData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoreTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const drift.VerificationMeta _coreTypeIdMeta =
      const drift.VerificationMeta('coreTypeId');
  @override
  late final drift.GeneratedColumn<int> coreTypeId = drift.GeneratedColumn<int>(
    'core_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES core_type (id) ON DELETE CASCADE',
    ),
  );
  static const drift.VerificationMeta _versionMeta =
      const drift.VerificationMeta('version');
  @override
  late final drift.GeneratedColumn<String> version =
      drift.GeneratedColumn<String>(
        'version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const drift.VerificationMeta _updatedAtMeta =
      const drift.VerificationMeta('updatedAt');
  @override
  late final drift.GeneratedColumn<DateTime> updatedAt =
      drift.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const drift.VerificationMeta _isExecMeta =
      const drift.VerificationMeta('isExec');
  @override
  late final drift.GeneratedColumn<bool> isExec = drift.GeneratedColumn<bool>(
    'is_exec',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_exec" IN (0, 1))',
    ),
    defaultValue: const drift.Constant(true),
  );
  static const drift.VerificationMeta _workingDirMeta =
      const drift.VerificationMeta('workingDir');
  @override
  late final drift.GeneratedColumn<String> workingDir =
      drift.GeneratedColumn<String>(
        'working_dir',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const drift.VerificationMeta _envsMeta = const drift.VerificationMeta(
    'envs',
  );
  @override
  late final drift.GeneratedColumn<String> envs = drift.GeneratedColumn<String>(
    'envs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const drift.Constant("{}"),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [
    id,
    coreTypeId,
    version,
    updatedAt,
    isExec,
    workingDir,
    envs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'core';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<CoreData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('core_type_id')) {
      context.handle(
        _coreTypeIdMeta,
        coreTypeId.isAcceptableOrUnknown(
          data['core_type_id']!,
          _coreTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coreTypeIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_exec')) {
      context.handle(
        _isExecMeta,
        isExec.isAcceptableOrUnknown(data['is_exec']!, _isExecMeta),
      );
    }
    if (data.containsKey('working_dir')) {
      context.handle(
        _workingDirMeta,
        workingDir.isAcceptableOrUnknown(data['working_dir']!, _workingDirMeta),
      );
    }
    if (data.containsKey('envs')) {
      context.handle(
        _envsMeta,
        envs.isAcceptableOrUnknown(data['envs']!, _envsMeta),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  CoreData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoreData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      coreTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}core_type_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isExec: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_exec'],
      )!,
      workingDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}working_dir'],
      ),
      envs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envs'],
      )!,
    );
  }

  @override
  $CoreTable createAlias(String alias) {
    return $CoreTable(attachedDatabase, alias);
  }
}

class CoreData extends drift.DataClass implements drift.Insertable<CoreData> {
  final int id;

  /// V2Ray, Xray, sing-box
  final int coreTypeId;
  final String? version;
  final DateTime updatedAt;
  final bool isExec;
  final String? workingDir;
  final String envs;
  const CoreData({
    required this.id,
    required this.coreTypeId,
    this.version,
    required this.updatedAt,
    required this.isExec,
    this.workingDir,
    required this.envs,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    map['core_type_id'] = drift.Variable<int>(coreTypeId);
    if (!nullToAbsent || version != null) {
      map['version'] = drift.Variable<String>(version);
    }
    map['updated_at'] = drift.Variable<DateTime>(updatedAt);
    map['is_exec'] = drift.Variable<bool>(isExec);
    if (!nullToAbsent || workingDir != null) {
      map['working_dir'] = drift.Variable<String>(workingDir);
    }
    map['envs'] = drift.Variable<String>(envs);
    return map;
  }

  CoreCompanion toCompanion(bool nullToAbsent) {
    return CoreCompanion(
      id: drift.Value(id),
      coreTypeId: drift.Value(coreTypeId),
      version: version == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(version),
      updatedAt: drift.Value(updatedAt),
      isExec: drift.Value(isExec),
      workingDir: workingDir == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(workingDir),
      envs: drift.Value(envs),
    );
  }

  factory CoreData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return CoreData(
      id: serializer.fromJson<int>(json['id']),
      coreTypeId: serializer.fromJson<int>(json['coreTypeId']),
      version: serializer.fromJson<String?>(json['version']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isExec: serializer.fromJson<bool>(json['isExec']),
      workingDir: serializer.fromJson<String?>(json['workingDir']),
      envs: serializer.fromJson<String>(json['envs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'coreTypeId': serializer.toJson<int>(coreTypeId),
      'version': serializer.toJson<String?>(version),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isExec': serializer.toJson<bool>(isExec),
      'workingDir': serializer.toJson<String?>(workingDir),
      'envs': serializer.toJson<String>(envs),
    };
  }

  CoreData copyWith({
    int? id,
    int? coreTypeId,
    drift.Value<String?> version = const drift.Value.absent(),
    DateTime? updatedAt,
    bool? isExec,
    drift.Value<String?> workingDir = const drift.Value.absent(),
    String? envs,
  }) => CoreData(
    id: id ?? this.id,
    coreTypeId: coreTypeId ?? this.coreTypeId,
    version: version.present ? version.value : this.version,
    updatedAt: updatedAt ?? this.updatedAt,
    isExec: isExec ?? this.isExec,
    workingDir: workingDir.present ? workingDir.value : this.workingDir,
    envs: envs ?? this.envs,
  );
  CoreData copyWithCompanion(CoreCompanion data) {
    return CoreData(
      id: data.id.present ? data.id.value : this.id,
      coreTypeId: data.coreTypeId.present
          ? data.coreTypeId.value
          : this.coreTypeId,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isExec: data.isExec.present ? data.isExec.value : this.isExec,
      workingDir: data.workingDir.present
          ? data.workingDir.value
          : this.workingDir,
      envs: data.envs.present ? data.envs.value : this.envs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoreData(')
          ..write('id: $id, ')
          ..write('coreTypeId: $coreTypeId, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isExec: $isExec, ')
          ..write('workingDir: $workingDir, ')
          ..write('envs: $envs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, coreTypeId, version, updatedAt, isExec, workingDir, envs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreData &&
          other.id == this.id &&
          other.coreTypeId == this.coreTypeId &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.isExec == this.isExec &&
          other.workingDir == this.workingDir &&
          other.envs == this.envs);
}

class CoreCompanion extends drift.UpdateCompanion<CoreData> {
  final drift.Value<int> id;
  final drift.Value<int> coreTypeId;
  final drift.Value<String?> version;
  final drift.Value<DateTime> updatedAt;
  final drift.Value<bool> isExec;
  final drift.Value<String?> workingDir;
  final drift.Value<String> envs;
  const CoreCompanion({
    this.id = const drift.Value.absent(),
    this.coreTypeId = const drift.Value.absent(),
    this.version = const drift.Value.absent(),
    this.updatedAt = const drift.Value.absent(),
    this.isExec = const drift.Value.absent(),
    this.workingDir = const drift.Value.absent(),
    this.envs = const drift.Value.absent(),
  });
  CoreCompanion.insert({
    this.id = const drift.Value.absent(),
    required int coreTypeId,
    this.version = const drift.Value.absent(),
    required DateTime updatedAt,
    this.isExec = const drift.Value.absent(),
    this.workingDir = const drift.Value.absent(),
    this.envs = const drift.Value.absent(),
  }) : coreTypeId = drift.Value(coreTypeId),
       updatedAt = drift.Value(updatedAt);
  static drift.Insertable<CoreData> custom({
    drift.Expression<int>? id,
    drift.Expression<int>? coreTypeId,
    drift.Expression<String>? version,
    drift.Expression<DateTime>? updatedAt,
    drift.Expression<bool>? isExec,
    drift.Expression<String>? workingDir,
    drift.Expression<String>? envs,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (coreTypeId != null) 'core_type_id': coreTypeId,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isExec != null) 'is_exec': isExec,
      if (workingDir != null) 'working_dir': workingDir,
      if (envs != null) 'envs': envs,
    });
  }

  CoreCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<int>? coreTypeId,
    drift.Value<String?>? version,
    drift.Value<DateTime>? updatedAt,
    drift.Value<bool>? isExec,
    drift.Value<String?>? workingDir,
    drift.Value<String>? envs,
  }) {
    return CoreCompanion(
      id: id ?? this.id,
      coreTypeId: coreTypeId ?? this.coreTypeId,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      isExec: isExec ?? this.isExec,
      workingDir: workingDir ?? this.workingDir,
      envs: envs ?? this.envs,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (coreTypeId.present) {
      map['core_type_id'] = drift.Variable<int>(coreTypeId.value);
    }
    if (version.present) {
      map['version'] = drift.Variable<String>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = drift.Variable<DateTime>(updatedAt.value);
    }
    if (isExec.present) {
      map['is_exec'] = drift.Variable<bool>(isExec.value);
    }
    if (workingDir.present) {
      map['working_dir'] = drift.Variable<String>(workingDir.value);
    }
    if (envs.present) {
      map['envs'] = drift.Variable<String>(envs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoreCompanion(')
          ..write('id: $id, ')
          ..write('coreTypeId: $coreTypeId, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isExec: $isExec, ')
          ..write('workingDir: $workingDir, ')
          ..write('envs: $envs')
          ..write(')'))
        .toString();
  }
}

class $CoreExecTable extends CoreExec
    with drift.TableInfo<$CoreExecTable, CoreExecData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoreExecTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _coreIdMeta =
      const drift.VerificationMeta('coreId');
  @override
  late final drift.GeneratedColumn<int> coreId = drift.GeneratedColumn<int>(
    'core_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES core (id) ON DELETE CASCADE',
    ),
  );
  static const drift.VerificationMeta _argsMeta = const drift.VerificationMeta(
    'args',
  );
  @override
  late final drift.GeneratedColumn<String> args = drift.GeneratedColumn<String>(
    'args',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const drift.Constant(""),
  );
  static const drift.VerificationMeta _assetIdMeta =
      const drift.VerificationMeta('assetId');
  @override
  late final drift.GeneratedColumn<int> assetId = drift.GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [coreId, args, assetId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'core_exec';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<CoreExecData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('core_id')) {
      context.handle(
        _coreIdMeta,
        coreId.isAcceptableOrUnknown(data['core_id']!, _coreIdMeta),
      );
    }
    if (data.containsKey('args')) {
      context.handle(
        _argsMeta,
        args.isAcceptableOrUnknown(data['args']!, _argsMeta),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {coreId};
  @override
  CoreExecData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoreExecData(
      coreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}core_id'],
      )!,
      args: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}args'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
    );
  }

  @override
  $CoreExecTable createAlias(String alias) {
    return $CoreExecTable(attachedDatabase, alias);
  }
}

class CoreExecData extends drift.DataClass
    implements drift.Insertable<CoreExecData> {
  final int coreId;
  final String args;
  final int assetId;
  const CoreExecData({
    required this.coreId,
    required this.args,
    required this.assetId,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['core_id'] = drift.Variable<int>(coreId);
    map['args'] = drift.Variable<String>(args);
    map['asset_id'] = drift.Variable<int>(assetId);
    return map;
  }

  CoreExecCompanion toCompanion(bool nullToAbsent) {
    return CoreExecCompanion(
      coreId: drift.Value(coreId),
      args: drift.Value(args),
      assetId: drift.Value(assetId),
    );
  }

  factory CoreExecData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return CoreExecData(
      coreId: serializer.fromJson<int>(json['coreId']),
      args: serializer.fromJson<String>(json['args']),
      assetId: serializer.fromJson<int>(json['assetId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coreId': serializer.toJson<int>(coreId),
      'args': serializer.toJson<String>(args),
      'assetId': serializer.toJson<int>(assetId),
    };
  }

  CoreExecData copyWith({int? coreId, String? args, int? assetId}) =>
      CoreExecData(
        coreId: coreId ?? this.coreId,
        args: args ?? this.args,
        assetId: assetId ?? this.assetId,
      );
  CoreExecData copyWithCompanion(CoreExecCompanion data) {
    return CoreExecData(
      coreId: data.coreId.present ? data.coreId.value : this.coreId,
      args: data.args.present ? data.args.value : this.args,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoreExecData(')
          ..write('coreId: $coreId, ')
          ..write('args: $args, ')
          ..write('assetId: $assetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(coreId, args, assetId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreExecData &&
          other.coreId == this.coreId &&
          other.args == this.args &&
          other.assetId == this.assetId);
}

class CoreExecCompanion extends drift.UpdateCompanion<CoreExecData> {
  final drift.Value<int> coreId;
  final drift.Value<String> args;
  final drift.Value<int> assetId;
  const CoreExecCompanion({
    this.coreId = const drift.Value.absent(),
    this.args = const drift.Value.absent(),
    this.assetId = const drift.Value.absent(),
  });
  CoreExecCompanion.insert({
    this.coreId = const drift.Value.absent(),
    this.args = const drift.Value.absent(),
    required int assetId,
  }) : assetId = drift.Value(assetId);
  static drift.Insertable<CoreExecData> custom({
    drift.Expression<int>? coreId,
    drift.Expression<String>? args,
    drift.Expression<int>? assetId,
  }) {
    return drift.RawValuesInsertable({
      if (coreId != null) 'core_id': coreId,
      if (args != null) 'args': args,
      if (assetId != null) 'asset_id': assetId,
    });
  }

  CoreExecCompanion copyWith({
    drift.Value<int>? coreId,
    drift.Value<String>? args,
    drift.Value<int>? assetId,
  }) {
    return CoreExecCompanion(
      coreId: coreId ?? this.coreId,
      args: args ?? this.args,
      assetId: assetId ?? this.assetId,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (coreId.present) {
      map['core_id'] = drift.Variable<int>(coreId.value);
    }
    if (args.present) {
      map['args'] = drift.Variable<String>(args.value);
    }
    if (assetId.present) {
      map['asset_id'] = drift.Variable<int>(assetId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoreExecCompanion(')
          ..write('coreId: $coreId, ')
          ..write('args: $args, ')
          ..write('assetId: $assetId')
          ..write(')'))
        .toString();
  }
}

class $CoreLibTable extends CoreLib
    with drift.TableInfo<$CoreLibTable, CoreLibData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoreLibTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _coreIdMeta =
      const drift.VerificationMeta('coreId');
  @override
  late final drift.GeneratedColumn<int> coreId = drift.GeneratedColumn<int>(
    'core_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES core (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [coreId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'core_lib';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<CoreLibData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('core_id')) {
      context.handle(
        _coreIdMeta,
        coreId.isAcceptableOrUnknown(data['core_id']!, _coreIdMeta),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {coreId};
  @override
  CoreLibData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoreLibData(
      coreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}core_id'],
      )!,
    );
  }

  @override
  $CoreLibTable createAlias(String alias) {
    return $CoreLibTable(attachedDatabase, alias);
  }
}

class CoreLibData extends drift.DataClass
    implements drift.Insertable<CoreLibData> {
  final int coreId;
  const CoreLibData({required this.coreId});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['core_id'] = drift.Variable<int>(coreId);
    return map;
  }

  CoreLibCompanion toCompanion(bool nullToAbsent) {
    return CoreLibCompanion(coreId: drift.Value(coreId));
  }

  factory CoreLibData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return CoreLibData(coreId: serializer.fromJson<int>(json['coreId']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'coreId': serializer.toJson<int>(coreId)};
  }

  CoreLibData copyWith({int? coreId}) =>
      CoreLibData(coreId: coreId ?? this.coreId);
  CoreLibData copyWithCompanion(CoreLibCompanion data) {
    return CoreLibData(
      coreId: data.coreId.present ? data.coreId.value : this.coreId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoreLibData(')
          ..write('coreId: $coreId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => coreId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreLibData && other.coreId == this.coreId);
}

class CoreLibCompanion extends drift.UpdateCompanion<CoreLibData> {
  final drift.Value<int> coreId;
  const CoreLibCompanion({this.coreId = const drift.Value.absent()});
  CoreLibCompanion.insert({this.coreId = const drift.Value.absent()});
  static drift.Insertable<CoreLibData> custom({drift.Expression<int>? coreId}) {
    return drift.RawValuesInsertable({if (coreId != null) 'core_id': coreId});
  }

  CoreLibCompanion copyWith({drift.Value<int>? coreId}) {
    return CoreLibCompanion(coreId: coreId ?? this.coreId);
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (coreId.present) {
      map['core_id'] = drift.Variable<int>(coreId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoreLibCompanion(')
          ..write('coreId: $coreId')
          ..write(')'))
        .toString();
  }
}

class $CoreTypeSelectedTable extends CoreTypeSelected
    with drift.TableInfo<$CoreTypeSelectedTable, CoreTypeSelectedData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoreTypeSelectedTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _coreTypeIdMeta =
      const drift.VerificationMeta('coreTypeId');
  @override
  late final drift.GeneratedColumn<int> coreTypeId = drift.GeneratedColumn<int>(
    'core_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES core_type (id) ON DELETE CASCADE',
    ),
  );
  static const drift.VerificationMeta _coreIdMeta =
      const drift.VerificationMeta('coreId');
  @override
  late final drift.GeneratedColumn<int> coreId = drift.GeneratedColumn<int>(
    'core_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES core (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [coreTypeId, coreId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'core_type_selected';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<CoreTypeSelectedData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('core_type_id')) {
      context.handle(
        _coreTypeIdMeta,
        coreTypeId.isAcceptableOrUnknown(
          data['core_type_id']!,
          _coreTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('core_id')) {
      context.handle(
        _coreIdMeta,
        coreId.isAcceptableOrUnknown(data['core_id']!, _coreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_coreIdMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {coreTypeId};
  @override
  CoreTypeSelectedData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoreTypeSelectedData(
      coreTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}core_type_id'],
      )!,
      coreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}core_id'],
      )!,
    );
  }

  @override
  $CoreTypeSelectedTable createAlias(String alias) {
    return $CoreTypeSelectedTable(attachedDatabase, alias);
  }
}

class CoreTypeSelectedData extends drift.DataClass
    implements drift.Insertable<CoreTypeSelectedData> {
  final int coreTypeId;
  final int coreId;
  const CoreTypeSelectedData({required this.coreTypeId, required this.coreId});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['core_type_id'] = drift.Variable<int>(coreTypeId);
    map['core_id'] = drift.Variable<int>(coreId);
    return map;
  }

  CoreTypeSelectedCompanion toCompanion(bool nullToAbsent) {
    return CoreTypeSelectedCompanion(
      coreTypeId: drift.Value(coreTypeId),
      coreId: drift.Value(coreId),
    );
  }

  factory CoreTypeSelectedData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return CoreTypeSelectedData(
      coreTypeId: serializer.fromJson<int>(json['coreTypeId']),
      coreId: serializer.fromJson<int>(json['coreId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coreTypeId': serializer.toJson<int>(coreTypeId),
      'coreId': serializer.toJson<int>(coreId),
    };
  }

  CoreTypeSelectedData copyWith({int? coreTypeId, int? coreId}) =>
      CoreTypeSelectedData(
        coreTypeId: coreTypeId ?? this.coreTypeId,
        coreId: coreId ?? this.coreId,
      );
  CoreTypeSelectedData copyWithCompanion(CoreTypeSelectedCompanion data) {
    return CoreTypeSelectedData(
      coreTypeId: data.coreTypeId.present
          ? data.coreTypeId.value
          : this.coreTypeId,
      coreId: data.coreId.present ? data.coreId.value : this.coreId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoreTypeSelectedData(')
          ..write('coreTypeId: $coreTypeId, ')
          ..write('coreId: $coreId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(coreTypeId, coreId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreTypeSelectedData &&
          other.coreTypeId == this.coreTypeId &&
          other.coreId == this.coreId);
}

class CoreTypeSelectedCompanion
    extends drift.UpdateCompanion<CoreTypeSelectedData> {
  final drift.Value<int> coreTypeId;
  final drift.Value<int> coreId;
  const CoreTypeSelectedCompanion({
    this.coreTypeId = const drift.Value.absent(),
    this.coreId = const drift.Value.absent(),
  });
  CoreTypeSelectedCompanion.insert({
    this.coreTypeId = const drift.Value.absent(),
    required int coreId,
  }) : coreId = drift.Value(coreId);
  static drift.Insertable<CoreTypeSelectedData> custom({
    drift.Expression<int>? coreTypeId,
    drift.Expression<int>? coreId,
  }) {
    return drift.RawValuesInsertable({
      if (coreTypeId != null) 'core_type_id': coreTypeId,
      if (coreId != null) 'core_id': coreId,
    });
  }

  CoreTypeSelectedCompanion copyWith({
    drift.Value<int>? coreTypeId,
    drift.Value<int>? coreId,
  }) {
    return CoreTypeSelectedCompanion(
      coreTypeId: coreTypeId ?? this.coreTypeId,
      coreId: coreId ?? this.coreId,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (coreTypeId.present) {
      map['core_type_id'] = drift.Variable<int>(coreTypeId.value);
    }
    if (coreId.present) {
      map['core_id'] = drift.Variable<int>(coreId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoreTypeSelectedCompanion(')
          ..write('coreTypeId: $coreTypeId, ')
          ..write('coreId: $coreId')
          ..write(')'))
        .toString();
  }
}

class $ProfileGroupTable extends ProfileGroup
    with drift.TableInfo<$ProfileGroupTable, ProfileGroupData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileGroupTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const drift.VerificationMeta _nameMeta = const drift.VerificationMeta(
    'name',
  );
  @override
  late final drift.GeneratedColumn<String> name = drift.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const drift.VerificationMeta _updatedAtMeta =
      const drift.VerificationMeta('updatedAt');
  @override
  late final drift.GeneratedColumn<DateTime> updatedAt =
      drift.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  late final drift.GeneratedColumnWithTypeConverter<ProfileGroupType, int>
  type = drift.GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<ProfileGroupType>($ProfileGroupTable.$convertertype);
  static const drift.VerificationMeta _coreTypeIdMeta =
      const drift.VerificationMeta('coreTypeId');
  @override
  late final drift.GeneratedColumn<int> coreTypeId = drift.GeneratedColumn<int>(
    'core_type_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES core_type (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [
    id,
    name,
    updatedAt,
    type,
    coreTypeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_group';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<ProfileGroupData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('core_type_id')) {
      context.handle(
        _coreTypeIdMeta,
        coreTypeId.isAcceptableOrUnknown(
          data['core_type_id']!,
          _coreTypeIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileGroupData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileGroupData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      type: $ProfileGroupTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      coreTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}core_type_id'],
      ),
    );
  }

  @override
  $ProfileGroupTable createAlias(String alias) {
    return $ProfileGroupTable(attachedDatabase, alias);
  }

  static drift.TypeConverter<ProfileGroupType, int> $convertertype =
      const ProfileGroupTypeConverter();
}

class ProfileGroupData extends drift.DataClass
    implements drift.Insertable<ProfileGroupData> {
  final int id;
  final String name;
  final DateTime updatedAt;
  final ProfileGroupType type;
  final int? coreTypeId;
  const ProfileGroupData({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.type,
    this.coreTypeId,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    map['name'] = drift.Variable<String>(name);
    map['updated_at'] = drift.Variable<DateTime>(updatedAt);
    {
      map['type'] = drift.Variable<int>(
        $ProfileGroupTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || coreTypeId != null) {
      map['core_type_id'] = drift.Variable<int>(coreTypeId);
    }
    return map;
  }

  ProfileGroupCompanion toCompanion(bool nullToAbsent) {
    return ProfileGroupCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      updatedAt: drift.Value(updatedAt),
      type: drift.Value(type),
      coreTypeId: coreTypeId == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(coreTypeId),
    );
  }

  factory ProfileGroupData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return ProfileGroupData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      type: serializer.fromJson<ProfileGroupType>(json['type']),
      coreTypeId: serializer.fromJson<int?>(json['coreTypeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'type': serializer.toJson<ProfileGroupType>(type),
      'coreTypeId': serializer.toJson<int?>(coreTypeId),
    };
  }

  ProfileGroupData copyWith({
    int? id,
    String? name,
    DateTime? updatedAt,
    ProfileGroupType? type,
    drift.Value<int?> coreTypeId = const drift.Value.absent(),
  }) => ProfileGroupData(
    id: id ?? this.id,
    name: name ?? this.name,
    updatedAt: updatedAt ?? this.updatedAt,
    type: type ?? this.type,
    coreTypeId: coreTypeId.present ? coreTypeId.value : this.coreTypeId,
  );
  ProfileGroupData copyWithCompanion(ProfileGroupCompanion data) {
    return ProfileGroupData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      type: data.type.present ? data.type.value : this.type,
      coreTypeId: data.coreTypeId.present
          ? data.coreTypeId.value
          : this.coreTypeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('coreTypeId: $coreTypeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, updatedAt, type, coreTypeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileGroupData &&
          other.id == this.id &&
          other.name == this.name &&
          other.updatedAt == this.updatedAt &&
          other.type == this.type &&
          other.coreTypeId == this.coreTypeId);
}

class ProfileGroupCompanion extends drift.UpdateCompanion<ProfileGroupData> {
  final drift.Value<int> id;
  final drift.Value<String> name;
  final drift.Value<DateTime> updatedAt;
  final drift.Value<ProfileGroupType> type;
  final drift.Value<int?> coreTypeId;
  const ProfileGroupCompanion({
    this.id = const drift.Value.absent(),
    this.name = const drift.Value.absent(),
    this.updatedAt = const drift.Value.absent(),
    this.type = const drift.Value.absent(),
    this.coreTypeId = const drift.Value.absent(),
  });
  ProfileGroupCompanion.insert({
    this.id = const drift.Value.absent(),
    required String name,
    required DateTime updatedAt,
    required ProfileGroupType type,
    this.coreTypeId = const drift.Value.absent(),
  }) : name = drift.Value(name),
       updatedAt = drift.Value(updatedAt),
       type = drift.Value(type);
  static drift.Insertable<ProfileGroupData> custom({
    drift.Expression<int>? id,
    drift.Expression<String>? name,
    drift.Expression<DateTime>? updatedAt,
    drift.Expression<int>? type,
    drift.Expression<int>? coreTypeId,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (type != null) 'type': type,
      if (coreTypeId != null) 'core_type_id': coreTypeId,
    });
  }

  ProfileGroupCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<String>? name,
    drift.Value<DateTime>? updatedAt,
    drift.Value<ProfileGroupType>? type,
    drift.Value<int?>? coreTypeId,
  }) {
    return ProfileGroupCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      coreTypeId: coreTypeId ?? this.coreTypeId,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = drift.Variable<String>(name.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = drift.Variable<DateTime>(updatedAt.value);
    }
    if (type.present) {
      map['type'] = drift.Variable<int>(
        $ProfileGroupTable.$convertertype.toSql(type.value),
      );
    }
    if (coreTypeId.present) {
      map['core_type_id'] = drift.Variable<int>(coreTypeId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('coreTypeId: $coreTypeId')
          ..write(')'))
        .toString();
  }
}

class $ProfileTable extends Profile
    with drift.TableInfo<$ProfileTable, ProfileData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const drift.VerificationMeta _nameMeta = const drift.VerificationMeta(
    'name',
  );
  @override
  late final drift.GeneratedColumn<String> name = drift.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const drift.VerificationMeta _keyMeta = const drift.VerificationMeta(
    'key',
  );
  @override
  late final drift.GeneratedColumn<String> key = drift.GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const drift.VerificationMeta _coreTypeIdMeta =
      const drift.VerificationMeta('coreTypeId');
  @override
  late final drift.GeneratedColumn<int> coreTypeId = drift.GeneratedColumn<int>(
    'core_type_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES core_type (id) ON DELETE CASCADE',
    ),
  );
  static const drift.VerificationMeta _coreCfgMeta =
      const drift.VerificationMeta('coreCfg');
  @override
  late final drift.GeneratedColumn<String> coreCfg =
      drift.GeneratedColumn<String>(
        'core_cfg',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const drift.Constant("{}"),
      );
  static const drift.VerificationMeta _coreCfgFmtMeta =
      const drift.VerificationMeta('coreCfgFmt');
  @override
  late final drift.GeneratedColumn<String> coreCfgFmt =
      drift.GeneratedColumn<String>(
        'core_cfg_fmt',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const drift.Constant("json"),
      );
  static const drift.VerificationMeta _updatedAtMeta =
      const drift.VerificationMeta('updatedAt');
  @override
  late final drift.GeneratedColumn<DateTime> updatedAt =
      drift.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  late final drift.GeneratedColumnWithTypeConverter<ProfileType, int> type =
      drift.GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ProfileType>($ProfileTable.$convertertype);
  static const drift.VerificationMeta _profileGroupIdMeta =
      const drift.VerificationMeta('profileGroupId');
  @override
  late final drift.GeneratedColumn<int> profileGroupId =
      drift.GeneratedColumn<int>(
        'profile_group_id',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profile_group (id)',
        ),
        defaultValue: const drift.Constant(1),
      );
  static const drift.VerificationMeta _httpingMeta =
      const drift.VerificationMeta('httping');
  @override
  late final drift.GeneratedColumn<int> httping = drift.GeneratedColumn<int>(
    'httping',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<drift.GeneratedColumn> get $columns => [
    id,
    name,
    key,
    coreTypeId,
    coreCfg,
    coreCfgFmt,
    updatedAt,
    type,
    profileGroupId,
    httping,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<ProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('core_type_id')) {
      context.handle(
        _coreTypeIdMeta,
        coreTypeId.isAcceptableOrUnknown(
          data['core_type_id']!,
          _coreTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('core_cfg')) {
      context.handle(
        _coreCfgMeta,
        coreCfg.isAcceptableOrUnknown(data['core_cfg']!, _coreCfgMeta),
      );
    }
    if (data.containsKey('core_cfg_fmt')) {
      context.handle(
        _coreCfgFmtMeta,
        coreCfgFmt.isAcceptableOrUnknown(
          data['core_cfg_fmt']!,
          _coreCfgFmtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('profile_group_id')) {
      context.handle(
        _profileGroupIdMeta,
        profileGroupId.isAcceptableOrUnknown(
          data['profile_group_id']!,
          _profileGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('httping')) {
      context.handle(
        _httpingMeta,
        httping.isAcceptableOrUnknown(data['httping']!, _httpingMeta),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      coreTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}core_type_id'],
      ),
      coreCfg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}core_cfg'],
      )!,
      coreCfgFmt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}core_cfg_fmt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      type: $ProfileTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      profileGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_group_id'],
      )!,
      httping: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}httping'],
      ),
    );
  }

  @override
  $ProfileTable createAlias(String alias) {
    return $ProfileTable(attachedDatabase, alias);
  }

  static drift.TypeConverter<ProfileType, int> $convertertype =
      const ProfileTypeConverter();
}

class ProfileData extends drift.DataClass
    implements drift.Insertable<ProfileData> {
  final int id;
  final String name;
  final String key;
  final int? coreTypeId;
  final String coreCfg;
  final String coreCfgFmt;
  final DateTime updatedAt;
  final ProfileType type;
  final int profileGroupId;
  final int? httping;
  const ProfileData({
    required this.id,
    required this.name,
    required this.key,
    this.coreTypeId,
    required this.coreCfg,
    required this.coreCfgFmt,
    required this.updatedAt,
    required this.type,
    required this.profileGroupId,
    this.httping,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    map['name'] = drift.Variable<String>(name);
    map['key'] = drift.Variable<String>(key);
    if (!nullToAbsent || coreTypeId != null) {
      map['core_type_id'] = drift.Variable<int>(coreTypeId);
    }
    map['core_cfg'] = drift.Variable<String>(coreCfg);
    map['core_cfg_fmt'] = drift.Variable<String>(coreCfgFmt);
    map['updated_at'] = drift.Variable<DateTime>(updatedAt);
    {
      map['type'] = drift.Variable<int>(
        $ProfileTable.$convertertype.toSql(type),
      );
    }
    map['profile_group_id'] = drift.Variable<int>(profileGroupId);
    if (!nullToAbsent || httping != null) {
      map['httping'] = drift.Variable<int>(httping);
    }
    return map;
  }

  ProfileCompanion toCompanion(bool nullToAbsent) {
    return ProfileCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      key: drift.Value(key),
      coreTypeId: coreTypeId == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(coreTypeId),
      coreCfg: drift.Value(coreCfg),
      coreCfgFmt: drift.Value(coreCfgFmt),
      updatedAt: drift.Value(updatedAt),
      type: drift.Value(type),
      profileGroupId: drift.Value(profileGroupId),
      httping: httping == null && nullToAbsent
          ? const drift.Value.absent()
          : drift.Value(httping),
    );
  }

  factory ProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return ProfileData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      key: serializer.fromJson<String>(json['key']),
      coreTypeId: serializer.fromJson<int?>(json['coreTypeId']),
      coreCfg: serializer.fromJson<String>(json['coreCfg']),
      coreCfgFmt: serializer.fromJson<String>(json['coreCfgFmt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      type: serializer.fromJson<ProfileType>(json['type']),
      profileGroupId: serializer.fromJson<int>(json['profileGroupId']),
      httping: serializer.fromJson<int?>(json['httping']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'key': serializer.toJson<String>(key),
      'coreTypeId': serializer.toJson<int?>(coreTypeId),
      'coreCfg': serializer.toJson<String>(coreCfg),
      'coreCfgFmt': serializer.toJson<String>(coreCfgFmt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'type': serializer.toJson<ProfileType>(type),
      'profileGroupId': serializer.toJson<int>(profileGroupId),
      'httping': serializer.toJson<int?>(httping),
    };
  }

  ProfileData copyWith({
    int? id,
    String? name,
    String? key,
    drift.Value<int?> coreTypeId = const drift.Value.absent(),
    String? coreCfg,
    String? coreCfgFmt,
    DateTime? updatedAt,
    ProfileType? type,
    int? profileGroupId,
    drift.Value<int?> httping = const drift.Value.absent(),
  }) => ProfileData(
    id: id ?? this.id,
    name: name ?? this.name,
    key: key ?? this.key,
    coreTypeId: coreTypeId.present ? coreTypeId.value : this.coreTypeId,
    coreCfg: coreCfg ?? this.coreCfg,
    coreCfgFmt: coreCfgFmt ?? this.coreCfgFmt,
    updatedAt: updatedAt ?? this.updatedAt,
    type: type ?? this.type,
    profileGroupId: profileGroupId ?? this.profileGroupId,
    httping: httping.present ? httping.value : this.httping,
  );
  ProfileData copyWithCompanion(ProfileCompanion data) {
    return ProfileData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      key: data.key.present ? data.key.value : this.key,
      coreTypeId: data.coreTypeId.present
          ? data.coreTypeId.value
          : this.coreTypeId,
      coreCfg: data.coreCfg.present ? data.coreCfg.value : this.coreCfg,
      coreCfgFmt: data.coreCfgFmt.present
          ? data.coreCfgFmt.value
          : this.coreCfgFmt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      type: data.type.present ? data.type.value : this.type,
      profileGroupId: data.profileGroupId.present
          ? data.profileGroupId.value
          : this.profileGroupId,
      httping: data.httping.present ? data.httping.value : this.httping,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('key: $key, ')
          ..write('coreTypeId: $coreTypeId, ')
          ..write('coreCfg: $coreCfg, ')
          ..write('coreCfgFmt: $coreCfgFmt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('profileGroupId: $profileGroupId, ')
          ..write('httping: $httping')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    key,
    coreTypeId,
    coreCfg,
    coreCfgFmt,
    updatedAt,
    type,
    profileGroupId,
    httping,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileData &&
          other.id == this.id &&
          other.name == this.name &&
          other.key == this.key &&
          other.coreTypeId == this.coreTypeId &&
          other.coreCfg == this.coreCfg &&
          other.coreCfgFmt == this.coreCfgFmt &&
          other.updatedAt == this.updatedAt &&
          other.type == this.type &&
          other.profileGroupId == this.profileGroupId &&
          other.httping == this.httping);
}

class ProfileCompanion extends drift.UpdateCompanion<ProfileData> {
  final drift.Value<int> id;
  final drift.Value<String> name;
  final drift.Value<String> key;
  final drift.Value<int?> coreTypeId;
  final drift.Value<String> coreCfg;
  final drift.Value<String> coreCfgFmt;
  final drift.Value<DateTime> updatedAt;
  final drift.Value<ProfileType> type;
  final drift.Value<int> profileGroupId;
  final drift.Value<int?> httping;
  const ProfileCompanion({
    this.id = const drift.Value.absent(),
    this.name = const drift.Value.absent(),
    this.key = const drift.Value.absent(),
    this.coreTypeId = const drift.Value.absent(),
    this.coreCfg = const drift.Value.absent(),
    this.coreCfgFmt = const drift.Value.absent(),
    this.updatedAt = const drift.Value.absent(),
    this.type = const drift.Value.absent(),
    this.profileGroupId = const drift.Value.absent(),
    this.httping = const drift.Value.absent(),
  });
  ProfileCompanion.insert({
    this.id = const drift.Value.absent(),
    required String name,
    required String key,
    this.coreTypeId = const drift.Value.absent(),
    this.coreCfg = const drift.Value.absent(),
    this.coreCfgFmt = const drift.Value.absent(),
    required DateTime updatedAt,
    required ProfileType type,
    this.profileGroupId = const drift.Value.absent(),
    this.httping = const drift.Value.absent(),
  }) : name = drift.Value(name),
       key = drift.Value(key),
       updatedAt = drift.Value(updatedAt),
       type = drift.Value(type);
  static drift.Insertable<ProfileData> custom({
    drift.Expression<int>? id,
    drift.Expression<String>? name,
    drift.Expression<String>? key,
    drift.Expression<int>? coreTypeId,
    drift.Expression<String>? coreCfg,
    drift.Expression<String>? coreCfgFmt,
    drift.Expression<DateTime>? updatedAt,
    drift.Expression<int>? type,
    drift.Expression<int>? profileGroupId,
    drift.Expression<int>? httping,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (key != null) 'key': key,
      if (coreTypeId != null) 'core_type_id': coreTypeId,
      if (coreCfg != null) 'core_cfg': coreCfg,
      if (coreCfgFmt != null) 'core_cfg_fmt': coreCfgFmt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (type != null) 'type': type,
      if (profileGroupId != null) 'profile_group_id': profileGroupId,
      if (httping != null) 'httping': httping,
    });
  }

  ProfileCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<String>? name,
    drift.Value<String>? key,
    drift.Value<int?>? coreTypeId,
    drift.Value<String>? coreCfg,
    drift.Value<String>? coreCfgFmt,
    drift.Value<DateTime>? updatedAt,
    drift.Value<ProfileType>? type,
    drift.Value<int>? profileGroupId,
    drift.Value<int?>? httping,
  }) {
    return ProfileCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      key: key ?? this.key,
      coreTypeId: coreTypeId ?? this.coreTypeId,
      coreCfg: coreCfg ?? this.coreCfg,
      coreCfgFmt: coreCfgFmt ?? this.coreCfgFmt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      profileGroupId: profileGroupId ?? this.profileGroupId,
      httping: httping ?? this.httping,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = drift.Variable<String>(name.value);
    }
    if (key.present) {
      map['key'] = drift.Variable<String>(key.value);
    }
    if (coreTypeId.present) {
      map['core_type_id'] = drift.Variable<int>(coreTypeId.value);
    }
    if (coreCfg.present) {
      map['core_cfg'] = drift.Variable<String>(coreCfg.value);
    }
    if (coreCfgFmt.present) {
      map['core_cfg_fmt'] = drift.Variable<String>(coreCfgFmt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = drift.Variable<DateTime>(updatedAt.value);
    }
    if (type.present) {
      map['type'] = drift.Variable<int>(
        $ProfileTable.$convertertype.toSql(type.value),
      );
    }
    if (profileGroupId.present) {
      map['profile_group_id'] = drift.Variable<int>(profileGroupId.value);
    }
    if (httping.present) {
      map['httping'] = drift.Variable<int>(httping.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('key: $key, ')
          ..write('coreTypeId: $coreTypeId, ')
          ..write('coreCfg: $coreCfg, ')
          ..write('coreCfgFmt: $coreCfgFmt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('profileGroupId: $profileGroupId, ')
          ..write('httping: $httping')
          ..write(')'))
        .toString();
  }
}

class $ProfileLocalTable extends ProfileLocal
    with drift.TableInfo<$ProfileLocalTable, ProfileLocalData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileLocalTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _profileIdMeta =
      const drift.VerificationMeta('profileId');
  @override
  late final drift.GeneratedColumn<int> profileId = drift.GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profile (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<drift.GeneratedColumn> get $columns => [profileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_local';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<ProfileLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {profileId};
  @override
  ProfileLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileLocalData(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
    );
  }

  @override
  $ProfileLocalTable createAlias(String alias) {
    return $ProfileLocalTable(attachedDatabase, alias);
  }
}

class ProfileLocalData extends drift.DataClass
    implements drift.Insertable<ProfileLocalData> {
  final int profileId;
  const ProfileLocalData({required this.profileId});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['profile_id'] = drift.Variable<int>(profileId);
    return map;
  }

  ProfileLocalCompanion toCompanion(bool nullToAbsent) {
    return ProfileLocalCompanion(profileId: drift.Value(profileId));
  }

  factory ProfileLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return ProfileLocalData(
      profileId: serializer.fromJson<int>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'profileId': serializer.toJson<int>(profileId)};
  }

  ProfileLocalData copyWith({int? profileId}) =>
      ProfileLocalData(profileId: profileId ?? this.profileId);
  ProfileLocalData copyWithCompanion(ProfileLocalCompanion data) {
    return ProfileLocalData(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileLocalData(')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => profileId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileLocalData && other.profileId == this.profileId);
}

class ProfileLocalCompanion extends drift.UpdateCompanion<ProfileLocalData> {
  final drift.Value<int> profileId;
  const ProfileLocalCompanion({this.profileId = const drift.Value.absent()});
  ProfileLocalCompanion.insert({this.profileId = const drift.Value.absent()});
  static drift.Insertable<ProfileLocalData> custom({
    drift.Expression<int>? profileId,
  }) {
    return drift.RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
    });
  }

  ProfileLocalCompanion copyWith({drift.Value<int>? profileId}) {
    return ProfileLocalCompanion(profileId: profileId ?? this.profileId);
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (profileId.present) {
      map['profile_id'] = drift.Variable<int>(profileId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileLocalCompanion(')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }
}

class $ProfileRemoteTable extends ProfileRemote
    with drift.TableInfo<$ProfileRemoteTable, ProfileRemoteData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileRemoteTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _profileIdMeta =
      const drift.VerificationMeta('profileId');
  @override
  late final drift.GeneratedColumn<int> profileId = drift.GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profile (id) ON DELETE CASCADE',
    ),
  );
  static const drift.VerificationMeta _urlMeta = const drift.VerificationMeta(
    'url',
  );
  @override
  late final drift.GeneratedColumn<String> url = drift.GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const drift.VerificationMeta _autoUpdateIntervalMeta =
      const drift.VerificationMeta('autoUpdateInterval');
  @override
  late final drift.GeneratedColumn<int> autoUpdateInterval =
      drift.GeneratedColumn<int>(
        'auto_update_interval',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [
    profileId,
    url,
    autoUpdateInterval,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_remote';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<ProfileRemoteData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('auto_update_interval')) {
      context.handle(
        _autoUpdateIntervalMeta,
        autoUpdateInterval.isAcceptableOrUnknown(
          data['auto_update_interval']!,
          _autoUpdateIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoUpdateIntervalMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {profileId};
  @override
  ProfileRemoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRemoteData(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      autoUpdateInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_update_interval'],
      )!,
    );
  }

  @override
  $ProfileRemoteTable createAlias(String alias) {
    return $ProfileRemoteTable(attachedDatabase, alias);
  }
}

class ProfileRemoteData extends drift.DataClass
    implements drift.Insertable<ProfileRemoteData> {
  final int profileId;
  final String url;
  final int autoUpdateInterval;
  const ProfileRemoteData({
    required this.profileId,
    required this.url,
    required this.autoUpdateInterval,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['profile_id'] = drift.Variable<int>(profileId);
    map['url'] = drift.Variable<String>(url);
    map['auto_update_interval'] = drift.Variable<int>(autoUpdateInterval);
    return map;
  }

  ProfileRemoteCompanion toCompanion(bool nullToAbsent) {
    return ProfileRemoteCompanion(
      profileId: drift.Value(profileId),
      url: drift.Value(url),
      autoUpdateInterval: drift.Value(autoUpdateInterval),
    );
  }

  factory ProfileRemoteData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return ProfileRemoteData(
      profileId: serializer.fromJson<int>(json['profileId']),
      url: serializer.fromJson<String>(json['url']),
      autoUpdateInterval: serializer.fromJson<int>(json['autoUpdateInterval']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'url': serializer.toJson<String>(url),
      'autoUpdateInterval': serializer.toJson<int>(autoUpdateInterval),
    };
  }

  ProfileRemoteData copyWith({
    int? profileId,
    String? url,
    int? autoUpdateInterval,
  }) => ProfileRemoteData(
    profileId: profileId ?? this.profileId,
    url: url ?? this.url,
    autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
  );
  ProfileRemoteData copyWithCompanion(ProfileRemoteCompanion data) {
    return ProfileRemoteData(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      url: data.url.present ? data.url.value : this.url,
      autoUpdateInterval: data.autoUpdateInterval.present
          ? data.autoUpdateInterval.value
          : this.autoUpdateInterval,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRemoteData(')
          ..write('profileId: $profileId, ')
          ..write('url: $url, ')
          ..write('autoUpdateInterval: $autoUpdateInterval')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, url, autoUpdateInterval);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRemoteData &&
          other.profileId == this.profileId &&
          other.url == this.url &&
          other.autoUpdateInterval == this.autoUpdateInterval);
}

class ProfileRemoteCompanion extends drift.UpdateCompanion<ProfileRemoteData> {
  final drift.Value<int> profileId;
  final drift.Value<String> url;
  final drift.Value<int> autoUpdateInterval;
  const ProfileRemoteCompanion({
    this.profileId = const drift.Value.absent(),
    this.url = const drift.Value.absent(),
    this.autoUpdateInterval = const drift.Value.absent(),
  });
  ProfileRemoteCompanion.insert({
    this.profileId = const drift.Value.absent(),
    required String url,
    required int autoUpdateInterval,
  }) : url = drift.Value(url),
       autoUpdateInterval = drift.Value(autoUpdateInterval);
  static drift.Insertable<ProfileRemoteData> custom({
    drift.Expression<int>? profileId,
    drift.Expression<String>? url,
    drift.Expression<int>? autoUpdateInterval,
  }) {
    return drift.RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (url != null) 'url': url,
      if (autoUpdateInterval != null)
        'auto_update_interval': autoUpdateInterval,
    });
  }

  ProfileRemoteCompanion copyWith({
    drift.Value<int>? profileId,
    drift.Value<String>? url,
    drift.Value<int>? autoUpdateInterval,
  }) {
    return ProfileRemoteCompanion(
      profileId: profileId ?? this.profileId,
      url: url ?? this.url,
      autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (profileId.present) {
      map['profile_id'] = drift.Variable<int>(profileId.value);
    }
    if (url.present) {
      map['url'] = drift.Variable<String>(url.value);
    }
    if (autoUpdateInterval.present) {
      map['auto_update_interval'] = drift.Variable<int>(
        autoUpdateInterval.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRemoteCompanion(')
          ..write('profileId: $profileId, ')
          ..write('url: $url, ')
          ..write('autoUpdateInterval: $autoUpdateInterval')
          ..write(')'))
        .toString();
  }
}

class $ProfileGroupLocalTable extends ProfileGroupLocal
    with drift.TableInfo<$ProfileGroupLocalTable, ProfileGroupLocalData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileGroupLocalTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _profileGroupIdMeta =
      const drift.VerificationMeta('profileGroupId');
  @override
  late final drift.GeneratedColumn<int> profileGroupId =
      drift.GeneratedColumn<int>(
        'profile_group_id',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profile_group (id) ON DELETE CASCADE',
        ),
      );
  @override
  List<drift.GeneratedColumn> get $columns => [profileGroupId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_group_local';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<ProfileGroupLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_group_id')) {
      context.handle(
        _profileGroupIdMeta,
        profileGroupId.isAcceptableOrUnknown(
          data['profile_group_id']!,
          _profileGroupIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {profileGroupId};
  @override
  ProfileGroupLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileGroupLocalData(
      profileGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_group_id'],
      )!,
    );
  }

  @override
  $ProfileGroupLocalTable createAlias(String alias) {
    return $ProfileGroupLocalTable(attachedDatabase, alias);
  }
}

class ProfileGroupLocalData extends drift.DataClass
    implements drift.Insertable<ProfileGroupLocalData> {
  final int profileGroupId;
  const ProfileGroupLocalData({required this.profileGroupId});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['profile_group_id'] = drift.Variable<int>(profileGroupId);
    return map;
  }

  ProfileGroupLocalCompanion toCompanion(bool nullToAbsent) {
    return ProfileGroupLocalCompanion(
      profileGroupId: drift.Value(profileGroupId),
    );
  }

  factory ProfileGroupLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return ProfileGroupLocalData(
      profileGroupId: serializer.fromJson<int>(json['profileGroupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileGroupId': serializer.toJson<int>(profileGroupId),
    };
  }

  ProfileGroupLocalData copyWith({int? profileGroupId}) =>
      ProfileGroupLocalData(
        profileGroupId: profileGroupId ?? this.profileGroupId,
      );
  ProfileGroupLocalData copyWithCompanion(ProfileGroupLocalCompanion data) {
    return ProfileGroupLocalData(
      profileGroupId: data.profileGroupId.present
          ? data.profileGroupId.value
          : this.profileGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupLocalData(')
          ..write('profileGroupId: $profileGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => profileGroupId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileGroupLocalData &&
          other.profileGroupId == this.profileGroupId);
}

class ProfileGroupLocalCompanion
    extends drift.UpdateCompanion<ProfileGroupLocalData> {
  final drift.Value<int> profileGroupId;
  const ProfileGroupLocalCompanion({
    this.profileGroupId = const drift.Value.absent(),
  });
  ProfileGroupLocalCompanion.insert({
    this.profileGroupId = const drift.Value.absent(),
  });
  static drift.Insertable<ProfileGroupLocalData> custom({
    drift.Expression<int>? profileGroupId,
  }) {
    return drift.RawValuesInsertable({
      if (profileGroupId != null) 'profile_group_id': profileGroupId,
    });
  }

  ProfileGroupLocalCompanion copyWith({drift.Value<int>? profileGroupId}) {
    return ProfileGroupLocalCompanion(
      profileGroupId: profileGroupId ?? this.profileGroupId,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (profileGroupId.present) {
      map['profile_group_id'] = drift.Variable<int>(profileGroupId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupLocalCompanion(')
          ..write('profileGroupId: $profileGroupId')
          ..write(')'))
        .toString();
  }
}

class $ProfileGroupRemoteTable extends ProfileGroupRemote
    with drift.TableInfo<$ProfileGroupRemoteTable, ProfileGroupRemoteData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileGroupRemoteTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _profileGroupIdMeta =
      const drift.VerificationMeta('profileGroupId');
  @override
  late final drift.GeneratedColumn<int> profileGroupId =
      drift.GeneratedColumn<int>(
        'profile_group_id',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profile_group (id) ON DELETE CASCADE',
        ),
      );
  static const drift.VerificationMeta _urlMeta = const drift.VerificationMeta(
    'url',
  );
  @override
  late final drift.GeneratedColumn<String> url = drift.GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final drift.GeneratedColumnWithTypeConverter<
    ProfileGroupRemoteProtocol,
    int
  >
  protocol =
      drift.GeneratedColumn<int>(
        'protocol',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ProfileGroupRemoteProtocol>(
        $ProfileGroupRemoteTable.$converterprotocol,
      );
  static const drift.VerificationMeta _autoUpdateIntervalMeta =
      const drift.VerificationMeta('autoUpdateInterval');
  @override
  late final drift.GeneratedColumn<int> autoUpdateInterval =
      drift.GeneratedColumn<int>(
        'auto_update_interval',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [
    profileGroupId,
    url,
    protocol,
    autoUpdateInterval,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_group_remote';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<ProfileGroupRemoteData> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_group_id')) {
      context.handle(
        _profileGroupIdMeta,
        profileGroupId.isAcceptableOrUnknown(
          data['profile_group_id']!,
          _profileGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('auto_update_interval')) {
      context.handle(
        _autoUpdateIntervalMeta,
        autoUpdateInterval.isAcceptableOrUnknown(
          data['auto_update_interval']!,
          _autoUpdateIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoUpdateIntervalMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {profileGroupId};
  @override
  ProfileGroupRemoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileGroupRemoteData(
      profileGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_group_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      protocol: $ProfileGroupRemoteTable.$converterprotocol.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}protocol'],
        )!,
      ),
      autoUpdateInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_update_interval'],
      )!,
    );
  }

  @override
  $ProfileGroupRemoteTable createAlias(String alias) {
    return $ProfileGroupRemoteTable(attachedDatabase, alias);
  }

  static drift.TypeConverter<ProfileGroupRemoteProtocol, int>
  $converterprotocol = const ProfileGroupRemoteProtocolConverter();
}

class ProfileGroupRemoteData extends drift.DataClass
    implements drift.Insertable<ProfileGroupRemoteData> {
  final int profileGroupId;
  final String url;
  final ProfileGroupRemoteProtocol protocol;
  final int autoUpdateInterval;
  const ProfileGroupRemoteData({
    required this.profileGroupId,
    required this.url,
    required this.protocol,
    required this.autoUpdateInterval,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['profile_group_id'] = drift.Variable<int>(profileGroupId);
    map['url'] = drift.Variable<String>(url);
    {
      map['protocol'] = drift.Variable<int>(
        $ProfileGroupRemoteTable.$converterprotocol.toSql(protocol),
      );
    }
    map['auto_update_interval'] = drift.Variable<int>(autoUpdateInterval);
    return map;
  }

  ProfileGroupRemoteCompanion toCompanion(bool nullToAbsent) {
    return ProfileGroupRemoteCompanion(
      profileGroupId: drift.Value(profileGroupId),
      url: drift.Value(url),
      protocol: drift.Value(protocol),
      autoUpdateInterval: drift.Value(autoUpdateInterval),
    );
  }

  factory ProfileGroupRemoteData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return ProfileGroupRemoteData(
      profileGroupId: serializer.fromJson<int>(json['profileGroupId']),
      url: serializer.fromJson<String>(json['url']),
      protocol: serializer.fromJson<ProfileGroupRemoteProtocol>(
        json['protocol'],
      ),
      autoUpdateInterval: serializer.fromJson<int>(json['autoUpdateInterval']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileGroupId': serializer.toJson<int>(profileGroupId),
      'url': serializer.toJson<String>(url),
      'protocol': serializer.toJson<ProfileGroupRemoteProtocol>(protocol),
      'autoUpdateInterval': serializer.toJson<int>(autoUpdateInterval),
    };
  }

  ProfileGroupRemoteData copyWith({
    int? profileGroupId,
    String? url,
    ProfileGroupRemoteProtocol? protocol,
    int? autoUpdateInterval,
  }) => ProfileGroupRemoteData(
    profileGroupId: profileGroupId ?? this.profileGroupId,
    url: url ?? this.url,
    protocol: protocol ?? this.protocol,
    autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
  );
  ProfileGroupRemoteData copyWithCompanion(ProfileGroupRemoteCompanion data) {
    return ProfileGroupRemoteData(
      profileGroupId: data.profileGroupId.present
          ? data.profileGroupId.value
          : this.profileGroupId,
      url: data.url.present ? data.url.value : this.url,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      autoUpdateInterval: data.autoUpdateInterval.present
          ? data.autoUpdateInterval.value
          : this.autoUpdateInterval,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupRemoteData(')
          ..write('profileGroupId: $profileGroupId, ')
          ..write('url: $url, ')
          ..write('protocol: $protocol, ')
          ..write('autoUpdateInterval: $autoUpdateInterval')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(profileGroupId, url, protocol, autoUpdateInterval);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileGroupRemoteData &&
          other.profileGroupId == this.profileGroupId &&
          other.url == this.url &&
          other.protocol == this.protocol &&
          other.autoUpdateInterval == this.autoUpdateInterval);
}

class ProfileGroupRemoteCompanion
    extends drift.UpdateCompanion<ProfileGroupRemoteData> {
  final drift.Value<int> profileGroupId;
  final drift.Value<String> url;
  final drift.Value<ProfileGroupRemoteProtocol> protocol;
  final drift.Value<int> autoUpdateInterval;
  const ProfileGroupRemoteCompanion({
    this.profileGroupId = const drift.Value.absent(),
    this.url = const drift.Value.absent(),
    this.protocol = const drift.Value.absent(),
    this.autoUpdateInterval = const drift.Value.absent(),
  });
  ProfileGroupRemoteCompanion.insert({
    this.profileGroupId = const drift.Value.absent(),
    required String url,
    required ProfileGroupRemoteProtocol protocol,
    required int autoUpdateInterval,
  }) : url = drift.Value(url),
       protocol = drift.Value(protocol),
       autoUpdateInterval = drift.Value(autoUpdateInterval);
  static drift.Insertable<ProfileGroupRemoteData> custom({
    drift.Expression<int>? profileGroupId,
    drift.Expression<String>? url,
    drift.Expression<int>? protocol,
    drift.Expression<int>? autoUpdateInterval,
  }) {
    return drift.RawValuesInsertable({
      if (profileGroupId != null) 'profile_group_id': profileGroupId,
      if (url != null) 'url': url,
      if (protocol != null) 'protocol': protocol,
      if (autoUpdateInterval != null)
        'auto_update_interval': autoUpdateInterval,
    });
  }

  ProfileGroupRemoteCompanion copyWith({
    drift.Value<int>? profileGroupId,
    drift.Value<String>? url,
    drift.Value<ProfileGroupRemoteProtocol>? protocol,
    drift.Value<int>? autoUpdateInterval,
  }) {
    return ProfileGroupRemoteCompanion(
      profileGroupId: profileGroupId ?? this.profileGroupId,
      url: url ?? this.url,
      protocol: protocol ?? this.protocol,
      autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (profileGroupId.present) {
      map['profile_group_id'] = drift.Variable<int>(profileGroupId.value);
    }
    if (url.present) {
      map['url'] = drift.Variable<String>(url.value);
    }
    if (protocol.present) {
      map['protocol'] = drift.Variable<int>(
        $ProfileGroupRemoteTable.$converterprotocol.toSql(protocol.value),
      );
    }
    if (autoUpdateInterval.present) {
      map['auto_update_interval'] = drift.Variable<int>(
        autoUpdateInterval.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupRemoteCompanion(')
          ..write('profileGroupId: $profileGroupId, ')
          ..write('url: $url, ')
          ..write('protocol: $protocol, ')
          ..write('autoUpdateInterval: $autoUpdateInterval')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends drift.GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $AssetTable asset = $AssetTable(this);
  late final $AssetLocalTable assetLocal = $AssetLocalTable(this);
  late final $AssetRemoteTable assetRemote = $AssetRemoteTable(this);
  late final $CoreTypeTable coreType = $CoreTypeTable(this);
  late final $CoreTable core = $CoreTable(this);
  late final $CoreExecTable coreExec = $CoreExecTable(this);
  late final $CoreLibTable coreLib = $CoreLibTable(this);
  late final $CoreTypeSelectedTable coreTypeSelected = $CoreTypeSelectedTable(
    this,
  );
  late final $ProfileGroupTable profileGroup = $ProfileGroupTable(this);
  late final $ProfileTable profile = $ProfileTable(this);
  late final $ProfileLocalTable profileLocal = $ProfileLocalTable(this);
  late final $ProfileRemoteTable profileRemote = $ProfileRemoteTable(this);
  late final $ProfileGroupLocalTable profileGroupLocal =
      $ProfileGroupLocalTable(this);
  late final $ProfileGroupRemoteTable profileGroupRemote =
      $ProfileGroupRemoteTable(this);
  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<drift.TableInfo<drift.Table, Object?>>();
  @override
  List<drift.DatabaseSchemaEntity> get allSchemaEntities => [
    asset,
    assetLocal,
    assetRemote,
    coreType,
    core,
    coreExec,
    coreLib,
    coreTypeSelected,
    profileGroup,
    profile,
    profileLocal,
    profileRemote,
    profileGroupLocal,
    profileGroupRemote,
  ];
  @override
  drift.StreamQueryUpdateRules
  get streamUpdateRules => const StreamQueryUpdateRules([
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'asset',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [drift.TableUpdate('asset_local', kind: drift.UpdateKind.delete)],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'asset',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate('asset_remote', kind: drift.UpdateKind.delete),
      ],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'core_type',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [drift.TableUpdate('core', kind: drift.UpdateKind.delete)],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'core',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [drift.TableUpdate('core_exec', kind: drift.UpdateKind.delete)],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'asset',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [drift.TableUpdate('core_exec', kind: drift.UpdateKind.delete)],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'core',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [drift.TableUpdate('core_lib', kind: drift.UpdateKind.delete)],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'core_type',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate('core_type_selected', kind: drift.UpdateKind.delete),
      ],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'core',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate('core_type_selected', kind: drift.UpdateKind.delete),
      ],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'core_type',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate('profile_group', kind: drift.UpdateKind.delete),
      ],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'core_type',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [drift.TableUpdate('profile', kind: drift.UpdateKind.delete)],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'profile',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate('profile_local', kind: drift.UpdateKind.delete),
      ],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'profile',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate('profile_remote', kind: drift.UpdateKind.delete),
      ],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'profile_group',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate('profile_group_local', kind: drift.UpdateKind.delete),
      ],
    ),
    drift.WritePropagation(
      on: drift.TableUpdateQuery.onTableName(
        'profile_group',
        limitUpdateKind: drift.UpdateKind.delete,
      ),
      result: [
        drift.TableUpdate(
          'profile_group_remote',
          kind: drift.UpdateKind.delete,
        ),
      ],
    ),
  ]);
}

typedef $$AssetTableCreateCompanionBuilder =
    AssetCompanion Function({
      drift.Value<int> id,
      drift.Value<String?> name,
      required AssetType type,
      required String path,
      required DateTime updatedAt,
    });
typedef $$AssetTableUpdateCompanionBuilder =
    AssetCompanion Function({
      drift.Value<int> id,
      drift.Value<String?> name,
      drift.Value<AssetType> type,
      drift.Value<String> path,
      drift.Value<DateTime> updatedAt,
    });

final class $$AssetTableReferences
    extends drift.BaseReferences<_$Database, $AssetTable, AssetData> {
  $$AssetTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static drift.MultiTypedResultKey<$AssetLocalTable, List<AssetLocalData>>
  _assetLocalRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.assetLocal,
    aliasName: drift.$_aliasNameGenerator(db.asset.id, db.assetLocal.assetId),
  );

  $$AssetLocalTableProcessedTableManager get assetLocalRefs {
    final manager = $$AssetLocalTableTableManager(
      $_db,
      $_db.assetLocal,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetLocalRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<$AssetRemoteTable, List<AssetRemoteData>>
  _assetRemoteRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.assetRemote,
    aliasName: drift.$_aliasNameGenerator(db.asset.id, db.assetRemote.assetId),
  );

  $$AssetRemoteTableProcessedTableManager get assetRemoteRefs {
    final manager = $$AssetRemoteTableTableManager(
      $_db,
      $_db.assetRemote,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetRemoteRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<$CoreExecTable, List<CoreExecData>>
  _coreExecRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.coreExec,
    aliasName: drift.$_aliasNameGenerator(db.asset.id, db.coreExec.assetId),
  );

  $$CoreExecTableProcessedTableManager get coreExecRefs {
    final manager = $$CoreExecTableTableManager(
      $_db,
      $_db.coreExec,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_coreExecRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetTableFilterComposer
    extends drift.Composer<_$Database, $AssetTable> {
  $$AssetTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnWithTypeConverterFilters<AssetType, AssetType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => drift.ColumnWithTypeConverterFilters(column),
      );

  drift.ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.Expression<bool> assetLocalRefs(
    drift.Expression<bool> Function($$AssetLocalTableFilterComposer f) f,
  ) {
    final $$AssetLocalTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetLocal,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetLocalTableFilterComposer(
            $db: $db,
            $table: $db.assetLocal,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> assetRemoteRefs(
    drift.Expression<bool> Function($$AssetRemoteTableFilterComposer f) f,
  ) {
    final $$AssetRemoteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetRemote,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetRemoteTableFilterComposer(
            $db: $db,
            $table: $db.assetRemote,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> coreExecRefs(
    drift.Expression<bool> Function($$CoreExecTableFilterComposer f) f,
  ) {
    final $$CoreExecTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreExec,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreExecTableFilterComposer(
            $db: $db,
            $table: $db.coreExec,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetTableOrderingComposer
    extends drift.Composer<_$Database, $AssetTable> {
  $$AssetTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnOrderings(column),
  );
}

class $$AssetTableAnnotationComposer
    extends drift.Composer<_$Database, $AssetTable> {
  $$AssetTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  drift.GeneratedColumnWithTypeConverter<AssetType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  drift.GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  drift.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  drift.Expression<T> assetLocalRefs<T extends Object>(
    drift.Expression<T> Function($$AssetLocalTableAnnotationComposer a) f,
  ) {
    final $$AssetLocalTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetLocal,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetLocalTableAnnotationComposer(
            $db: $db,
            $table: $db.assetLocal,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> assetRemoteRefs<T extends Object>(
    drift.Expression<T> Function($$AssetRemoteTableAnnotationComposer a) f,
  ) {
    final $$AssetRemoteTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetRemote,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetRemoteTableAnnotationComposer(
            $db: $db,
            $table: $db.assetRemote,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> coreExecRefs<T extends Object>(
    drift.Expression<T> Function($$CoreExecTableAnnotationComposer a) f,
  ) {
    final $$CoreExecTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreExec,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreExecTableAnnotationComposer(
            $db: $db,
            $table: $db.coreExec,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $AssetTable,
          AssetData,
          $$AssetTableFilterComposer,
          $$AssetTableOrderingComposer,
          $$AssetTableAnnotationComposer,
          $$AssetTableCreateCompanionBuilder,
          $$AssetTableUpdateCompanionBuilder,
          (AssetData, $$AssetTableReferences),
          AssetData,
          drift.PrefetchHooks Function({
            bool assetLocalRefs,
            bool assetRemoteRefs,
            bool coreExecRefs,
          })
        > {
  $$AssetTableTableManager(_$Database db, $AssetTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String?> name = const drift.Value.absent(),
                drift.Value<AssetType> type = const drift.Value.absent(),
                drift.Value<String> path = const drift.Value.absent(),
                drift.Value<DateTime> updatedAt = const drift.Value.absent(),
              }) => AssetCompanion(
                id: id,
                name: name,
                type: type,
                path: path,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String?> name = const drift.Value.absent(),
                required AssetType type,
                required String path,
                required DateTime updatedAt,
              }) => AssetCompanion.insert(
                id: id,
                name: name,
                type: type,
                path: path,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AssetTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assetLocalRefs = false,
                assetRemoteRefs = false,
                coreExecRefs = false,
              }) {
                return drift.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assetLocalRefs) db.assetLocal,
                    if (assetRemoteRefs) db.assetRemote,
                    if (coreExecRefs) db.coreExec,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assetLocalRefs)
                        await drift.$_getPrefetchedData<
                          AssetData,
                          $AssetTable,
                          AssetLocalData
                        >(
                          currentTable: table,
                          referencedTable: $$AssetTableReferences
                              ._assetLocalRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetTableReferences(
                                db,
                                table,
                                p0,
                              ).assetLocalRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetRemoteRefs)
                        await drift.$_getPrefetchedData<
                          AssetData,
                          $AssetTable,
                          AssetRemoteData
                        >(
                          currentTable: table,
                          referencedTable: $$AssetTableReferences
                              ._assetRemoteRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetTableReferences(
                                db,
                                table,
                                p0,
                              ).assetRemoteRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (coreExecRefs)
                        await drift.$_getPrefetchedData<
                          AssetData,
                          $AssetTable,
                          CoreExecData
                        >(
                          currentTable: table,
                          referencedTable: $$AssetTableReferences
                              ._coreExecRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetTableReferences(
                                db,
                                table,
                                p0,
                              ).coreExecRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AssetTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $AssetTable,
      AssetData,
      $$AssetTableFilterComposer,
      $$AssetTableOrderingComposer,
      $$AssetTableAnnotationComposer,
      $$AssetTableCreateCompanionBuilder,
      $$AssetTableUpdateCompanionBuilder,
      (AssetData, $$AssetTableReferences),
      AssetData,
      drift.PrefetchHooks Function({
        bool assetLocalRefs,
        bool assetRemoteRefs,
        bool coreExecRefs,
      })
    >;
typedef $$AssetLocalTableCreateCompanionBuilder =
    AssetLocalCompanion Function({drift.Value<int> assetId});
typedef $$AssetLocalTableUpdateCompanionBuilder =
    AssetLocalCompanion Function({drift.Value<int> assetId});

final class $$AssetLocalTableReferences
    extends drift.BaseReferences<_$Database, $AssetLocalTable, AssetLocalData> {
  $$AssetLocalTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetTable _assetIdTable(_$Database db) => db.asset.createAlias(
    drift.$_aliasNameGenerator(db.assetLocal.assetId, db.asset.id),
  );

  $$AssetTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetTableTableManager(
      $_db,
      $_db.asset,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetLocalTableFilterComposer
    extends drift.Composer<_$Database, $AssetLocalTable> {
  $$AssetLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AssetTableFilterComposer get assetId {
    final $$AssetTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableFilterComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetLocalTableOrderingComposer
    extends drift.Composer<_$Database, $AssetLocalTable> {
  $$AssetLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AssetTableOrderingComposer get assetId {
    final $$AssetTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableOrderingComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetLocalTableAnnotationComposer
    extends drift.Composer<_$Database, $AssetLocalTable> {
  $$AssetLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AssetTableAnnotationComposer get assetId {
    final $$AssetTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableAnnotationComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetLocalTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $AssetLocalTable,
          AssetLocalData,
          $$AssetLocalTableFilterComposer,
          $$AssetLocalTableOrderingComposer,
          $$AssetLocalTableAnnotationComposer,
          $$AssetLocalTableCreateCompanionBuilder,
          $$AssetLocalTableUpdateCompanionBuilder,
          (AssetLocalData, $$AssetLocalTableReferences),
          AssetLocalData,
          drift.PrefetchHooks Function({bool assetId})
        > {
  $$AssetLocalTableTableManager(_$Database db, $AssetLocalTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({drift.Value<int> assetId = const drift.Value.absent()}) =>
                  AssetLocalCompanion(assetId: assetId),
          createCompanionCallback:
              ({drift.Value<int> assetId = const drift.Value.absent()}) =>
                  AssetLocalCompanion.insert(assetId: assetId),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetLocalTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable: $$AssetLocalTableReferences
                                    ._assetIdTable(db),
                                referencedColumn: $$AssetLocalTableReferences
                                    ._assetIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetLocalTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $AssetLocalTable,
      AssetLocalData,
      $$AssetLocalTableFilterComposer,
      $$AssetLocalTableOrderingComposer,
      $$AssetLocalTableAnnotationComposer,
      $$AssetLocalTableCreateCompanionBuilder,
      $$AssetLocalTableUpdateCompanionBuilder,
      (AssetLocalData, $$AssetLocalTableReferences),
      AssetLocalData,
      drift.PrefetchHooks Function({bool assetId})
    >;
typedef $$AssetRemoteTableCreateCompanionBuilder =
    AssetRemoteCompanion Function({
      drift.Value<int> assetId,
      required String url,
      drift.Value<String> meta,
      required int autoUpdateInterval,
      drift.Value<String?> downloadedFilePath,
      drift.Value<DateTime?> checkedAt,
    });
typedef $$AssetRemoteTableUpdateCompanionBuilder =
    AssetRemoteCompanion Function({
      drift.Value<int> assetId,
      drift.Value<String> url,
      drift.Value<String> meta,
      drift.Value<int> autoUpdateInterval,
      drift.Value<String?> downloadedFilePath,
      drift.Value<DateTime?> checkedAt,
    });

final class $$AssetRemoteTableReferences
    extends
        drift.BaseReferences<_$Database, $AssetRemoteTable, AssetRemoteData> {
  $$AssetRemoteTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetTable _assetIdTable(_$Database db) => db.asset.createAlias(
    drift.$_aliasNameGenerator(db.assetRemote.assetId, db.asset.id),
  );

  $$AssetTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetTableTableManager(
      $_db,
      $_db.asset,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetRemoteTableFilterComposer
    extends drift.Composer<_$Database, $AssetRemoteTable> {
  $$AssetRemoteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get downloadedFilePath => $composableBuilder(
    column: $table.downloadedFilePath,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => drift.ColumnFilters(column),
  );

  $$AssetTableFilterComposer get assetId {
    final $$AssetTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableFilterComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetRemoteTableOrderingComposer
    extends drift.Composer<_$Database, $AssetRemoteTable> {
  $$AssetRemoteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get downloadedFilePath => $composableBuilder(
    column: $table.downloadedFilePath,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => drift.ColumnOrderings(column),
  );

  $$AssetTableOrderingComposer get assetId {
    final $$AssetTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableOrderingComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetRemoteTableAnnotationComposer
    extends drift.Composer<_$Database, $AssetRemoteTable> {
  $$AssetRemoteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  drift.GeneratedColumn<String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);

  drift.GeneratedColumn<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => column,
  );

  drift.GeneratedColumn<String> get downloadedFilePath => $composableBuilder(
    column: $table.downloadedFilePath,
    builder: (column) => column,
  );

  drift.GeneratedColumn<DateTime> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  $$AssetTableAnnotationComposer get assetId {
    final $$AssetTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableAnnotationComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetRemoteTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $AssetRemoteTable,
          AssetRemoteData,
          $$AssetRemoteTableFilterComposer,
          $$AssetRemoteTableOrderingComposer,
          $$AssetRemoteTableAnnotationComposer,
          $$AssetRemoteTableCreateCompanionBuilder,
          $$AssetRemoteTableUpdateCompanionBuilder,
          (AssetRemoteData, $$AssetRemoteTableReferences),
          AssetRemoteData,
          drift.PrefetchHooks Function({bool assetId})
        > {
  $$AssetRemoteTableTableManager(_$Database db, $AssetRemoteTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetRemoteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetRemoteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetRemoteTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> assetId = const drift.Value.absent(),
                drift.Value<String> url = const drift.Value.absent(),
                drift.Value<String> meta = const drift.Value.absent(),
                drift.Value<int> autoUpdateInterval =
                    const drift.Value.absent(),
                drift.Value<String?> downloadedFilePath =
                    const drift.Value.absent(),
                drift.Value<DateTime?> checkedAt = const drift.Value.absent(),
              }) => AssetRemoteCompanion(
                assetId: assetId,
                url: url,
                meta: meta,
                autoUpdateInterval: autoUpdateInterval,
                downloadedFilePath: downloadedFilePath,
                checkedAt: checkedAt,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> assetId = const drift.Value.absent(),
                required String url,
                drift.Value<String> meta = const drift.Value.absent(),
                required int autoUpdateInterval,
                drift.Value<String?> downloadedFilePath =
                    const drift.Value.absent(),
                drift.Value<DateTime?> checkedAt = const drift.Value.absent(),
              }) => AssetRemoteCompanion.insert(
                assetId: assetId,
                url: url,
                meta: meta,
                autoUpdateInterval: autoUpdateInterval,
                downloadedFilePath: downloadedFilePath,
                checkedAt: checkedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetRemoteTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable: $$AssetRemoteTableReferences
                                    ._assetIdTable(db),
                                referencedColumn: $$AssetRemoteTableReferences
                                    ._assetIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetRemoteTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $AssetRemoteTable,
      AssetRemoteData,
      $$AssetRemoteTableFilterComposer,
      $$AssetRemoteTableOrderingComposer,
      $$AssetRemoteTableAnnotationComposer,
      $$AssetRemoteTableCreateCompanionBuilder,
      $$AssetRemoteTableUpdateCompanionBuilder,
      (AssetRemoteData, $$AssetRemoteTableReferences),
      AssetRemoteData,
      drift.PrefetchHooks Function({bool assetId})
    >;
typedef $$CoreTypeTableCreateCompanionBuilder =
    CoreTypeCompanion Function({drift.Value<int> id, required String name});
typedef $$CoreTypeTableUpdateCompanionBuilder =
    CoreTypeCompanion Function({drift.Value<int> id, drift.Value<String> name});

final class $$CoreTypeTableReferences
    extends drift.BaseReferences<_$Database, $CoreTypeTable, CoreTypeData> {
  $$CoreTypeTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static drift.MultiTypedResultKey<$CoreTable, List<CoreData>> _coreRefsTable(
    _$Database db,
  ) => drift.MultiTypedResultKey.fromTable(
    db.core,
    aliasName: drift.$_aliasNameGenerator(db.coreType.id, db.core.coreTypeId),
  );

  $$CoreTableProcessedTableManager get coreRefs {
    final manager = $$CoreTableTableManager(
      $_db,
      $_db.core,
    ).filter((f) => f.coreTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_coreRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<
    $CoreTypeSelectedTable,
    List<CoreTypeSelectedData>
  >
  _coreTypeSelectedRefsTable(_$Database db) =>
      drift.MultiTypedResultKey.fromTable(
        db.coreTypeSelected,
        aliasName: drift.$_aliasNameGenerator(
          db.coreType.id,
          db.coreTypeSelected.coreTypeId,
        ),
      );

  $$CoreTypeSelectedTableProcessedTableManager get coreTypeSelectedRefs {
    final manager = $$CoreTypeSelectedTableTableManager(
      $_db,
      $_db.coreTypeSelected,
    ).filter((f) => f.coreTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _coreTypeSelectedRefsTable($_db),
    );
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<$ProfileGroupTable, List<ProfileGroupData>>
  _profileGroupRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.profileGroup,
    aliasName: drift.$_aliasNameGenerator(
      db.coreType.id,
      db.profileGroup.coreTypeId,
    ),
  );

  $$ProfileGroupTableProcessedTableManager get profileGroupRefs {
    final manager = $$ProfileGroupTableTableManager(
      $_db,
      $_db.profileGroup,
    ).filter((f) => f.coreTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileGroupRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<$ProfileTable, List<ProfileData>>
  _profileRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.profile,
    aliasName: drift.$_aliasNameGenerator(
      db.coreType.id,
      db.profile.coreTypeId,
    ),
  );

  $$ProfileTableProcessedTableManager get profileRefs {
    final manager = $$ProfileTableTableManager(
      $_db,
      $_db.profile,
    ).filter((f) => f.coreTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoreTypeTableFilterComposer
    extends drift.Composer<_$Database, $CoreTypeTable> {
  $$CoreTypeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.Expression<bool> coreRefs(
    drift.Expression<bool> Function($$CoreTableFilterComposer f) f,
  ) {
    final $$CoreTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableFilterComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> coreTypeSelectedRefs(
    drift.Expression<bool> Function($$CoreTypeSelectedTableFilterComposer f) f,
  ) {
    final $$CoreTypeSelectedTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreTypeSelected,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeSelectedTableFilterComposer(
            $db: $db,
            $table: $db.coreTypeSelected,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> profileGroupRefs(
    drift.Expression<bool> Function($$ProfileGroupTableFilterComposer f) f,
  ) {
    final $$ProfileGroupTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableFilterComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> profileRefs(
    drift.Expression<bool> Function($$ProfileTableFilterComposer f) f,
  ) {
    final $$ProfileTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableFilterComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoreTypeTableOrderingComposer
    extends drift.Composer<_$Database, $CoreTypeTable> {
  $$CoreTypeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnOrderings(column),
  );
}

class $$CoreTypeTableAnnotationComposer
    extends drift.Composer<_$Database, $CoreTypeTable> {
  $$CoreTypeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  drift.Expression<T> coreRefs<T extends Object>(
    drift.Expression<T> Function($$CoreTableAnnotationComposer a) f,
  ) {
    final $$CoreTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableAnnotationComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> coreTypeSelectedRefs<T extends Object>(
    drift.Expression<T> Function($$CoreTypeSelectedTableAnnotationComposer a) f,
  ) {
    final $$CoreTypeSelectedTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreTypeSelected,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeSelectedTableAnnotationComposer(
            $db: $db,
            $table: $db.coreTypeSelected,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> profileGroupRefs<T extends Object>(
    drift.Expression<T> Function($$ProfileGroupTableAnnotationComposer a) f,
  ) {
    final $$ProfileGroupTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableAnnotationComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> profileRefs<T extends Object>(
    drift.Expression<T> Function($$ProfileTableAnnotationComposer a) f,
  ) {
    final $$ProfileTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.coreTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableAnnotationComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoreTypeTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $CoreTypeTable,
          CoreTypeData,
          $$CoreTypeTableFilterComposer,
          $$CoreTypeTableOrderingComposer,
          $$CoreTypeTableAnnotationComposer,
          $$CoreTypeTableCreateCompanionBuilder,
          $$CoreTypeTableUpdateCompanionBuilder,
          (CoreTypeData, $$CoreTypeTableReferences),
          CoreTypeData,
          drift.PrefetchHooks Function({
            bool coreRefs,
            bool coreTypeSelectedRefs,
            bool profileGroupRefs,
            bool profileRefs,
          })
        > {
  $$CoreTypeTableTableManager(_$Database db, $CoreTypeTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoreTypeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoreTypeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoreTypeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String> name = const drift.Value.absent(),
              }) => CoreTypeCompanion(id: id, name: name),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                required String name,
              }) => CoreTypeCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoreTypeTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                coreRefs = false,
                coreTypeSelectedRefs = false,
                profileGroupRefs = false,
                profileRefs = false,
              }) {
                return drift.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (coreRefs) db.core,
                    if (coreTypeSelectedRefs) db.coreTypeSelected,
                    if (profileGroupRefs) db.profileGroup,
                    if (profileRefs) db.profile,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (coreRefs)
                        await drift.$_getPrefetchedData<
                          CoreTypeData,
                          $CoreTypeTable,
                          CoreData
                        >(
                          currentTable: table,
                          referencedTable: $$CoreTypeTableReferences
                              ._coreRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoreTypeTableReferences(db, table, p0).coreRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coreTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (coreTypeSelectedRefs)
                        await drift.$_getPrefetchedData<
                          CoreTypeData,
                          $CoreTypeTable,
                          CoreTypeSelectedData
                        >(
                          currentTable: table,
                          referencedTable: $$CoreTypeTableReferences
                              ._coreTypeSelectedRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoreTypeTableReferences(
                                db,
                                table,
                                p0,
                              ).coreTypeSelectedRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coreTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileGroupRefs)
                        await drift.$_getPrefetchedData<
                          CoreTypeData,
                          $CoreTypeTable,
                          ProfileGroupData
                        >(
                          currentTable: table,
                          referencedTable: $$CoreTypeTableReferences
                              ._profileGroupRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoreTypeTableReferences(
                                db,
                                table,
                                p0,
                              ).profileGroupRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coreTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileRefs)
                        await drift.$_getPrefetchedData<
                          CoreTypeData,
                          $CoreTypeTable,
                          ProfileData
                        >(
                          currentTable: table,
                          referencedTable: $$CoreTypeTableReferences
                              ._profileRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoreTypeTableReferences(
                                db,
                                table,
                                p0,
                              ).profileRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coreTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoreTypeTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $CoreTypeTable,
      CoreTypeData,
      $$CoreTypeTableFilterComposer,
      $$CoreTypeTableOrderingComposer,
      $$CoreTypeTableAnnotationComposer,
      $$CoreTypeTableCreateCompanionBuilder,
      $$CoreTypeTableUpdateCompanionBuilder,
      (CoreTypeData, $$CoreTypeTableReferences),
      CoreTypeData,
      drift.PrefetchHooks Function({
        bool coreRefs,
        bool coreTypeSelectedRefs,
        bool profileGroupRefs,
        bool profileRefs,
      })
    >;
typedef $$CoreTableCreateCompanionBuilder =
    CoreCompanion Function({
      drift.Value<int> id,
      required int coreTypeId,
      drift.Value<String?> version,
      required DateTime updatedAt,
      drift.Value<bool> isExec,
      drift.Value<String?> workingDir,
      drift.Value<String> envs,
    });
typedef $$CoreTableUpdateCompanionBuilder =
    CoreCompanion Function({
      drift.Value<int> id,
      drift.Value<int> coreTypeId,
      drift.Value<String?> version,
      drift.Value<DateTime> updatedAt,
      drift.Value<bool> isExec,
      drift.Value<String?> workingDir,
      drift.Value<String> envs,
    });

final class $$CoreTableReferences
    extends drift.BaseReferences<_$Database, $CoreTable, CoreData> {
  $$CoreTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoreTypeTable _coreTypeIdTable(_$Database db) =>
      db.coreType.createAlias(
        drift.$_aliasNameGenerator(db.core.coreTypeId, db.coreType.id),
      );

  $$CoreTypeTableProcessedTableManager get coreTypeId {
    final $_column = $_itemColumn<int>('core_type_id')!;

    final manager = $$CoreTypeTableTableManager(
      $_db,
      $_db.coreType,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coreTypeIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static drift.MultiTypedResultKey<$CoreExecTable, List<CoreExecData>>
  _coreExecRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.coreExec,
    aliasName: drift.$_aliasNameGenerator(db.core.id, db.coreExec.coreId),
  );

  $$CoreExecTableProcessedTableManager get coreExecRefs {
    final manager = $$CoreExecTableTableManager(
      $_db,
      $_db.coreExec,
    ).filter((f) => f.coreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_coreExecRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<$CoreLibTable, List<CoreLibData>>
  _coreLibRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.coreLib,
    aliasName: drift.$_aliasNameGenerator(db.core.id, db.coreLib.coreId),
  );

  $$CoreLibTableProcessedTableManager get coreLibRefs {
    final manager = $$CoreLibTableTableManager(
      $_db,
      $_db.coreLib,
    ).filter((f) => f.coreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_coreLibRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<
    $CoreTypeSelectedTable,
    List<CoreTypeSelectedData>
  >
  _coreTypeSelectedRefsTable(_$Database db) =>
      drift.MultiTypedResultKey.fromTable(
        db.coreTypeSelected,
        aliasName: drift.$_aliasNameGenerator(
          db.core.id,
          db.coreTypeSelected.coreId,
        ),
      );

  $$CoreTypeSelectedTableProcessedTableManager get coreTypeSelectedRefs {
    final manager = $$CoreTypeSelectedTableTableManager(
      $_db,
      $_db.coreTypeSelected,
    ).filter((f) => f.coreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _coreTypeSelectedRefsTable($_db),
    );
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoreTableFilterComposer extends drift.Composer<_$Database, $CoreTable> {
  $$CoreTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<bool> get isExec => $composableBuilder(
    column: $table.isExec,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get envs => $composableBuilder(
    column: $table.envs,
    builder: (column) => drift.ColumnFilters(column),
  );

  $$CoreTypeTableFilterComposer get coreTypeId {
    final $$CoreTypeTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableFilterComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  drift.Expression<bool> coreExecRefs(
    drift.Expression<bool> Function($$CoreExecTableFilterComposer f) f,
  ) {
    final $$CoreExecTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreExec,
      getReferencedColumn: (t) => t.coreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreExecTableFilterComposer(
            $db: $db,
            $table: $db.coreExec,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> coreLibRefs(
    drift.Expression<bool> Function($$CoreLibTableFilterComposer f) f,
  ) {
    final $$CoreLibTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreLib,
      getReferencedColumn: (t) => t.coreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreLibTableFilterComposer(
            $db: $db,
            $table: $db.coreLib,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> coreTypeSelectedRefs(
    drift.Expression<bool> Function($$CoreTypeSelectedTableFilterComposer f) f,
  ) {
    final $$CoreTypeSelectedTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreTypeSelected,
      getReferencedColumn: (t) => t.coreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeSelectedTableFilterComposer(
            $db: $db,
            $table: $db.coreTypeSelected,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoreTableOrderingComposer
    extends drift.Composer<_$Database, $CoreTable> {
  $$CoreTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<bool> get isExec => $composableBuilder(
    column: $table.isExec,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get envs => $composableBuilder(
    column: $table.envs,
    builder: (column) => drift.ColumnOrderings(column),
  );

  $$CoreTypeTableOrderingComposer get coreTypeId {
    final $$CoreTypeTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableOrderingComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreTableAnnotationComposer
    extends drift.Composer<_$Database, $CoreTable> {
  $$CoreTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  drift.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  drift.GeneratedColumn<bool> get isExec =>
      $composableBuilder(column: $table.isExec, builder: (column) => column);

  drift.GeneratedColumn<String> get workingDir => $composableBuilder(
    column: $table.workingDir,
    builder: (column) => column,
  );

  drift.GeneratedColumn<String> get envs =>
      $composableBuilder(column: $table.envs, builder: (column) => column);

  $$CoreTypeTableAnnotationComposer get coreTypeId {
    final $$CoreTypeTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableAnnotationComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  drift.Expression<T> coreExecRefs<T extends Object>(
    drift.Expression<T> Function($$CoreExecTableAnnotationComposer a) f,
  ) {
    final $$CoreExecTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreExec,
      getReferencedColumn: (t) => t.coreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreExecTableAnnotationComposer(
            $db: $db,
            $table: $db.coreExec,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> coreLibRefs<T extends Object>(
    drift.Expression<T> Function($$CoreLibTableAnnotationComposer a) f,
  ) {
    final $$CoreLibTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreLib,
      getReferencedColumn: (t) => t.coreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreLibTableAnnotationComposer(
            $db: $db,
            $table: $db.coreLib,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> coreTypeSelectedRefs<T extends Object>(
    drift.Expression<T> Function($$CoreTypeSelectedTableAnnotationComposer a) f,
  ) {
    final $$CoreTypeSelectedTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coreTypeSelected,
      getReferencedColumn: (t) => t.coreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeSelectedTableAnnotationComposer(
            $db: $db,
            $table: $db.coreTypeSelected,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoreTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $CoreTable,
          CoreData,
          $$CoreTableFilterComposer,
          $$CoreTableOrderingComposer,
          $$CoreTableAnnotationComposer,
          $$CoreTableCreateCompanionBuilder,
          $$CoreTableUpdateCompanionBuilder,
          (CoreData, $$CoreTableReferences),
          CoreData,
          drift.PrefetchHooks Function({
            bool coreTypeId,
            bool coreExecRefs,
            bool coreLibRefs,
            bool coreTypeSelectedRefs,
          })
        > {
  $$CoreTableTableManager(_$Database db, $CoreTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoreTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoreTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoreTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<int> coreTypeId = const drift.Value.absent(),
                drift.Value<String?> version = const drift.Value.absent(),
                drift.Value<DateTime> updatedAt = const drift.Value.absent(),
                drift.Value<bool> isExec = const drift.Value.absent(),
                drift.Value<String?> workingDir = const drift.Value.absent(),
                drift.Value<String> envs = const drift.Value.absent(),
              }) => CoreCompanion(
                id: id,
                coreTypeId: coreTypeId,
                version: version,
                updatedAt: updatedAt,
                isExec: isExec,
                workingDir: workingDir,
                envs: envs,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                required int coreTypeId,
                drift.Value<String?> version = const drift.Value.absent(),
                required DateTime updatedAt,
                drift.Value<bool> isExec = const drift.Value.absent(),
                drift.Value<String?> workingDir = const drift.Value.absent(),
                drift.Value<String> envs = const drift.Value.absent(),
              }) => CoreCompanion.insert(
                id: id,
                coreTypeId: coreTypeId,
                version: version,
                updatedAt: updatedAt,
                isExec: isExec,
                workingDir: workingDir,
                envs: envs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CoreTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                coreTypeId = false,
                coreExecRefs = false,
                coreLibRefs = false,
                coreTypeSelectedRefs = false,
              }) {
                return drift.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (coreExecRefs) db.coreExec,
                    if (coreLibRefs) db.coreLib,
                    if (coreTypeSelectedRefs) db.coreTypeSelected,
                  ],
                  addJoins:
                      <
                        T extends drift.TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (coreTypeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.coreTypeId,
                                    referencedTable: $$CoreTableReferences
                                        ._coreTypeIdTable(db),
                                    referencedColumn: $$CoreTableReferences
                                        ._coreTypeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (coreExecRefs)
                        await drift.$_getPrefetchedData<
                          CoreData,
                          $CoreTable,
                          CoreExecData
                        >(
                          currentTable: table,
                          referencedTable: $$CoreTableReferences
                              ._coreExecRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoreTableReferences(db, table, p0).coreExecRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (coreLibRefs)
                        await drift.$_getPrefetchedData<
                          CoreData,
                          $CoreTable,
                          CoreLibData
                        >(
                          currentTable: table,
                          referencedTable: $$CoreTableReferences
                              ._coreLibRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoreTableReferences(db, table, p0).coreLibRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (coreTypeSelectedRefs)
                        await drift.$_getPrefetchedData<
                          CoreData,
                          $CoreTable,
                          CoreTypeSelectedData
                        >(
                          currentTable: table,
                          referencedTable: $$CoreTableReferences
                              ._coreTypeSelectedRefsTable(db),
                          managerFromTypedResult: (p0) => $$CoreTableReferences(
                            db,
                            table,
                            p0,
                          ).coreTypeSelectedRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coreId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoreTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $CoreTable,
      CoreData,
      $$CoreTableFilterComposer,
      $$CoreTableOrderingComposer,
      $$CoreTableAnnotationComposer,
      $$CoreTableCreateCompanionBuilder,
      $$CoreTableUpdateCompanionBuilder,
      (CoreData, $$CoreTableReferences),
      CoreData,
      drift.PrefetchHooks Function({
        bool coreTypeId,
        bool coreExecRefs,
        bool coreLibRefs,
        bool coreTypeSelectedRefs,
      })
    >;
typedef $$CoreExecTableCreateCompanionBuilder =
    CoreExecCompanion Function({
      drift.Value<int> coreId,
      drift.Value<String> args,
      required int assetId,
    });
typedef $$CoreExecTableUpdateCompanionBuilder =
    CoreExecCompanion Function({
      drift.Value<int> coreId,
      drift.Value<String> args,
      drift.Value<int> assetId,
    });

final class $$CoreExecTableReferences
    extends drift.BaseReferences<_$Database, $CoreExecTable, CoreExecData> {
  $$CoreExecTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoreTable _coreIdTable(_$Database db) => db.core.createAlias(
    drift.$_aliasNameGenerator(db.coreExec.coreId, db.core.id),
  );

  $$CoreTableProcessedTableManager get coreId {
    final $_column = $_itemColumn<int>('core_id')!;

    final manager = $$CoreTableTableManager(
      $_db,
      $_db.core,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coreIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AssetTable _assetIdTable(_$Database db) => db.asset.createAlias(
    drift.$_aliasNameGenerator(db.coreExec.assetId, db.asset.id),
  );

  $$AssetTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetTableTableManager(
      $_db,
      $_db.asset,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CoreExecTableFilterComposer
    extends drift.Composer<_$Database, $CoreExecTable> {
  $$CoreExecTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<String> get args => $composableBuilder(
    column: $table.args,
    builder: (column) => drift.ColumnFilters(column),
  );

  $$CoreTableFilterComposer get coreId {
    final $$CoreTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableFilterComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetTableFilterComposer get assetId {
    final $$AssetTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableFilterComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreExecTableOrderingComposer
    extends drift.Composer<_$Database, $CoreExecTable> {
  $$CoreExecTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<String> get args => $composableBuilder(
    column: $table.args,
    builder: (column) => drift.ColumnOrderings(column),
  );

  $$CoreTableOrderingComposer get coreId {
    final $$CoreTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableOrderingComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetTableOrderingComposer get assetId {
    final $$AssetTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableOrderingComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreExecTableAnnotationComposer
    extends drift.Composer<_$Database, $CoreExecTable> {
  $$CoreExecTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<String> get args =>
      $composableBuilder(column: $table.args, builder: (column) => column);

  $$CoreTableAnnotationComposer get coreId {
    final $$CoreTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableAnnotationComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetTableAnnotationComposer get assetId {
    final $$AssetTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.asset,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetTableAnnotationComposer(
            $db: $db,
            $table: $db.asset,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreExecTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $CoreExecTable,
          CoreExecData,
          $$CoreExecTableFilterComposer,
          $$CoreExecTableOrderingComposer,
          $$CoreExecTableAnnotationComposer,
          $$CoreExecTableCreateCompanionBuilder,
          $$CoreExecTableUpdateCompanionBuilder,
          (CoreExecData, $$CoreExecTableReferences),
          CoreExecData,
          drift.PrefetchHooks Function({bool coreId, bool assetId})
        > {
  $$CoreExecTableTableManager(_$Database db, $CoreExecTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoreExecTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoreExecTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoreExecTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> coreId = const drift.Value.absent(),
                drift.Value<String> args = const drift.Value.absent(),
                drift.Value<int> assetId = const drift.Value.absent(),
              }) => CoreExecCompanion(
                coreId: coreId,
                args: args,
                assetId: assetId,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> coreId = const drift.Value.absent(),
                drift.Value<String> args = const drift.Value.absent(),
                required int assetId,
              }) => CoreExecCompanion.insert(
                coreId: coreId,
                args: args,
                assetId: assetId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoreExecTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({coreId = false, assetId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (coreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.coreId,
                                referencedTable: $$CoreExecTableReferences
                                    ._coreIdTable(db),
                                referencedColumn: $$CoreExecTableReferences
                                    ._coreIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable: $$CoreExecTableReferences
                                    ._assetIdTable(db),
                                referencedColumn: $$CoreExecTableReferences
                                    ._assetIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CoreExecTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $CoreExecTable,
      CoreExecData,
      $$CoreExecTableFilterComposer,
      $$CoreExecTableOrderingComposer,
      $$CoreExecTableAnnotationComposer,
      $$CoreExecTableCreateCompanionBuilder,
      $$CoreExecTableUpdateCompanionBuilder,
      (CoreExecData, $$CoreExecTableReferences),
      CoreExecData,
      drift.PrefetchHooks Function({bool coreId, bool assetId})
    >;
typedef $$CoreLibTableCreateCompanionBuilder =
    CoreLibCompanion Function({drift.Value<int> coreId});
typedef $$CoreLibTableUpdateCompanionBuilder =
    CoreLibCompanion Function({drift.Value<int> coreId});

final class $$CoreLibTableReferences
    extends drift.BaseReferences<_$Database, $CoreLibTable, CoreLibData> {
  $$CoreLibTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoreTable _coreIdTable(_$Database db) => db.core.createAlias(
    drift.$_aliasNameGenerator(db.coreLib.coreId, db.core.id),
  );

  $$CoreTableProcessedTableManager get coreId {
    final $_column = $_itemColumn<int>('core_id')!;

    final manager = $$CoreTableTableManager(
      $_db,
      $_db.core,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coreIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CoreLibTableFilterComposer
    extends drift.Composer<_$Database, $CoreLibTable> {
  $$CoreLibTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoreTableFilterComposer get coreId {
    final $$CoreTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableFilterComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreLibTableOrderingComposer
    extends drift.Composer<_$Database, $CoreLibTable> {
  $$CoreLibTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoreTableOrderingComposer get coreId {
    final $$CoreTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableOrderingComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreLibTableAnnotationComposer
    extends drift.Composer<_$Database, $CoreLibTable> {
  $$CoreLibTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoreTableAnnotationComposer get coreId {
    final $$CoreTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableAnnotationComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreLibTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $CoreLibTable,
          CoreLibData,
          $$CoreLibTableFilterComposer,
          $$CoreLibTableOrderingComposer,
          $$CoreLibTableAnnotationComposer,
          $$CoreLibTableCreateCompanionBuilder,
          $$CoreLibTableUpdateCompanionBuilder,
          (CoreLibData, $$CoreLibTableReferences),
          CoreLibData,
          drift.PrefetchHooks Function({bool coreId})
        > {
  $$CoreLibTableTableManager(_$Database db, $CoreLibTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoreLibTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoreLibTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoreLibTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({drift.Value<int> coreId = const drift.Value.absent()}) =>
                  CoreLibCompanion(coreId: coreId),
          createCompanionCallback:
              ({drift.Value<int> coreId = const drift.Value.absent()}) =>
                  CoreLibCompanion.insert(coreId: coreId),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoreLibTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({coreId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (coreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.coreId,
                                referencedTable: $$CoreLibTableReferences
                                    ._coreIdTable(db),
                                referencedColumn: $$CoreLibTableReferences
                                    ._coreIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CoreLibTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $CoreLibTable,
      CoreLibData,
      $$CoreLibTableFilterComposer,
      $$CoreLibTableOrderingComposer,
      $$CoreLibTableAnnotationComposer,
      $$CoreLibTableCreateCompanionBuilder,
      $$CoreLibTableUpdateCompanionBuilder,
      (CoreLibData, $$CoreLibTableReferences),
      CoreLibData,
      drift.PrefetchHooks Function({bool coreId})
    >;
typedef $$CoreTypeSelectedTableCreateCompanionBuilder =
    CoreTypeSelectedCompanion Function({
      drift.Value<int> coreTypeId,
      required int coreId,
    });
typedef $$CoreTypeSelectedTableUpdateCompanionBuilder =
    CoreTypeSelectedCompanion Function({
      drift.Value<int> coreTypeId,
      drift.Value<int> coreId,
    });

final class $$CoreTypeSelectedTableReferences
    extends
        drift.BaseReferences<
          _$Database,
          $CoreTypeSelectedTable,
          CoreTypeSelectedData
        > {
  $$CoreTypeSelectedTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoreTypeTable _coreTypeIdTable(_$Database db) =>
      db.coreType.createAlias(
        drift.$_aliasNameGenerator(
          db.coreTypeSelected.coreTypeId,
          db.coreType.id,
        ),
      );

  $$CoreTypeTableProcessedTableManager get coreTypeId {
    final $_column = $_itemColumn<int>('core_type_id')!;

    final manager = $$CoreTypeTableTableManager(
      $_db,
      $_db.coreType,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coreTypeIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CoreTable _coreIdTable(_$Database db) => db.core.createAlias(
    drift.$_aliasNameGenerator(db.coreTypeSelected.coreId, db.core.id),
  );

  $$CoreTableProcessedTableManager get coreId {
    final $_column = $_itemColumn<int>('core_id')!;

    final manager = $$CoreTableTableManager(
      $_db,
      $_db.core,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coreIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CoreTypeSelectedTableFilterComposer
    extends drift.Composer<_$Database, $CoreTypeSelectedTable> {
  $$CoreTypeSelectedTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoreTypeTableFilterComposer get coreTypeId {
    final $$CoreTypeTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableFilterComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoreTableFilterComposer get coreId {
    final $$CoreTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableFilterComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreTypeSelectedTableOrderingComposer
    extends drift.Composer<_$Database, $CoreTypeSelectedTable> {
  $$CoreTypeSelectedTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoreTypeTableOrderingComposer get coreTypeId {
    final $$CoreTypeTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableOrderingComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoreTableOrderingComposer get coreId {
    final $$CoreTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableOrderingComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreTypeSelectedTableAnnotationComposer
    extends drift.Composer<_$Database, $CoreTypeSelectedTable> {
  $$CoreTypeSelectedTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoreTypeTableAnnotationComposer get coreTypeId {
    final $$CoreTypeTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableAnnotationComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoreTableAnnotationComposer get coreId {
    final $$CoreTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreId,
      referencedTable: $db.core,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTableAnnotationComposer(
            $db: $db,
            $table: $db.core,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoreTypeSelectedTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $CoreTypeSelectedTable,
          CoreTypeSelectedData,
          $$CoreTypeSelectedTableFilterComposer,
          $$CoreTypeSelectedTableOrderingComposer,
          $$CoreTypeSelectedTableAnnotationComposer,
          $$CoreTypeSelectedTableCreateCompanionBuilder,
          $$CoreTypeSelectedTableUpdateCompanionBuilder,
          (CoreTypeSelectedData, $$CoreTypeSelectedTableReferences),
          CoreTypeSelectedData,
          drift.PrefetchHooks Function({bool coreTypeId, bool coreId})
        > {
  $$CoreTypeSelectedTableTableManager(
    _$Database db,
    $CoreTypeSelectedTable table,
  ) : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoreTypeSelectedTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoreTypeSelectedTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoreTypeSelectedTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> coreTypeId = const drift.Value.absent(),
                drift.Value<int> coreId = const drift.Value.absent(),
              }) => CoreTypeSelectedCompanion(
                coreTypeId: coreTypeId,
                coreId: coreId,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> coreTypeId = const drift.Value.absent(),
                required int coreId,
              }) => CoreTypeSelectedCompanion.insert(
                coreTypeId: coreTypeId,
                coreId: coreId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoreTypeSelectedTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({coreTypeId = false, coreId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (coreTypeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.coreTypeId,
                                referencedTable:
                                    $$CoreTypeSelectedTableReferences
                                        ._coreTypeIdTable(db),
                                referencedColumn:
                                    $$CoreTypeSelectedTableReferences
                                        ._coreTypeIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (coreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.coreId,
                                referencedTable:
                                    $$CoreTypeSelectedTableReferences
                                        ._coreIdTable(db),
                                referencedColumn:
                                    $$CoreTypeSelectedTableReferences
                                        ._coreIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CoreTypeSelectedTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $CoreTypeSelectedTable,
      CoreTypeSelectedData,
      $$CoreTypeSelectedTableFilterComposer,
      $$CoreTypeSelectedTableOrderingComposer,
      $$CoreTypeSelectedTableAnnotationComposer,
      $$CoreTypeSelectedTableCreateCompanionBuilder,
      $$CoreTypeSelectedTableUpdateCompanionBuilder,
      (CoreTypeSelectedData, $$CoreTypeSelectedTableReferences),
      CoreTypeSelectedData,
      drift.PrefetchHooks Function({bool coreTypeId, bool coreId})
    >;
typedef $$ProfileGroupTableCreateCompanionBuilder =
    ProfileGroupCompanion Function({
      drift.Value<int> id,
      required String name,
      required DateTime updatedAt,
      required ProfileGroupType type,
      drift.Value<int?> coreTypeId,
    });
typedef $$ProfileGroupTableUpdateCompanionBuilder =
    ProfileGroupCompanion Function({
      drift.Value<int> id,
      drift.Value<String> name,
      drift.Value<DateTime> updatedAt,
      drift.Value<ProfileGroupType> type,
      drift.Value<int?> coreTypeId,
    });

final class $$ProfileGroupTableReferences
    extends
        drift.BaseReferences<_$Database, $ProfileGroupTable, ProfileGroupData> {
  $$ProfileGroupTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoreTypeTable _coreTypeIdTable(_$Database db) =>
      db.coreType.createAlias(
        drift.$_aliasNameGenerator(db.profileGroup.coreTypeId, db.coreType.id),
      );

  $$CoreTypeTableProcessedTableManager? get coreTypeId {
    final $_column = $_itemColumn<int>('core_type_id');
    if ($_column == null) return null;
    final manager = $$CoreTypeTableTableManager(
      $_db,
      $_db.coreType,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coreTypeIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static drift.MultiTypedResultKey<$ProfileTable, List<ProfileData>>
  _profileRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.profile,
    aliasName: drift.$_aliasNameGenerator(
      db.profileGroup.id,
      db.profile.profileGroupId,
    ),
  );

  $$ProfileTableProcessedTableManager get profileRefs {
    final manager = $$ProfileTableTableManager(
      $_db,
      $_db.profile,
    ).filter((f) => f.profileGroupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<
    $ProfileGroupLocalTable,
    List<ProfileGroupLocalData>
  >
  _profileGroupLocalRefsTable(_$Database db) =>
      drift.MultiTypedResultKey.fromTable(
        db.profileGroupLocal,
        aliasName: drift.$_aliasNameGenerator(
          db.profileGroup.id,
          db.profileGroupLocal.profileGroupId,
        ),
      );

  $$ProfileGroupLocalTableProcessedTableManager get profileGroupLocalRefs {
    final manager = $$ProfileGroupLocalTableTableManager(
      $_db,
      $_db.profileGroupLocal,
    ).filter((f) => f.profileGroupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _profileGroupLocalRefsTable($_db),
    );
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<
    $ProfileGroupRemoteTable,
    List<ProfileGroupRemoteData>
  >
  _profileGroupRemoteRefsTable(_$Database db) =>
      drift.MultiTypedResultKey.fromTable(
        db.profileGroupRemote,
        aliasName: drift.$_aliasNameGenerator(
          db.profileGroup.id,
          db.profileGroupRemote.profileGroupId,
        ),
      );

  $$ProfileGroupRemoteTableProcessedTableManager get profileGroupRemoteRefs {
    final manager = $$ProfileGroupRemoteTableTableManager(
      $_db,
      $_db.profileGroupRemote,
    ).filter((f) => f.profileGroupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _profileGroupRemoteRefsTable($_db),
    );
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfileGroupTableFilterComposer
    extends drift.Composer<_$Database, $ProfileGroupTable> {
  $$ProfileGroupTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnWithTypeConverterFilters<ProfileGroupType, ProfileGroupType, int>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => drift.ColumnWithTypeConverterFilters(column),
  );

  $$CoreTypeTableFilterComposer get coreTypeId {
    final $$CoreTypeTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableFilterComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  drift.Expression<bool> profileRefs(
    drift.Expression<bool> Function($$ProfileTableFilterComposer f) f,
  ) {
    final $$ProfileTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.profileGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableFilterComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> profileGroupLocalRefs(
    drift.Expression<bool> Function($$ProfileGroupLocalTableFilterComposer f) f,
  ) {
    final $$ProfileGroupLocalTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileGroupLocal,
      getReferencedColumn: (t) => t.profileGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupLocalTableFilterComposer(
            $db: $db,
            $table: $db.profileGroupLocal,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> profileGroupRemoteRefs(
    drift.Expression<bool> Function($$ProfileGroupRemoteTableFilterComposer f)
    f,
  ) {
    final $$ProfileGroupRemoteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileGroupRemote,
      getReferencedColumn: (t) => t.profileGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupRemoteTableFilterComposer(
            $db: $db,
            $table: $db.profileGroupRemote,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfileGroupTableOrderingComposer
    extends drift.Composer<_$Database, $ProfileGroupTable> {
  $$ProfileGroupTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => drift.ColumnOrderings(column),
  );

  $$CoreTypeTableOrderingComposer get coreTypeId {
    final $$CoreTypeTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableOrderingComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupTableAnnotationComposer
    extends drift.Composer<_$Database, $ProfileGroupTable> {
  $$ProfileGroupTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  drift.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  drift.GeneratedColumnWithTypeConverter<ProfileGroupType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$CoreTypeTableAnnotationComposer get coreTypeId {
    final $$CoreTypeTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableAnnotationComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  drift.Expression<T> profileRefs<T extends Object>(
    drift.Expression<T> Function($$ProfileTableAnnotationComposer a) f,
  ) {
    final $$ProfileTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.profileGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableAnnotationComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> profileGroupLocalRefs<T extends Object>(
    drift.Expression<T> Function($$ProfileGroupLocalTableAnnotationComposer a)
    f,
  ) {
    final $$ProfileGroupLocalTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.profileGroupLocal,
          getReferencedColumn: (t) => t.profileGroupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProfileGroupLocalTableAnnotationComposer(
                $db: $db,
                $table: $db.profileGroupLocal,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  drift.Expression<T> profileGroupRemoteRefs<T extends Object>(
    drift.Expression<T> Function($$ProfileGroupRemoteTableAnnotationComposer a)
    f,
  ) {
    final $$ProfileGroupRemoteTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.profileGroupRemote,
          getReferencedColumn: (t) => t.profileGroupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProfileGroupRemoteTableAnnotationComposer(
                $db: $db,
                $table: $db.profileGroupRemote,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProfileGroupTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $ProfileGroupTable,
          ProfileGroupData,
          $$ProfileGroupTableFilterComposer,
          $$ProfileGroupTableOrderingComposer,
          $$ProfileGroupTableAnnotationComposer,
          $$ProfileGroupTableCreateCompanionBuilder,
          $$ProfileGroupTableUpdateCompanionBuilder,
          (ProfileGroupData, $$ProfileGroupTableReferences),
          ProfileGroupData,
          drift.PrefetchHooks Function({
            bool coreTypeId,
            bool profileRefs,
            bool profileGroupLocalRefs,
            bool profileGroupRemoteRefs,
          })
        > {
  $$ProfileGroupTableTableManager(_$Database db, $ProfileGroupTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileGroupTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileGroupTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileGroupTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String> name = const drift.Value.absent(),
                drift.Value<DateTime> updatedAt = const drift.Value.absent(),
                drift.Value<ProfileGroupType> type = const drift.Value.absent(),
                drift.Value<int?> coreTypeId = const drift.Value.absent(),
              }) => ProfileGroupCompanion(
                id: id,
                name: name,
                updatedAt: updatedAt,
                type: type,
                coreTypeId: coreTypeId,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                required String name,
                required DateTime updatedAt,
                required ProfileGroupType type,
                drift.Value<int?> coreTypeId = const drift.Value.absent(),
              }) => ProfileGroupCompanion.insert(
                id: id,
                name: name,
                updatedAt: updatedAt,
                type: type,
                coreTypeId: coreTypeId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileGroupTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                coreTypeId = false,
                profileRefs = false,
                profileGroupLocalRefs = false,
                profileGroupRemoteRefs = false,
              }) {
                return drift.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (profileRefs) db.profile,
                    if (profileGroupLocalRefs) db.profileGroupLocal,
                    if (profileGroupRemoteRefs) db.profileGroupRemote,
                  ],
                  addJoins:
                      <
                        T extends drift.TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (coreTypeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.coreTypeId,
                                    referencedTable:
                                        $$ProfileGroupTableReferences
                                            ._coreTypeIdTable(db),
                                    referencedColumn:
                                        $$ProfileGroupTableReferences
                                            ._coreTypeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (profileRefs)
                        await drift.$_getPrefetchedData<
                          ProfileGroupData,
                          $ProfileGroupTable,
                          ProfileData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfileGroupTableReferences
                              ._profileRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfileGroupTableReferences(
                                db,
                                table,
                                p0,
                              ).profileRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileGroupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileGroupLocalRefs)
                        await drift.$_getPrefetchedData<
                          ProfileGroupData,
                          $ProfileGroupTable,
                          ProfileGroupLocalData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfileGroupTableReferences
                              ._profileGroupLocalRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfileGroupTableReferences(
                                db,
                                table,
                                p0,
                              ).profileGroupLocalRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileGroupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileGroupRemoteRefs)
                        await drift.$_getPrefetchedData<
                          ProfileGroupData,
                          $ProfileGroupTable,
                          ProfileGroupRemoteData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfileGroupTableReferences
                              ._profileGroupRemoteRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfileGroupTableReferences(
                                db,
                                table,
                                p0,
                              ).profileGroupRemoteRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileGroupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProfileGroupTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $ProfileGroupTable,
      ProfileGroupData,
      $$ProfileGroupTableFilterComposer,
      $$ProfileGroupTableOrderingComposer,
      $$ProfileGroupTableAnnotationComposer,
      $$ProfileGroupTableCreateCompanionBuilder,
      $$ProfileGroupTableUpdateCompanionBuilder,
      (ProfileGroupData, $$ProfileGroupTableReferences),
      ProfileGroupData,
      drift.PrefetchHooks Function({
        bool coreTypeId,
        bool profileRefs,
        bool profileGroupLocalRefs,
        bool profileGroupRemoteRefs,
      })
    >;
typedef $$ProfileTableCreateCompanionBuilder =
    ProfileCompanion Function({
      drift.Value<int> id,
      required String name,
      required String key,
      drift.Value<int?> coreTypeId,
      drift.Value<String> coreCfg,
      drift.Value<String> coreCfgFmt,
      required DateTime updatedAt,
      required ProfileType type,
      drift.Value<int> profileGroupId,
      drift.Value<int?> httping,
    });
typedef $$ProfileTableUpdateCompanionBuilder =
    ProfileCompanion Function({
      drift.Value<int> id,
      drift.Value<String> name,
      drift.Value<String> key,
      drift.Value<int?> coreTypeId,
      drift.Value<String> coreCfg,
      drift.Value<String> coreCfgFmt,
      drift.Value<DateTime> updatedAt,
      drift.Value<ProfileType> type,
      drift.Value<int> profileGroupId,
      drift.Value<int?> httping,
    });

final class $$ProfileTableReferences
    extends drift.BaseReferences<_$Database, $ProfileTable, ProfileData> {
  $$ProfileTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoreTypeTable _coreTypeIdTable(_$Database db) =>
      db.coreType.createAlias(
        drift.$_aliasNameGenerator(db.profile.coreTypeId, db.coreType.id),
      );

  $$CoreTypeTableProcessedTableManager? get coreTypeId {
    final $_column = $_itemColumn<int>('core_type_id');
    if ($_column == null) return null;
    final manager = $$CoreTypeTableTableManager(
      $_db,
      $_db.coreType,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coreTypeIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProfileGroupTable _profileGroupIdTable(_$Database db) =>
      db.profileGroup.createAlias(
        drift.$_aliasNameGenerator(
          db.profile.profileGroupId,
          db.profileGroup.id,
        ),
      );

  $$ProfileGroupTableProcessedTableManager get profileGroupId {
    final $_column = $_itemColumn<int>('profile_group_id')!;

    final manager = $$ProfileGroupTableTableManager(
      $_db,
      $_db.profileGroup,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileGroupIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static drift.MultiTypedResultKey<$ProfileLocalTable, List<ProfileLocalData>>
  _profileLocalRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.profileLocal,
    aliasName: drift.$_aliasNameGenerator(
      db.profile.id,
      db.profileLocal.profileId,
    ),
  );

  $$ProfileLocalTableProcessedTableManager get profileLocalRefs {
    final manager = $$ProfileLocalTableTableManager(
      $_db,
      $_db.profileLocal,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileLocalRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static drift.MultiTypedResultKey<$ProfileRemoteTable, List<ProfileRemoteData>>
  _profileRemoteRefsTable(_$Database db) => drift.MultiTypedResultKey.fromTable(
    db.profileRemote,
    aliasName: drift.$_aliasNameGenerator(
      db.profile.id,
      db.profileRemote.profileId,
    ),
  );

  $$ProfileRemoteTableProcessedTableManager get profileRemoteRefs {
    final manager = $$ProfileRemoteTableTableManager(
      $_db,
      $_db.profileRemote,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileRemoteRefsTable($_db));
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfileTableFilterComposer
    extends drift.Composer<_$Database, $ProfileTable> {
  $$ProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get coreCfg => $composableBuilder(
    column: $table.coreCfg,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get coreCfgFmt => $composableBuilder(
    column: $table.coreCfgFmt,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnWithTypeConverterFilters<ProfileType, ProfileType, int>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => drift.ColumnWithTypeConverterFilters(column),
  );

  drift.ColumnFilters<int> get httping => $composableBuilder(
    column: $table.httping,
    builder: (column) => drift.ColumnFilters(column),
  );

  $$CoreTypeTableFilterComposer get coreTypeId {
    final $$CoreTypeTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableFilterComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfileGroupTableFilterComposer get profileGroupId {
    final $$ProfileGroupTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableFilterComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  drift.Expression<bool> profileLocalRefs(
    drift.Expression<bool> Function($$ProfileLocalTableFilterComposer f) f,
  ) {
    final $$ProfileLocalTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileLocal,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileLocalTableFilterComposer(
            $db: $db,
            $table: $db.profileLocal,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<bool> profileRemoteRefs(
    drift.Expression<bool> Function($$ProfileRemoteTableFilterComposer f) f,
  ) {
    final $$ProfileRemoteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileRemote,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileRemoteTableFilterComposer(
            $db: $db,
            $table: $db.profileRemote,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfileTableOrderingComposer
    extends drift.Composer<_$Database, $ProfileTable> {
  $$ProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get coreCfg => $composableBuilder(
    column: $table.coreCfg,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get coreCfgFmt => $composableBuilder(
    column: $table.coreCfgFmt,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get httping => $composableBuilder(
    column: $table.httping,
    builder: (column) => drift.ColumnOrderings(column),
  );

  $$CoreTypeTableOrderingComposer get coreTypeId {
    final $$CoreTypeTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableOrderingComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfileGroupTableOrderingComposer get profileGroupId {
    final $$ProfileGroupTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableOrderingComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileTableAnnotationComposer
    extends drift.Composer<_$Database, $ProfileTable> {
  $$ProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  drift.GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  drift.GeneratedColumn<String> get coreCfg =>
      $composableBuilder(column: $table.coreCfg, builder: (column) => column);

  drift.GeneratedColumn<String> get coreCfgFmt => $composableBuilder(
    column: $table.coreCfgFmt,
    builder: (column) => column,
  );

  drift.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  drift.GeneratedColumnWithTypeConverter<ProfileType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  drift.GeneratedColumn<int> get httping =>
      $composableBuilder(column: $table.httping, builder: (column) => column);

  $$CoreTypeTableAnnotationComposer get coreTypeId {
    final $$CoreTypeTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coreTypeId,
      referencedTable: $db.coreType,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoreTypeTableAnnotationComposer(
            $db: $db,
            $table: $db.coreType,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfileGroupTableAnnotationComposer get profileGroupId {
    final $$ProfileGroupTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableAnnotationComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  drift.Expression<T> profileLocalRefs<T extends Object>(
    drift.Expression<T> Function($$ProfileLocalTableAnnotationComposer a) f,
  ) {
    final $$ProfileLocalTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileLocal,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileLocalTableAnnotationComposer(
            $db: $db,
            $table: $db.profileLocal,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  drift.Expression<T> profileRemoteRefs<T extends Object>(
    drift.Expression<T> Function($$ProfileRemoteTableAnnotationComposer a) f,
  ) {
    final $$ProfileRemoteTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileRemote,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileRemoteTableAnnotationComposer(
            $db: $db,
            $table: $db.profileRemote,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfileTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $ProfileTable,
          ProfileData,
          $$ProfileTableFilterComposer,
          $$ProfileTableOrderingComposer,
          $$ProfileTableAnnotationComposer,
          $$ProfileTableCreateCompanionBuilder,
          $$ProfileTableUpdateCompanionBuilder,
          (ProfileData, $$ProfileTableReferences),
          ProfileData,
          drift.PrefetchHooks Function({
            bool coreTypeId,
            bool profileGroupId,
            bool profileLocalRefs,
            bool profileRemoteRefs,
          })
        > {
  $$ProfileTableTableManager(_$Database db, $ProfileTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String> name = const drift.Value.absent(),
                drift.Value<String> key = const drift.Value.absent(),
                drift.Value<int?> coreTypeId = const drift.Value.absent(),
                drift.Value<String> coreCfg = const drift.Value.absent(),
                drift.Value<String> coreCfgFmt = const drift.Value.absent(),
                drift.Value<DateTime> updatedAt = const drift.Value.absent(),
                drift.Value<ProfileType> type = const drift.Value.absent(),
                drift.Value<int> profileGroupId = const drift.Value.absent(),
                drift.Value<int?> httping = const drift.Value.absent(),
              }) => ProfileCompanion(
                id: id,
                name: name,
                key: key,
                coreTypeId: coreTypeId,
                coreCfg: coreCfg,
                coreCfgFmt: coreCfgFmt,
                updatedAt: updatedAt,
                type: type,
                profileGroupId: profileGroupId,
                httping: httping,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                required String name,
                required String key,
                drift.Value<int?> coreTypeId = const drift.Value.absent(),
                drift.Value<String> coreCfg = const drift.Value.absent(),
                drift.Value<String> coreCfgFmt = const drift.Value.absent(),
                required DateTime updatedAt,
                required ProfileType type,
                drift.Value<int> profileGroupId = const drift.Value.absent(),
                drift.Value<int?> httping = const drift.Value.absent(),
              }) => ProfileCompanion.insert(
                id: id,
                name: name,
                key: key,
                coreTypeId: coreTypeId,
                coreCfg: coreCfg,
                coreCfgFmt: coreCfgFmt,
                updatedAt: updatedAt,
                type: type,
                profileGroupId: profileGroupId,
                httping: httping,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                coreTypeId = false,
                profileGroupId = false,
                profileLocalRefs = false,
                profileRemoteRefs = false,
              }) {
                return drift.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (profileLocalRefs) db.profileLocal,
                    if (profileRemoteRefs) db.profileRemote,
                  ],
                  addJoins:
                      <
                        T extends drift.TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (coreTypeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.coreTypeId,
                                    referencedTable: $$ProfileTableReferences
                                        ._coreTypeIdTable(db),
                                    referencedColumn: $$ProfileTableReferences
                                        ._coreTypeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (profileGroupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.profileGroupId,
                                    referencedTable: $$ProfileTableReferences
                                        ._profileGroupIdTable(db),
                                    referencedColumn: $$ProfileTableReferences
                                        ._profileGroupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (profileLocalRefs)
                        await drift.$_getPrefetchedData<
                          ProfileData,
                          $ProfileTable,
                          ProfileLocalData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfileTableReferences
                              ._profileLocalRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfileTableReferences(
                                db,
                                table,
                                p0,
                              ).profileLocalRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (profileRemoteRefs)
                        await drift.$_getPrefetchedData<
                          ProfileData,
                          $ProfileTable,
                          ProfileRemoteData
                        >(
                          currentTable: table,
                          referencedTable: $$ProfileTableReferences
                              ._profileRemoteRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfileTableReferences(
                                db,
                                table,
                                p0,
                              ).profileRemoteRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProfileTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $ProfileTable,
      ProfileData,
      $$ProfileTableFilterComposer,
      $$ProfileTableOrderingComposer,
      $$ProfileTableAnnotationComposer,
      $$ProfileTableCreateCompanionBuilder,
      $$ProfileTableUpdateCompanionBuilder,
      (ProfileData, $$ProfileTableReferences),
      ProfileData,
      drift.PrefetchHooks Function({
        bool coreTypeId,
        bool profileGroupId,
        bool profileLocalRefs,
        bool profileRemoteRefs,
      })
    >;
typedef $$ProfileLocalTableCreateCompanionBuilder =
    ProfileLocalCompanion Function({drift.Value<int> profileId});
typedef $$ProfileLocalTableUpdateCompanionBuilder =
    ProfileLocalCompanion Function({drift.Value<int> profileId});

final class $$ProfileLocalTableReferences
    extends
        drift.BaseReferences<_$Database, $ProfileLocalTable, ProfileLocalData> {
  $$ProfileLocalTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfileTable _profileIdTable(_$Database db) => db.profile.createAlias(
    drift.$_aliasNameGenerator(db.profileLocal.profileId, db.profile.id),
  );

  $$ProfileTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfileTableTableManager(
      $_db,
      $_db.profile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProfileLocalTableFilterComposer
    extends drift.Composer<_$Database, $ProfileLocalTable> {
  $$ProfileLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProfileTableFilterComposer get profileId {
    final $$ProfileTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableFilterComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileLocalTableOrderingComposer
    extends drift.Composer<_$Database, $ProfileLocalTable> {
  $$ProfileLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProfileTableOrderingComposer get profileId {
    final $$ProfileTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableOrderingComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileLocalTableAnnotationComposer
    extends drift.Composer<_$Database, $ProfileLocalTable> {
  $$ProfileLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProfileTableAnnotationComposer get profileId {
    final $$ProfileTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableAnnotationComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileLocalTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $ProfileLocalTable,
          ProfileLocalData,
          $$ProfileLocalTableFilterComposer,
          $$ProfileLocalTableOrderingComposer,
          $$ProfileLocalTableAnnotationComposer,
          $$ProfileLocalTableCreateCompanionBuilder,
          $$ProfileLocalTableUpdateCompanionBuilder,
          (ProfileLocalData, $$ProfileLocalTableReferences),
          ProfileLocalData,
          drift.PrefetchHooks Function({bool profileId})
        > {
  $$ProfileLocalTableTableManager(_$Database db, $ProfileLocalTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({drift.Value<int> profileId = const drift.Value.absent()}) =>
                  ProfileLocalCompanion(profileId: profileId),
          createCompanionCallback:
              ({drift.Value<int> profileId = const drift.Value.absent()}) =>
                  ProfileLocalCompanion.insert(profileId: profileId),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileLocalTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$ProfileLocalTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$ProfileLocalTableReferences
                                    ._profileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProfileLocalTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $ProfileLocalTable,
      ProfileLocalData,
      $$ProfileLocalTableFilterComposer,
      $$ProfileLocalTableOrderingComposer,
      $$ProfileLocalTableAnnotationComposer,
      $$ProfileLocalTableCreateCompanionBuilder,
      $$ProfileLocalTableUpdateCompanionBuilder,
      (ProfileLocalData, $$ProfileLocalTableReferences),
      ProfileLocalData,
      drift.PrefetchHooks Function({bool profileId})
    >;
typedef $$ProfileRemoteTableCreateCompanionBuilder =
    ProfileRemoteCompanion Function({
      drift.Value<int> profileId,
      required String url,
      required int autoUpdateInterval,
    });
typedef $$ProfileRemoteTableUpdateCompanionBuilder =
    ProfileRemoteCompanion Function({
      drift.Value<int> profileId,
      drift.Value<String> url,
      drift.Value<int> autoUpdateInterval,
    });

final class $$ProfileRemoteTableReferences
    extends
        drift.BaseReferences<
          _$Database,
          $ProfileRemoteTable,
          ProfileRemoteData
        > {
  $$ProfileRemoteTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfileTable _profileIdTable(_$Database db) => db.profile.createAlias(
    drift.$_aliasNameGenerator(db.profileRemote.profileId, db.profile.id),
  );

  $$ProfileTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfileTableTableManager(
      $_db,
      $_db.profile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProfileRemoteTableFilterComposer
    extends drift.Composer<_$Database, $ProfileRemoteTable> {
  $$ProfileRemoteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => drift.ColumnFilters(column),
  );

  $$ProfileTableFilterComposer get profileId {
    final $$ProfileTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableFilterComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileRemoteTableOrderingComposer
    extends drift.Composer<_$Database, $ProfileRemoteTable> {
  $$ProfileRemoteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => drift.ColumnOrderings(column),
  );

  $$ProfileTableOrderingComposer get profileId {
    final $$ProfileTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableOrderingComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileRemoteTableAnnotationComposer
    extends drift.Composer<_$Database, $ProfileRemoteTable> {
  $$ProfileRemoteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  drift.GeneratedColumn<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => column,
  );

  $$ProfileTableAnnotationComposer get profileId {
    final $$ProfileTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableAnnotationComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileRemoteTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $ProfileRemoteTable,
          ProfileRemoteData,
          $$ProfileRemoteTableFilterComposer,
          $$ProfileRemoteTableOrderingComposer,
          $$ProfileRemoteTableAnnotationComposer,
          $$ProfileRemoteTableCreateCompanionBuilder,
          $$ProfileRemoteTableUpdateCompanionBuilder,
          (ProfileRemoteData, $$ProfileRemoteTableReferences),
          ProfileRemoteData,
          drift.PrefetchHooks Function({bool profileId})
        > {
  $$ProfileRemoteTableTableManager(_$Database db, $ProfileRemoteTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileRemoteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileRemoteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileRemoteTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> profileId = const drift.Value.absent(),
                drift.Value<String> url = const drift.Value.absent(),
                drift.Value<int> autoUpdateInterval =
                    const drift.Value.absent(),
              }) => ProfileRemoteCompanion(
                profileId: profileId,
                url: url,
                autoUpdateInterval: autoUpdateInterval,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> profileId = const drift.Value.absent(),
                required String url,
                required int autoUpdateInterval,
              }) => ProfileRemoteCompanion.insert(
                profileId: profileId,
                url: url,
                autoUpdateInterval: autoUpdateInterval,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileRemoteTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$ProfileRemoteTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$ProfileRemoteTableReferences
                                    ._profileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProfileRemoteTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $ProfileRemoteTable,
      ProfileRemoteData,
      $$ProfileRemoteTableFilterComposer,
      $$ProfileRemoteTableOrderingComposer,
      $$ProfileRemoteTableAnnotationComposer,
      $$ProfileRemoteTableCreateCompanionBuilder,
      $$ProfileRemoteTableUpdateCompanionBuilder,
      (ProfileRemoteData, $$ProfileRemoteTableReferences),
      ProfileRemoteData,
      drift.PrefetchHooks Function({bool profileId})
    >;
typedef $$ProfileGroupLocalTableCreateCompanionBuilder =
    ProfileGroupLocalCompanion Function({drift.Value<int> profileGroupId});
typedef $$ProfileGroupLocalTableUpdateCompanionBuilder =
    ProfileGroupLocalCompanion Function({drift.Value<int> profileGroupId});

final class $$ProfileGroupLocalTableReferences
    extends
        drift.BaseReferences<
          _$Database,
          $ProfileGroupLocalTable,
          ProfileGroupLocalData
        > {
  $$ProfileGroupLocalTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfileGroupTable _profileGroupIdTable(_$Database db) =>
      db.profileGroup.createAlias(
        drift.$_aliasNameGenerator(
          db.profileGroupLocal.profileGroupId,
          db.profileGroup.id,
        ),
      );

  $$ProfileGroupTableProcessedTableManager get profileGroupId {
    final $_column = $_itemColumn<int>('profile_group_id')!;

    final manager = $$ProfileGroupTableTableManager(
      $_db,
      $_db.profileGroup,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileGroupIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProfileGroupLocalTableFilterComposer
    extends drift.Composer<_$Database, $ProfileGroupLocalTable> {
  $$ProfileGroupLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProfileGroupTableFilterComposer get profileGroupId {
    final $$ProfileGroupTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableFilterComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupLocalTableOrderingComposer
    extends drift.Composer<_$Database, $ProfileGroupLocalTable> {
  $$ProfileGroupLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProfileGroupTableOrderingComposer get profileGroupId {
    final $$ProfileGroupTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableOrderingComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupLocalTableAnnotationComposer
    extends drift.Composer<_$Database, $ProfileGroupLocalTable> {
  $$ProfileGroupLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProfileGroupTableAnnotationComposer get profileGroupId {
    final $$ProfileGroupTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableAnnotationComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupLocalTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $ProfileGroupLocalTable,
          ProfileGroupLocalData,
          $$ProfileGroupLocalTableFilterComposer,
          $$ProfileGroupLocalTableOrderingComposer,
          $$ProfileGroupLocalTableAnnotationComposer,
          $$ProfileGroupLocalTableCreateCompanionBuilder,
          $$ProfileGroupLocalTableUpdateCompanionBuilder,
          (ProfileGroupLocalData, $$ProfileGroupLocalTableReferences),
          ProfileGroupLocalData,
          drift.PrefetchHooks Function({bool profileGroupId})
        > {
  $$ProfileGroupLocalTableTableManager(
    _$Database db,
    $ProfileGroupLocalTable table,
  ) : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileGroupLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileGroupLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileGroupLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                drift.Value<int> profileGroupId = const drift.Value.absent(),
              }) => ProfileGroupLocalCompanion(profileGroupId: profileGroupId),
          createCompanionCallback:
              ({
                drift.Value<int> profileGroupId = const drift.Value.absent(),
              }) => ProfileGroupLocalCompanion.insert(
                profileGroupId: profileGroupId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileGroupLocalTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileGroupId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileGroupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileGroupId,
                                referencedTable:
                                    $$ProfileGroupLocalTableReferences
                                        ._profileGroupIdTable(db),
                                referencedColumn:
                                    $$ProfileGroupLocalTableReferences
                                        ._profileGroupIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProfileGroupLocalTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $ProfileGroupLocalTable,
      ProfileGroupLocalData,
      $$ProfileGroupLocalTableFilterComposer,
      $$ProfileGroupLocalTableOrderingComposer,
      $$ProfileGroupLocalTableAnnotationComposer,
      $$ProfileGroupLocalTableCreateCompanionBuilder,
      $$ProfileGroupLocalTableUpdateCompanionBuilder,
      (ProfileGroupLocalData, $$ProfileGroupLocalTableReferences),
      ProfileGroupLocalData,
      drift.PrefetchHooks Function({bool profileGroupId})
    >;
typedef $$ProfileGroupRemoteTableCreateCompanionBuilder =
    ProfileGroupRemoteCompanion Function({
      drift.Value<int> profileGroupId,
      required String url,
      required ProfileGroupRemoteProtocol protocol,
      required int autoUpdateInterval,
    });
typedef $$ProfileGroupRemoteTableUpdateCompanionBuilder =
    ProfileGroupRemoteCompanion Function({
      drift.Value<int> profileGroupId,
      drift.Value<String> url,
      drift.Value<ProfileGroupRemoteProtocol> protocol,
      drift.Value<int> autoUpdateInterval,
    });

final class $$ProfileGroupRemoteTableReferences
    extends
        drift.BaseReferences<
          _$Database,
          $ProfileGroupRemoteTable,
          ProfileGroupRemoteData
        > {
  $$ProfileGroupRemoteTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfileGroupTable _profileGroupIdTable(_$Database db) =>
      db.profileGroup.createAlias(
        drift.$_aliasNameGenerator(
          db.profileGroupRemote.profileGroupId,
          db.profileGroup.id,
        ),
      );

  $$ProfileGroupTableProcessedTableManager get profileGroupId {
    final $_column = $_itemColumn<int>('profile_group_id')!;

    final manager = $$ProfileGroupTableTableManager(
      $_db,
      $_db.profileGroup,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileGroupIdTable($_db));
    if (item == null) return manager;
    return drift.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProfileGroupRemoteTableFilterComposer
    extends drift.Composer<_$Database, $ProfileGroupRemoteTable> {
  $$ProfileGroupRemoteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnWithTypeConverterFilters<
    ProfileGroupRemoteProtocol,
    ProfileGroupRemoteProtocol,
    int
  >
  get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => drift.ColumnWithTypeConverterFilters(column),
  );

  drift.ColumnFilters<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => drift.ColumnFilters(column),
  );

  $$ProfileGroupTableFilterComposer get profileGroupId {
    final $$ProfileGroupTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableFilterComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupRemoteTableOrderingComposer
    extends drift.Composer<_$Database, $ProfileGroupRemoteTable> {
  $$ProfileGroupRemoteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => drift.ColumnOrderings(column),
  );

  $$ProfileGroupTableOrderingComposer get profileGroupId {
    final $$ProfileGroupTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableOrderingComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupRemoteTableAnnotationComposer
    extends drift.Composer<_$Database, $ProfileGroupRemoteTable> {
  $$ProfileGroupRemoteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  drift.GeneratedColumnWithTypeConverter<ProfileGroupRemoteProtocol, int>
  get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  drift.GeneratedColumn<int> get autoUpdateInterval => $composableBuilder(
    column: $table.autoUpdateInterval,
    builder: (column) => column,
  );

  $$ProfileGroupTableAnnotationComposer get profileGroupId {
    final $$ProfileGroupTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileGroupId,
      referencedTable: $db.profileGroup,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupTableAnnotationComposer(
            $db: $db,
            $table: $db.profileGroup,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupRemoteTableTableManager
    extends
        drift.RootTableManager<
          _$Database,
          $ProfileGroupRemoteTable,
          ProfileGroupRemoteData,
          $$ProfileGroupRemoteTableFilterComposer,
          $$ProfileGroupRemoteTableOrderingComposer,
          $$ProfileGroupRemoteTableAnnotationComposer,
          $$ProfileGroupRemoteTableCreateCompanionBuilder,
          $$ProfileGroupRemoteTableUpdateCompanionBuilder,
          (ProfileGroupRemoteData, $$ProfileGroupRemoteTableReferences),
          ProfileGroupRemoteData,
          drift.PrefetchHooks Function({bool profileGroupId})
        > {
  $$ProfileGroupRemoteTableTableManager(
    _$Database db,
    $ProfileGroupRemoteTable table,
  ) : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileGroupRemoteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileGroupRemoteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileGroupRemoteTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                drift.Value<int> profileGroupId = const drift.Value.absent(),
                drift.Value<String> url = const drift.Value.absent(),
                drift.Value<ProfileGroupRemoteProtocol> protocol =
                    const drift.Value.absent(),
                drift.Value<int> autoUpdateInterval =
                    const drift.Value.absent(),
              }) => ProfileGroupRemoteCompanion(
                profileGroupId: profileGroupId,
                url: url,
                protocol: protocol,
                autoUpdateInterval: autoUpdateInterval,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> profileGroupId = const drift.Value.absent(),
                required String url,
                required ProfileGroupRemoteProtocol protocol,
                required int autoUpdateInterval,
              }) => ProfileGroupRemoteCompanion.insert(
                profileGroupId: profileGroupId,
                url: url,
                protocol: protocol,
                autoUpdateInterval: autoUpdateInterval,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileGroupRemoteTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileGroupId = false}) {
            return drift.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends drift.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileGroupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileGroupId,
                                referencedTable:
                                    $$ProfileGroupRemoteTableReferences
                                        ._profileGroupIdTable(db),
                                referencedColumn:
                                    $$ProfileGroupRemoteTableReferences
                                        ._profileGroupIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProfileGroupRemoteTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$Database,
      $ProfileGroupRemoteTable,
      ProfileGroupRemoteData,
      $$ProfileGroupRemoteTableFilterComposer,
      $$ProfileGroupRemoteTableOrderingComposer,
      $$ProfileGroupRemoteTableAnnotationComposer,
      $$ProfileGroupRemoteTableCreateCompanionBuilder,
      $$ProfileGroupRemoteTableUpdateCompanionBuilder,
      (ProfileGroupRemoteData, $$ProfileGroupRemoteTableReferences),
      ProfileGroupRemoteData,
      drift.PrefetchHooks Function({bool profileGroupId})
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$AssetTableTableManager get asset =>
      $$AssetTableTableManager(_db, _db.asset);
  $$AssetLocalTableTableManager get assetLocal =>
      $$AssetLocalTableTableManager(_db, _db.assetLocal);
  $$AssetRemoteTableTableManager get assetRemote =>
      $$AssetRemoteTableTableManager(_db, _db.assetRemote);
  $$CoreTypeTableTableManager get coreType =>
      $$CoreTypeTableTableManager(_db, _db.coreType);
  $$CoreTableTableManager get core => $$CoreTableTableManager(_db, _db.core);
  $$CoreExecTableTableManager get coreExec =>
      $$CoreExecTableTableManager(_db, _db.coreExec);
  $$CoreLibTableTableManager get coreLib =>
      $$CoreLibTableTableManager(_db, _db.coreLib);
  $$CoreTypeSelectedTableTableManager get coreTypeSelected =>
      $$CoreTypeSelectedTableTableManager(_db, _db.coreTypeSelected);
  $$ProfileGroupTableTableManager get profileGroup =>
      $$ProfileGroupTableTableManager(_db, _db.profileGroup);
  $$ProfileTableTableManager get profile =>
      $$ProfileTableTableManager(_db, _db.profile);
  $$ProfileLocalTableTableManager get profileLocal =>
      $$ProfileLocalTableTableManager(_db, _db.profileLocal);
  $$ProfileRemoteTableTableManager get profileRemote =>
      $$ProfileRemoteTableTableManager(_db, _db.profileRemote);
  $$ProfileGroupLocalTableTableManager get profileGroupLocal =>
      $$ProfileGroupLocalTableTableManager(_db, _db.profileGroupLocal);
  $$ProfileGroupRemoteTableTableManager get profileGroupRemote =>
      $$ProfileGroupRemoteTableTableManager(_db, _db.profileGroupRemote);
}
