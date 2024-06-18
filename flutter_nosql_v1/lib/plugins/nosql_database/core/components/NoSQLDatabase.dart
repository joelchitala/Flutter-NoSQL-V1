import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Database.dart';

class NoSQLDatabase {
  final double _version = 1.0;
  DateTime _timestamp = DateTime.now();

  Map<String, Database> databases = {};
  Database? currentDatabase;
  bool inMemoryOnlyMode;

  NoSQLDatabase({
    this.inMemoryOnlyMode = false,
  });

  void initialize({required Map<String, dynamic> data}) {
    try {
      if (inMemoryOnlyMode) {
        return;
      }

      _timestamp = DateTime.tryParse(data["timestamp"]) ?? _timestamp;

      Map<String, dynamic>? databases = data["databases"];

      databases?.forEach(
        (key, value) {
          databases.addAll(
            {
              key: Database.fromJson(data: value),
            },
          );
        },
      );
    } catch (e) {
      return;
    }
  }

  bool addCollection({
    required Database database,
  }) {
    bool results = true;
    var name = database.name;

    if (databases.containsKey(name)) {
      return false;
    }

    return results;
  }

  bool updateCollection({
    required Database database,
    required Map<String, dynamic> data,
  }) {
    bool results = true;

    var object = databases[database.name];

    if (object == null) {
      return false;
    }

    object.update(data: data);

    return results;
  }

  bool removeCollection({
    required Database database,
  }) {
    bool results = true;

    var object = databases.remove(database.name);

    if (object == null) {
      return false;
    }

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
      "inMemoryOnlyMode": inMemoryOnlyMode,
      "databases": serialize ? databaseEntries : databases,
    };
  }
}
