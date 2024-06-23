import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/nosql_database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/proxies/nosql_document_proxy.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional_manager.dart';

class NoSQLManager with NoSqlDocumentProxy {
  final double _version = 1.0;

  NoSQLDatabase _noSQLDatabase = NoSQLDatabase();

  NoSQLManager._();
  static final _instance = NoSQLManager._();
  factory NoSQLManager() => _instance;

  void initialize({required Map<String, dynamic> data}) {
    try {
      _noSQLDatabase.initialize(data: data["_noSQLDatabase"]);
    } catch (e) {
      throw "Error $e occured in initializing an instance of NoSQLDatabase";
    }
  }

  NoSQLDatabase getNoSqlDatabase() {
    final NoSQLTransactionalManager transactionalManager =
        NoSQLTransactionalManager();

    var transactional = transactionalManager.currentTransactional;

    if (transactional != null) {
      return transactional.noSQLDatabase ?? _noSQLDatabase;
    }
    return _noSQLDatabase;
  }

  void setNoSqlDatabase(NoSQLDatabase db) {
    _noSQLDatabase = db;
  }

  Future<bool> opMapper({required Future<bool> Function() func}) async {
    final NoSQLTransactionalManager transactionalManager =
        NoSQLTransactionalManager();

    var transactional = transactionalManager.currentTransactional;

    if (transactional != null) {
      if (!transactional.getExecutionResults()) {
        return false;
      }

      bool results = await func();

      await transactional.setExecutionResults(results);

      return results;
    }

    return await func();
  }

  Map<String, dynamic> toJson({
    required bool serialize,
  }) {
    return {
      "version": _version,
      "_noSQLDatabase": serialize
          ? _noSQLDatabase.toJson(serialize: serialize)
          : _noSQLDatabase,
    };
  }
}
