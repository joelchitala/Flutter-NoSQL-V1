import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/nosql_database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional_manager.dart';

class NoSQLTransactional {
  NoSQLDatabase? _noSQLDatabase;

  final NoSQLTransactionalManager _transactionalManager =
      NoSQLTransactionalManager();

  bool _executionResults = true;

  final Future<void> Function() _executeFunction;

  NoSQLTransactional({
    required Future<void> Function() executeFunction,
  }) : _executeFunction = executeFunction;

  NoSQLDatabase? get noSQLDatabase => _noSQLDatabase;

  bool getExecutionResults() {
    return _executionResults;
  }

  Future<void> setExecutionResults(bool res) async {
    if (!res) {
      _executionResults = res;
    }
  }

  Future<int> mount() async {
    return _transactionalManager.mount(
      this,
      (noSQLDatabase) {
        if (_noSQLDatabase != null) return;

        _noSQLDatabase = noSQLDatabase;
      },
    );
  }

  Future<int> unmount() async {
    return _transactionalManager.unmount(this);
  }

  Future<bool> execute() async {
    bool results = true;

    try {
      int res = await mount();

      if (res == -1) return false;

      await _executeFunction();

      results = _executionResults;

      await unmount();
    } catch (e) {
      throw "Transactional Error $e occured";
    }

    await unmount();

    return results;
  }

  Future<void> commit({
    Function(String? error)? callback,
  }) async {
    if (noSQLDatabase != null && _executionResults) {
      await _transactionalManager.commit(_noSQLDatabase!);
    }
  }
}
