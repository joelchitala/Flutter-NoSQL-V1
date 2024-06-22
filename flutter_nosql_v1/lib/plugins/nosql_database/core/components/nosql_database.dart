import 'dart:async';

import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/nosql_meta_manager.dart';

class NoSQLDatabase {
  final double _version = 1.0;
  NoSqlMetaManager metaManger = NoSqlMetaManager();

  DateTime _timestamp = DateTime.now();

  final _streamController = StreamController<List<Database>>.broadcast();
  Map<String, Database> databases = {};
  Database? currentDatabase;
  bool inMemoryOnlyMode;

  NoSQLDatabase({
    this.inMemoryOnlyMode = false,
  });

  NoSQLDatabase? noSQLDatabaseCopy() {
    try {
      NoSQLDatabase noSQLDatabase = NoSQLDatabase();

      noSQLDatabase.setDatabase(toJson(serialize: false));

      return noSQLDatabase;
    } catch (_) {}

    return null;
  }

  void setDatabase(Map<String, dynamic> data) {
    inMemoryOnlyMode = data["inMemoryOnlyMode"] ?? inMemoryOnlyMode;
    databases = data["databases"] ?? databases;
  }

  void initialize({required Map<String, dynamic> data}) {
    try {
      if (inMemoryOnlyMode) {
        return;
      }

      _timestamp = DateTime.tryParse("${data["_timestamp"]}") ?? _timestamp;

      Map<String, dynamic>? jsonDatabases = data["databases"];

      jsonDatabases?.forEach(
        (key, value) {
          databases.addAll(
            {
              key: Database.fromJson(data: value),
            },
          );
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Database>> stream({bool Function(Database database)? query}) {
    if (query != null) {
      return _streamController.stream.map((databases) {
        return databases.where(query).toList();
      });
    }

    return _streamController.stream;
  }

  void _broadcastChanges() {
    _streamController.add(List<Database>.from(databases.values.toList()));
  }

  void dispose() {
    _streamController.close();
  }

  bool addDatabase({
    required Database database,
  }) {
    bool results = true;
    var name = database.name;

    if (databases.containsKey(name)) {
      return false;
    }

    databases.addAll({database.name: database});
    _broadcastChanges();
    return results;
  }

  bool updateDatabase({
    required Database database,
    required Map<String, dynamic> data,
  }) {
    bool results = true;

    var object = databases[database.name];

    if (object == null) {
      return false;
    }

    object.update(data: data);
    _broadcastChanges();
    return results;
  }

  bool removeDatabase({
    required Database database,
  }) {
    bool results = true;

    var object = databases.remove(database.name);

    if (object == null) {
      return false;
    }
    _broadcastChanges();

    return results;
  }

  Map<String, dynamic> toJson({required bool serialize}) {
    Map<String, Map> databaseEntries = {};

    databases.forEach(
      (key, value) {
        databaseEntries.addAll(
          {
            key: value.toJson(serialize: serialize),
          },
        );
      },
    );

    return {
      "version": _version,
      "_timestamp": _timestamp.toIso8601String(),
      "inMemoryOnlyMode": inMemoryOnlyMode,
      "databases":
          serialize ? databaseEntries : Map<String, Database>.from(databases),
      "metaManger": serialize
          ? metaManger.toJson(
              serialize: serialize,
            )
          : metaManger,
    };
  }
}
