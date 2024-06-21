import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/nosql_database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/nosql_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/logger.dart';

class NoSQLTransactionalManager extends Logging {
  NoSQLTransactional? _currentTransactional;

  final NoSQLManager _noSqlManager = NoSQLManager();

  NoSQLTransactionalManager._();
  static final _intance = NoSQLTransactionalManager._();
  factory NoSQLTransactionalManager() => _intance;

  NoSQLTransactional? get currentTransactional => _currentTransactional;

  Future<int> mount(
    NoSQLTransactional noSQLTransactional,
    void Function(NoSQLDatabase noSQLDatabase) setDatabase,
  ) async {
    try {
      if (_currentTransactional == null) {
        _currentTransactional = noSQLTransactional;
        var db = _noSqlManager.noSQLDatabase.noSQLDatabaseCopy();

        if (db == null) return -1;

        setDatabase(db);

        return 1;
      }

      return 0;
    } catch (e) {
      log("Error $e occured in mounting nosql transactional");
    }
    return -1;
  }

  Future<int> unmount(NoSQLTransactional noSQLTransactional) async {
    if (_currentTransactional == noSQLTransactional) {
      _currentTransactional = null;
      return 1;
    }

    return 0;
  }

  Future<bool> opMapper({required Future<bool> Function() func}) async {
    if (_currentTransactional != null) {
      if (!_currentTransactional!.getExecutionResults()) {
        return false;
      }

      bool results = await func();

      await _currentTransactional!.setExecutionResults(results);

      return results;
    }

    return await func();
  }

  Future<NoSQLDatabase> commit(NoSQLDatabase noSQLDatabase) async {
    _noSqlManager.noSQLDatabase = noSQLDatabase;

    return noSQLDatabase;
  }
}

mixin NoSQLTransactionalManagerWrapper {
  final NoSQLTransactionalManager _transactionalManager =
      NoSQLTransactionalManager();

  Future<bool> opMapper({required Future<bool> Function() func}) async {
    return await _transactionalManager.opMapper(func: func);
  }
}
