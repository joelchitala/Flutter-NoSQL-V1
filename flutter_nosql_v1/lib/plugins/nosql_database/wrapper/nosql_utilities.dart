import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/document.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/nosql_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/components/restriction_object.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/fileoperations.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/utils.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/logger.dart';

class NoSQLUtility extends Logging {
  final NoSQLManager _noSQLManager = NoSQLManager();

  late final Future<bool> Function({required Future<bool> Function() func})
      _opMapper;

  NoSQLUtility() {
    _opMapper = _noSQLManager.opMapper;
  }

  Future<bool> clean({
    String databasePath = "database.json",
    String loggerPath = "logger.json",
    required bool delete,
  }) async {
    bool results = true;

    if (delete) {
      return results;
    }

    bool savedDatabase = await cleanFile(
      databasePath,
    );

    bool savedLogger = await cleanFile(
      loggerPath,
    );

    if (!savedDatabase) {
      log("Failed to clean database to path $databasePath");
    }

    if (!savedLogger) {
      log("Failed to clean logger to path $loggerPath");
    }

    return results;
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
        _noSQLManager.toJson(
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

  Future<Map<String, dynamic>> noSQLDatabaseToJson({
    required bool serialize,
  }) async {
    return _noSQLManager.toJson(serialize: serialize);
  }

  Future<bool> setCurrentDatabase({String? name}) async {
    name == null
        ? _noSQLManager.getNoSqlDatabase().currentDatabase = null
        : _noSQLManager.getNoSqlDatabase().currentDatabase =
            await getDatabase(reference: name);

    return true;
  }

  NoSQLTransactional transactional(Future<void> Function() executeFunction) {
    NoSQLTransactional sqlTransactional = NoSQLTransactional(
      executeFunction: executeFunction,
    );

    return sqlTransactional;
  }

  Future<bool> createDatabase({
    required String name,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(func: () async {
      name = name.toLowerCase();

      Database? db = _noSQLManager.getNoSqlDatabase().databases[name];
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

      bool results =
          _noSQLManager.getNoSqlDatabase().addDatabase(database: database);

      if (results) {
        successMessage = "$name database successfully created";
        log(successMessage);
        if (callback != null) callback(res: (true, successMessage));
      }

      return true;
    });
  }

  Future<Database?> getDatabase({
    required String reference,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    String name = reference.toLowerCase();

    if (reference.contains(".")) {
      name = reference.split(".")[0];
    }
    Database? db =
        _noSQLManager.getNoSqlDatabase().databases[name.toLowerCase()];
    return db;
  }

  Future<List<Database>> getDatabases({
    bool Function(Database database)? query,
  }) async {
    return query == null
        ? _noSQLManager.getNoSqlDatabase().databases.values.toList()
        : _noSQLManager
            .getNoSqlDatabase()
            .databases
            .values
            .where(query)
            .toList();
  }

  Stream<List<Database>> getDatabaseStream({
    bool Function(Database database)? query,
  }) async* {
    yield* _noSQLManager.getNoSqlDatabase().stream(query: query);
  }

  Future<bool> deleteDatabase({
    required String name,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Database? db = _noSQLManager.getNoSqlDatabase().databases[name];

        String? successMessage, errorMessage;

        try {
          if (db == null) {
            errorMessage =
                "Failed to delete $name database, database does not exists";

            log(errorMessage);
            if (callback != null) callback(error: errorMessage);

            return false;
          }
          bool results =
              _noSQLManager.getNoSqlDatabase().removeDatabase(database: db);

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
      },
    );
  }

  Future<bool> setRestrictions({
    required String reference,
    required RestrictionBuilder builder,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        bool results = _noSQLManager
            .getNoSqlDatabase()
            .metaManger
            .metaRestrictionObject
            .addRestriction(
              objectId: collection.objectId,
              restrictionBuilder: builder,
              callback: callback,
            );

        return results;
      },
    );
  }

  Future<bool> removeRestrictions({
    required String reference,
    List<String> fieldObjectKeys = const [],
    List<String> valueObjectKeys = const [],
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        var metaManger = _noSQLManager.getNoSqlDatabase().metaManger;

        bool results = metaManger.metaRestrictionObject.removeRestriction(
          objectId: collection.objectId,
          fieldObjectKeys: fieldObjectKeys,
          valueObjectKeys: valueObjectKeys,
          callback: callback,
        );

        return results;
      },
    );
  }

  Future<bool> createCollection({
    required String reference,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Database? database;
        String collectionName;

        reference = reference.toLowerCase();

        if (reference.contains(".")) {
          database = await getDatabase(reference: reference.split(".")[0]);
          collectionName = reference.split(".")[1];
        } else {
          database = _noSQLManager.getNoSqlDatabase().currentDatabase;
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
          errorMessage =
              "Failed to add Collection with the reference $reference";
          log(errorMessage);
          if (callback != null) callback(error: errorMessage);
        }

        return results;
      },
    );
  }

  Future<Collection?> getCollection({
    required String reference,
    void Function(String errorMsg)? callback,
  }) async {
    Database? database;
    Collection? collection;

    reference = reference.toLowerCase();

    if (reference.contains(".")) {
      database =
          _noSQLManager.getNoSqlDatabase().databases[reference.split(".")[0]];
      collection = database?.objects[reference.split(".")[1]];
    } else {
      database = _noSQLManager.getNoSqlDatabase().currentDatabase;
      collection = database?.objects[reference];
    }

    String? errorMessage;

    if (collection == null) {
      errorMessage = "Collection with the reference $reference not found";
      log(errorMessage);
      if (callback != null) callback(errorMessage);
    }

    return collection;
  }

  Future<List<Collection>> getCollections({
    String? databaseName,
    void Function(String errorMsg)? callback,
    bool Function(Database database)? query,
  }) async {
    Database? database;

    if (databaseName == null) {
      database = _noSQLManager.getNoSqlDatabase().currentDatabase;
    } else {
      database = _noSQLManager
          .getNoSqlDatabase()
          .databases[databaseName.toLowerCase()];
    }

    if (database == null) {
      var msg =
          "Database with the name $databaseName not found and current database is null";
      if (callback != null) {
        callback(
          msg,
        );
      }
      log(msg);

      return [];
    }
    return database.objects.values.toList();
  }

  Stream<List<Collection>> getCollectionStream({
    String? databaseName,
    bool Function(Collection collection)? query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async* {
    Database? database = databaseName == null
        ? _noSQLManager.getNoSqlDatabase().currentDatabase
        : await getDatabase(
            reference: databaseName,
            callback: ({error, res}) {
              if (callback != null) callback(error: error);
            },
          );

    if (database == null) {
      yield* Stream<List<Collection>>.value([]);
    } else {
      yield* database.stream(query: query);
    }
  }

  Future<bool> deleteCollection({
    required String reference,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
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
      },
    );
  }

  Future<bool> insertDocument({
    required String reference,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        bool results = _noSQLManager.insertDocumentProxy(
          collection: collection,
          data: data,
          callback: callback,
        );

        return results;
      },
    );
  }

  Future<bool> insertDocuments({
    required String reference,
    required List<Map<String, dynamic>> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        bool results = true;

        List<Document> failedDocuments = [];

        results = _noSQLManager.insertDocumentsProxy(
          collection: collection,
          data: data,
          callback: callback,
        );

        if (!results) {
          String errorMessage =
              "failed to insert documents: ${failedDocuments.map(
            (document) => document.toJson(
              serialize: true,
            ),
          )}";
          log(errorMessage);

          if (callback != null) callback(error: errorMessage);
        }

        return results;
      },
    );
  }

  Future<List<Document>> getDocuments({
    required String reference,
    bool Function(Document document)? query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return [];

    return query == null
        ? collection.objects.values.toList()
        : collection.objects.values.where(query).toList();
  }

  Stream<List<Document>> getDocumentStream({
    required String reference,
    bool Function(Document document)? query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async* {
    reference = reference.toLowerCase();

    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) {
      yield* Stream<List<Document>>.value([]);
    } else {
      yield* collection.stream(query: query);
    }
  }

  Future<bool> updateDocument({
    required String reference,
    required bool Function(Document document) query,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        bool results = _noSQLManager.updateDocumentProxy(
          collection: collection,
          query: query,
          data: data,
          callback: callback,
        );
        return results;
      },
    );
  }

  Future<bool> updateDocuments({
    required String reference,
    required bool Function(Document document) query,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        bool results = _noSQLManager.updateDocumentsProxy(
          collection: collection,
          query: query,
          data: data,
          callback: callback,
        );
        return results;
      },
    );
  }

  Future<bool> removeDocument({
    required String reference,
    required bool Function(Document document) query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        Document? document = collection.objects.values.where(query).firstOrNull;

        if (document == null) {
          if (callback != null) {
            callback(error: "Document not found");
          }
          return false;
        }

        bool results = collection.removeDocument(document: document);

        if (results) {
          if (callback != null) {
            callback(res: (true, "Document deleted"));
          }
        } else {
          if (callback != null) {
            callback(
              error: "Failed to delete document $document",
            );
          }
        }

        return true;
      },
    );
  }

  Future<bool> removeDocuments({
    required String reference,
    required bool Function(Document document) query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
          callback: (errorMsg) {
            if (callback != null) callback(error: errorMsg);
          },
        );

        if (collection == null) return false;

        var documents = collection.objects.values.where(query).toList();

        bool results = true;

        List<Document> failedDocuments = [];

        for (var document in documents) {
          bool docRes = collection.removeDocument(document: document);

          if (!docRes) {
            failedDocuments.add(document);
            results = false;
          }
        }

        if (!results) {
          String errorMessage =
              "Failed to delete documents: ${failedDocuments.map(
            (document) => document.toJson(
              serialize: true,
            ),
          )}";
          log(errorMessage);

          if (callback != null) callback(error: errorMessage);
        }

        return results;
      },
    );
  }
}
