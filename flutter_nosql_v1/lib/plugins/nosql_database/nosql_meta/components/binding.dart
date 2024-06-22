import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/components/restriction_object.dart';

class Binding {
  Collection parent, child;

  RestrictionFieldObject fieldObject;

  Binding({
    required this.parent,
    required this.child,
    required this.fieldObject,
  });
}
