import 'package:flutter_nosql_v1/plugins/nosql_database/core/NoSqlManager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/utils.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/Logger.dart';

class NoSQLUtility extends Logging {
  final NoSQLManager _noSQLManager = NoSQLManager();
  Database? currentDatabase;
  late Map<String, Database> databases;

  NoSQLUtility() {
    databases = _noSQLManager.noSQLDatabase.databases;
    currentDatabase = _noSQLManager.noSQLDatabase.currentDatabase;
  }

  Future<bool> createDatabase({
    required String name,
    DateTime? timestamp,
  }) async {
    Database? db = databases[name];

    if (name.isEmpty) {
      log("Failed to create Database. name can not be empty");
      return false;
    }
    if (db != null) {
      log("Failed to create $name database, database exists");
      return false;
    }
    var database = Database(
      objectId: generateUUID(),
      name: name,
      timestamp: timestamp,
    );

    databases.addAll({
      name: database,
    });
    log("$name database successfully created");

    return true;
  }

  Future<Database?> getDatabase({required String reference}) async {
    String name = reference;

    if (reference.contains(".")) {
      name = reference.split(".")[0];
    }
    Database? db = databases[name];
    return db;
  }

  Future<bool> deleteDatabase({required String name}) async {
    Database? db = databases[name];

    try {
      if (db == null) {
        log(
          "Failed to delete $name database, database does not exists",
        );
        return false;
      }
      databases.remove(name);
      log("$name database successfully deleted");
    } catch (e) {
      log("Failed to delete $name database, error ocurred -> $e");
      return false;
    }
    return true;
  }

  Future<bool> createCollection({required String reference}) async {
    Database? database;
    String collectionName;

    if (reference.contains(".")) {
      database = await getDatabase(reference: reference.split(".")[0]);
      collectionName = reference.split(".")[1];
    } else {
      database = currentDatabase;
      collectionName = reference;
    }

    if (database == null || collectionName.isEmpty) return false;

    var collection = Collection(
      objectId: generateUUID(),
      name: collectionName,
    );

    return database.addCollection(collection: collection);
  }

  Future<Collection?> getCollection({required String reference}) async {
    Database? database;
    Collection? collection;

    if (reference.contains(".")) {
      database = databases[reference.split(".")[0]];
      collection = database?.collections[reference.split(".")[1]];
    } else {
      database = currentDatabase;
      collection = database?.collections[reference];
    }

    if (database == null || collection == null) {
      return null;
    }

    return collection;
  }

  Future<bool> deleteCollection({required String reference}) async {
    Database? database = await getDatabase(reference: reference);

    if (database == null) {
      log("Database with the reference $reference not found");
      return false;
    }

    Collection? collection = await getCollection(reference: reference);

    if (collection == null) {
      log("Collection with the reference $reference not found");
      return false;
    }

    bool results = database.removeCollection(collection: collection);

    results
        ? log("Collection with the reference $reference deleted")
        : log("Failed Collection with the reference $reference");

    return results;
  }
}
