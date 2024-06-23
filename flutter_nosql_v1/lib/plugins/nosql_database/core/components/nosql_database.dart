import 'dart:async';

import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/nosql_meta_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/utils.dart';

class NoSQLDatabase extends BaseComponent<NoSQLDatabase, Database> {
  final double _version = 1.0;
  NoSqlMetaManager metaManger = NoSqlMetaManager();

  final _streamController = StreamController<List<Database>>.broadcast();
  Database? currentDatabase;
  bool inMemoryOnlyMode;

  NoSQLDatabase({
    required super.objectId,
    this.inMemoryOnlyMode = false,
  });
  factory NoSQLDatabase.copy({
    required NoSQLDatabase initialDB,
  }) {
    NoSQLDatabase noSQLDatabase = NoSQLDatabase(
      objectId: generateUUID(),
    );
    noSQLDatabase.initialize(data: initialDB.toJson(serialize: true));
    return noSQLDatabase;
  }

  void setDatabase(Map<String, dynamic> data) {
    inMemoryOnlyMode = data["inMemoryOnlyMode"] ?? inMemoryOnlyMode;
    objects = data["objects"] == null
        ? objects
        : Map<String, Database>.from(data["objects"]);

    metaManger = data["metaManger"] ?? metaManger;
  }

  void initialize({required Map<String, dynamic> data}) {
    if (inMemoryOnlyMode) {
      return;
    }

    Map<String, dynamic>? jsonDatabases = data["objects"];

    jsonDatabases?.forEach(
      (key, value) {
        objects.addAll(
          {
            key: Database.fromJson(data: value),
          },
        );
      },
    );

    Map<String, dynamic>? jsonMetaManager = data["metaManger"];

    if (jsonMetaManager != null) {
      metaManger.initialize(data: jsonMetaManager);
    }
  }

  Stream<List<Database>> stream({bool Function(Database database)? query}) {
    if (query != null) {
      return _streamController.stream.map((objects) {
        return objects.where(query).toList();
      });
    }

    return _streamController.stream;
  }

  void _broadcastChanges() {
    _streamController.add(List<Database>.from(objects.values.toList()));
  }

  void dispose() {
    _streamController.close();
  }

  bool addDatabase({
    required Database database,
  }) {
    bool results = true;
    var name = database.name.toLowerCase();

    if (objects.containsKey(name)) {
      return false;
    }

    objects.addAll({name: database});
    _broadcastChanges();

    return results;
  }

  bool updateDatabase({
    required Database database,
    required Map<String, dynamic> data,
  }) {
    bool results = true;

    var name = database.name.toLowerCase();
    var object = objects[name];

    if (object == null) {
      return false;
    }

    var updateName = data["name"];
    if (updateName != null) {
      var isKey = objects.containsKey(updateName);

      if (isKey) {
        if (objects[updateName] != database) {
          return false;
        }
      } else {
        objects[updateName] = database;
        objects.remove(name);
      }
    }

    object.update(data: data);
    _broadcastChanges();

    return results;
  }

  bool removeDatabase({
    required Database database,
  }) {
    bool results = true;

    var name = database.name.toLowerCase();
    var object = objects.remove(name);

    if (object == null) {
      return false;
    }
    _broadcastChanges();

    return results;
  }

  @override
  Map<String, dynamic> toJson({required bool serialize}) {
    Map<String, Map> databaseEntries = {};

    objects.forEach(
      (key, value) {
        databaseEntries.addAll(
          {
            key: value.toJson(serialize: serialize),
          },
        );
      },
    );

    return super.toJson(serialize: serialize)
      ..addAll(
        {
          "version": _version,
          "inMemoryOnlyMode": inMemoryOnlyMode,
          "objects": serialize ? databaseEntries : objects,
          "metaManger": serialize
              ? metaManger.toJson(
                  serialize: serialize,
                )
              : metaManger,
        },
      );
  }

  @override
  bool update({required Map<String, dynamic> data}) {
    return true;
  }
}
