import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/components/restriction_object.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional_manager.dart';

class NoSqlMetaObject with NoSQLTransactionalManagerWrapper {
  final Map<String, RestrictionFieldObject> _fieldObjects = {};

  void initFieldObject({
    required Collection collection,
  }) {
    if (_fieldObjects[collection.objectId] == null) {}
  }

  RestrictionFieldObject? getFieldObject({
    required String objectId,
  }) {
    return _fieldObjects[objectId];
  }

  List<RestrictionFieldObject> getFieldObjects({
    bool Function(RestrictionFieldObject object)? query,
  }) {
    var objects = _fieldObjects.values;
    return query == null ? objects.toList() : objects.where(query).toList();
  }

  Future<bool> addFieldObject({
    required Collection collection,
    required RestrictionFieldObject fieldObject,
  }) async {
    initFieldObject(collection: collection);
    return opMapper(
      func: () async {
        bool results = true;

        if (getFieldObject(objectId: fieldObject.objectId) != null) {
          return false;
        }

        _fieldObjects.addAll(
          {
            fieldObject.objectId: fieldObject,
          },
        );

        return results;
      },
    );
  }

  Future<bool> removeFieldObject({
    required Collection collection,
    required RestrictionFieldObject fieldObject,
  }) async {
    return opMapper(
      func: () async {
        bool results = true;
        var object = getFieldObject(
          objectId: fieldObject.objectId,
        );

        if (object == null) {
          return false;
        }

        _fieldObjects.remove(fieldObject.objectId);

        return results;
      },
    );
  }
}
