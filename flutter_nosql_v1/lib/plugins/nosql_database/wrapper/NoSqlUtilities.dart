import 'package:flutter_nosql_v1/plugins/nosql_database/core/NoSqlManager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/fileoperations.dart';
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
  Future<bool> setCurrentDatabase({String? name}) async {
    name == null
        ? _noSQLManager.noSQLDatabase.currentDatabase = null
        : _noSQLManager.noSQLDatabase.currentDatabase =
            await getDatabase(reference: name);

    return true;
  }

  Future<bool> initialize({
    String databasePath = "database.json",
    String loggerPath = "logger.json",
  }) async {
    bool results = true;

    try {
      Map<String, dynamic>? databaseData = await readFile(databasePath);

      Map<String, dynamic>? loggerData = await readFile(loggerPath);

      if (databaseData != null) {
        _noSQLManager.initialize(data: databaseData);
      } else {
        log("Failed to initialize database with path $databasePath");
      }

      if (loggerData != null) {
        initializeLogger(data: loggerData);
      } else {
        log("Failed to initialize logger with path $loggerPath");
      }
    } catch (e) {
      rethrow;
    }

    return results;
  }

  Future<bool> commitToDisk({
    String databasePath = "database.json",
    String loggerPath = "logger.json",
  }) async {
    bool results = true;

    try {
      bool savedDatabase = await writeFile(
        databasePath,
        _noSQLManager.noSQLDatabase.toJson(
          serialize: true,
        ),
      );

      bool savedLogger = await writeFile(
        loggerPath,
        loggerToJson(),
      );

      if (!savedDatabase) {
        log("Failed to save database to path $databasePath");
      }

      if (!savedLogger) {
        log("Failed to save logger to path $loggerPath");
      }
    } catch (e) {
      rethrow;
    }

    return results;
  }

  Future<bool> createDatabase({
    required String name,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Database? db = databases[name];
    String? successMessage, errorMessage;

    if (name.isEmpty) {
      errorMessage = "Failed to create Database. name can not be empty";
      log(errorMessage);
      if (callback != null) callback(error: errorMessage);
      return false;
    }

    if (db != null) {
      errorMessage = "Failed to create $name database, database exists";
      log(errorMessage);
      if (callback != null) callback(error: errorMessage);
      return false;
    }

    var database = Database(
      objectId: generateUUID(),
      name: name,
      timestamp: DateTime.now(),
    );

    databases.addAll({
      name: database,
    });

    successMessage = "$name database successfully created";
    log(successMessage);
    if (callback != null) callback(res: (true, successMessage));

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

  Future<bool> deleteDatabase({
    required String name,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Database? db = databases[name];

    String? successMessage, errorMessage;

    try {
      if (db == null) {
        errorMessage =
            "Failed to delete $name database, database does not exists";

        log(errorMessage);
        if (callback != null) callback(error: errorMessage);

        return false;
      }
      bool results = databases.remove(name) == null ? false : true;

      if (results) {
        successMessage = "$name database successfully deleted";
        log(successMessage);
        if (callback != null) callback(res: (results, successMessage));
      } else {
        errorMessage = "Failed to delete $name Database";
        log(errorMessage);
        if (callback != null) callback(error: errorMessage);
      }
    } catch (e) {
      errorMessage = "Failed to delete $name database, error ocurred -> $e";
      log(errorMessage);
      if (callback != null) callback(error: errorMessage);
      return false;
    }

    return true;
  }

  Future<bool> createCollection({
    required String reference,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Database? database;
    String collectionName;

    if (reference.contains(".")) {
      database = await getDatabase(reference: reference.split(".")[0]);
      collectionName = reference.split(".")[1];
    } else {
      database = currentDatabase;
      collectionName = reference;
    }

    String? successMessage, errorMessage;

    if (database == null) {
      errorMessage = "Database with the reference $reference not found";
      log(errorMessage);

      if (callback != null) callback(error: errorMessage);
      return false;
    }

    if (collectionName.isEmpty) {
      errorMessage = "Collection name in the $reference can not be empty";
      log(errorMessage);

      if (callback != null) callback(error: errorMessage);
      return false;
    }

    var collection = Collection(
      objectId: generateUUID(),
      name: collectionName,
    );

    bool results = database.addCollection(collection: collection);

    if (results) {
      successMessage = "Collection with the reference $reference added";
      log(successMessage);
      if (callback != null) callback(res: (results, successMessage));
    } else {
      errorMessage = "Failed to add Collection with the reference $reference";
      log(errorMessage);
      if (callback != null) callback(error: errorMessage);
    }

    return results;
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

  Future<bool> deleteCollection({
    required String reference,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Database? database = await getDatabase(reference: reference);

    String? successMessage, errorMessage;

    if (database == null) {
      errorMessage = "Database with the reference $reference not found";
      log(errorMessage);
      if (callback != null) callback(error: errorMessage);
      return false;
    }

    Collection? collection = await getCollection(reference: reference);

    if (collection == null) {
      errorMessage = "Collection with the reference $reference not found";
      log(errorMessage);
      if (callback != null) callback(error: errorMessage);
      return false;
    }

    bool results = database.removeCollection(collection: collection);

    if (results) {
      successMessage = "Collection with the reference $reference deleted";
      log(successMessage);
      if (callback != null) callback(res: (results, successMessage));
    } else {
      errorMessage =
          "Failed to delete Collection with the reference $reference";
      log(errorMessage);
      if (callback != null) callback(error: errorMessage);
    }

    return results;
  }
}
