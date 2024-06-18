import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/NoSQLDatabase.dart';

class NoSQLManager {
  final double _version = 1.0;

  NoSQLDatabase noSQLDatabase = NoSQLDatabase();
  String path = "database.json";

  NoSQLManager._();

  static final _instance = NoSQLManager._();

  factory NoSQLManager() => _instance;

  void initialize({required Map<String, dynamic> data}) {}

  Map<String, dynamic> toJson() {
    return {
      "version": _version,
      "noSQLDatabase": noSQLDatabase,
    };
  }
}
