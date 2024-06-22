import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/nosql_meta_object.dart';

class NoSqlMetaManager {
  final NoSqlMetaObject _metaObject = NoSqlMetaObject();

  NoSqlMetaManager._();
  static final _intance = NoSqlMetaManager._();
  factory NoSqlMetaManager() => _intance;

  NoSqlMetaObject get metaObject => _metaObject;
}
