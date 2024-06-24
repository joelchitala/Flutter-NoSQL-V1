import 'components/nosql_meta_object.dart';

class NoSqlMetaManager {
  final NoSqlMetaRestrictionObject _metaRestrictionObject =
      NoSqlMetaRestrictionObject();

  NoSqlMetaRestrictionObject get metaRestrictionObject =>
      _metaRestrictionObject;

  void initialize({required Map<String, dynamic> data}) {
    var metaRestrictionObjectData = data["_metaRestrictionObject"];

    if (metaRestrictionObjectData != null) {
      _metaRestrictionObject.initialize(data: metaRestrictionObjectData);
    }
  }

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
