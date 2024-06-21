import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/nosql_database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional_manager.dart';

class NoSQLManager {
  final double _version = 1.0;

  NoSQLDatabase noSQLDatabase = NoSQLDatabase();
  String path = "database.json";

  NoSQLManager._();
  static final _instance = NoSQLManager._();
  factory NoSQLManager() => _instance;

  void initialize({required Map<String, dynamic> data}) {
    try {
      noSQLDatabase.initialize(data: data["noSQLDatabase"]);
    } catch (e) {
      throw "Error $e occured in initializing an instance of NoSQLDatabase";
    }
  }

  NoSQLDatabase getNoSqlDatabase() {
    final NoSQLTransactionalManager transactionalManager =
        NoSQLTransactionalManager();

    var transactional = transactionalManager.currentTransactional;

    if (transactional != null) {
      return transactional.noSQLDatabase ?? noSQLDatabase;
    }
    return noSQLDatabase;
  }

  void setNoSqlDatabase(NoSQLDatabase db) {
    noSQLDatabase = db;
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
