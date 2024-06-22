import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/components/restriction_object.dart';

class NoSqlMetaRestrictionObject {
  final Map<String, RestrictionBuilder> _collectionRestrictions = {};

  NoSqlMetaRestrictionObject();

  Map<String, RestrictionBuilder> get collectionRestrictions =>
      _collectionRestrictions;

  RestrictionBuilder? getRestrictionBuilder({required String objectId}) {
    return _collectionRestrictions[objectId];
  }

  bool addRestriction({
    required String objectId,
    required RestrictionBuilder restrictionBuilder,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    bool results = true;

    var ref = _collectionRestrictions[objectId];

    if (ref == null) {
      _collectionRestrictions.addAll({objectId: restrictionBuilder});

      return false;
    }

    bool res = true;

    for (var fieldObject in restrictionBuilder.fieldObjects) {
      res = ref.addFieldObject(
        object: fieldObject,
        callback: callback,
      );

      if (!res) results = false;
    }

    for (var valueObject in restrictionBuilder.valueObjects) {
      res = ref.addValueObject(
        object: valueObject,
        callback: callback,
      );

      if (!res) results = false;
    }

    return results;
  }

  bool removeRestriction({
    required String objectId,
    List<String> fieldObjectKeys = const [],
    List<String> valueObjectKeys = const [],
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    bool results = true;

    var ref = _collectionRestrictions[objectId];

    if (ref == null) {
      return false;
    }

    bool res = true;

    for (var key in fieldObjectKeys) {
      res = ref.removeField(
        key: key,
        callback: callback,
      );

      if (!res) results = false;
    }

    for (var key in valueObjectKeys) {
      res = ref.removeValue(
        key: key,
        callback: callback,
      );
      if (!res) results = false;
    }

    return results;
  }

  Map<String, dynamic> toJson({
    required bool serialize,
  }) {
    Map<String, dynamic> collectionRestrictionsTempEntries = {};

    for (var object in _collectionRestrictions.entries) {
      var key = object.key;
      var value = object.value;

      collectionRestrictionsTempEntries.addAll(
        {
          key: value.toJson(serialize: serialize),
        },
      );
    }

    return {
      "_collectionRestrictions": serialize
          ? collectionRestrictionsTempEntries
          : _collectionRestrictions,
    };
  }
}
