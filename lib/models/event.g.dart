// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  date: _dateFromJson(json['date'] as String),
  isHoliday: json['isHoliday'] == null
      ? false
      : _intToBool((json['isHoliday'] as num).toInt()),
  isBirthday: json['isBirthday'] == null
      ? false
      : _intToBool((json['isBirthday'] as num).toInt()),
  color: json['color'] == null
      ? AppColors.lightBlue
      : _colorFromJson((json['color'] as num).toInt()),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'isHoliday': _boolToInt(instance.isHoliday),
  'isBirthday': _boolToInt(instance.isBirthday),
  'date': _dateToJson(instance.date),
  'color': _colorToJson(instance.color),
};
