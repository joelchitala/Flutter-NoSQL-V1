import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/nosql_meta_object.dart';

class NoSqlMetaManager {
  final NoSqlMetaRestrictionObject _metaRestrictionObject =
      NoSqlMetaRestrictionObject();

  NoSqlMetaRestrictionObject get metaRestrictionObject =>
      _metaRestrictionObject;

  Map<String, dynamic> toJson({
    required bool serialize,
  }) {
    return {
      "_metaRestrictionObject": serialize
          ? _metaRestrictionObject.toJson(
              serialize: serialize,
            )
          : _metaRestrictionObject,
    };
  }
}