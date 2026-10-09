// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anyportal_rest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileGroupRemoteAnyPortalREST _$ProfileGroupRemoteAnyPortalRESTFromJson(
  Map<String, dynamic> json,
) => ProfileGroupRemoteAnyPortalREST(
  (json['version'] as num).toInt(),
  (json['profiles'] as List<dynamic>)
      .map((e) => Profile.fromJson(e as Map<String, dynamic>))
      .toList(),
  name: json['name'] as String?,
  autoUpdateInterval: (json['autoUpdateInterval'] as num?)?.toInt(),
  subscriptionUserInfo: json['subscriptionUserInfo'] == null
      ? null
      : SubscriptionUserInfo.fromJson(
          json['subscriptionUserInfo'] as Map<String, dynamic>,
        ),
  supportUrl: json['supportUrl'] as String?,
  profileWebPageUrl: json['profileWebPageUrl'] as String?,
);

Map<String, dynamic> _$ProfileGroupRemoteAnyPortalRESTToJson(
  ProfileGroupRemoteAnyPortalREST instance,
) => <String, dynamic>{
  'profiles': instance.profiles.map((e) => e.toJson()).toList(),
  'name': instance.name,
  'autoUpdateInterval': instance.autoUpdateInterval,
  'subscriptionUserInfo': instance.subscriptionUserInfo?.toJson(),
  'supportUrl': instance.supportUrl,
  'profileWebPageUrl': instance.profileWebPageUrl,
  'version': instance.version,
};
