import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/NoSQLDatabase.dart';

class NoSQLManager {
  final double _version = 1.0;

  NoSQLDatabase noSQLDatabase = NoSQLDatabase();
  String path = "database.json";

  NoSQLManager._();
  static final _instance = NoSQLManager._();
  factory NoSQLManager() => _instance;

  void initialize({required Map<String, dynamic> data}) {
    try {
      var noSQLDB = NoSQLDatabase();

      noSQLDB.initialize(data: data);

      noSQLDatabase = noSQLDB;
    } catch (e) {
      throw "Error $e occured in initializing an instance of NoSQLDatabase";
    }
  }

  Map<String, dynamic> toJson({
    required bool serialize,
  }) {
    return {
      "version": _version,
      "noSQLDatabase": serialize
          ? noSQLDatabase.toJson(serialize: serialize)
          : noSQLDatabase,
    };
  }
}
