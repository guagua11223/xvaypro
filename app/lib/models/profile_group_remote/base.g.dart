// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'name': instance.name,
  'key': instance.key,
  'coreType': instance.coreType,
  'format': instance.format,
  'coreConfig': instance.coreConfig,
};

SubscriptionUserInfo _$SubscriptionUserInfoFromJson(
  Map<String, dynamic> json,
) => SubscriptionUserInfo(
  json['expire'] as num?,
  json['total'] as num?,
  json['upload'] as num?,
  json['download'] as num?,
);

Map<String, dynamic> _$SubscriptionUserInfoToJson(
  SubscriptionUserInfo instance,
) => <String, dynamic>{
  'expire': instance.expire,
  'total': instance.total,
  'upload': instance.upload,
  'download': instance.download,
};
