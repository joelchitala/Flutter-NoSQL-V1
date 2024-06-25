import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/sub_components/database.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/meta/nosql_meta_manager.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/utils/core_utils.dart';

class NoSQLDatabase extends BaseComponent<NoSQLDatabase, Database> {
  final double _version = 1.0;
  NoSqlMetaManager metaManger = NoSqlMetaManager();

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
    objects = data["objects"] ?? objects;

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

  bool addDatabase({
    required Database database,
  }) {
    bool results = true;
    var name = database.name.toLowerCase();

    if (objects.containsKey(name)) {
      return false;
    }

    objects.addAll({name: database});
    broadcastObjectsChanges();

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
    broadcastObjectsChanges();

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
    broadcastObjectsChanges();

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
