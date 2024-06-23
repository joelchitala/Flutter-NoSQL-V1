import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/events.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/nosql_database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/proxies/nosql_document_proxy.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/utils.dart';

class NoSQLManager with NoSqlDocumentProxy {
  final double _version = 1.0;
  final EventStream _eventStream = EventStream();

  NoSQLDatabase _noSQLDatabase = NoSQLDatabase(
    objectId: generateUUID(),
  );

  NoSQLManager._() {
    _eventStream.eventStream.listen(
      (event) {
        print(event);
        switch (event.event) {
          case EventType.add:
            break;
          case EventType.update:
            break;
          case EventType.remove:
            if (event.entityType == EntityType.collection) {
              var obj = event.object as Collection;
              getNoSqlDatabase()
                  .metaManger
                  .metaRestrictionObject
                  .removeCollectionRestriction(
                    objectId: obj.objectId,
                  );
            }
            break;
          default:
        }
      },
    );
  }
  static final _instance = NoSQLManager._();
  factory NoSQLManager() => _instance;

  NoSQLDatabase get currentDB => _noSQLDatabase;

  void initialize({required Map<String, dynamic> data}) {
    _noSQLDatabase.initialize(data: data["_noSQLDatabase"]);
  }

  NoSQLDatabase getNoSqlDatabase() {
    NoSQLTransactionalManager transactionalManager =
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
    NoSQLTransactionalManager transactionalManager =
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
