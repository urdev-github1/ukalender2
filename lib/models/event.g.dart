// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  title: json['title'] as String,
  description: json['description'] as String?,
  date: DateTime.parse(json['date'] as String),
  isHoliday: json['isHoliday'] as bool? ?? false,
  color: json['color'] == null
      ? Colors.blue
      : _colorFromJson((json['color'] as num).toInt()),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'isHoliday': instance.isHoliday,
  'color': _colorToJson(instance.color),
};
