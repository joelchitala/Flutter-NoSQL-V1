import 'package:flutter_nosql_v1/plugins/nosql_database/core/NoSqlManager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Document.dart';
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
      var data = _noSQLManager.toJson(
        serialize: true,
      );

      bool savedDatabase = await writeFile(
        databasePath,
        data,
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
        ? _noSQLManager.noSQLDatabase.currentDatabase = null
        : _noSQLManager.noSQLDatabase.currentDatabase =
            await getDatabase(reference: name);

    return true;
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

  Future<Collection?> getCollection({
    required String reference,
    void Function(String errorMsg)? callback,
  }) async {
    Database? database;
    Collection? collection;

    if (reference.contains(".")) {
      database = databases[reference.split(".")[0]];
      collection = database?.collections[reference.split(".")[1]];
    } else {
      database = currentDatabase;
      collection = database?.collections[reference];
    }

    String? errorMessage;

    if (collection == null) {
      errorMessage = "Collection with the reference $reference not found";
      log(errorMessage);
      if (callback != null) callback(errorMessage);
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

  Future<bool> insertDocument({
    required String reference,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return false;

    Document document = Document(
      objectId: generateUUID(),
      timestamp: DateTime.now(),
    );
    document.addField(field: data);

    bool results = collection.addDocument(document: document);

    // if (callback != null) callback(res: (results,""));

    return results;
  }

  Future<bool> insertDocuments({
    required String reference,
    required List<Map<String, dynamic>> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return false;

    bool results = true;

    List<Document> failedDocuments = [];

    for (var field in data) {
      bool docRes = true;
      Document document = Document(
        objectId: generateUUID(),
        timestamp: DateTime.now(),
      );
      document.addField(field: field);

      docRes = collection.addDocument(document: document);

      if (!docRes) {
        failedDocuments.add(document);
        results = false;
      }
    }

    if (!results) {
      String errorMessage = "failed to insert documents: ${failedDocuments.map(
        (document) => document.toJson(
          serialize: true,
        ),
      )}";
      log(errorMessage);

      if (callback != null) callback(error: errorMessage);
    }

    return results;
  }

  Future<List<Document>> getDocument({
    required String reference,
    required bool Function(Document document) query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return [];

    return collection.documents.values.where(query).toList();
  }

  Future<Stream<List<Document>>> getDocumentStream({
    required String reference,
    required bool Function(Document document) query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return Stream<List<Document>>.value([]);

    return collection.stream(query: query);
  }

  Future<bool> updateDocument({
    required String reference,
    required bool Function(Document document) query,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return false;

    Document? document = collection.documents.values.where(query).firstOrNull;

    if (document == null) {
      if (callback != null) {
        callback(error: "Document not found");
      }
      return false;
    }

    bool results = collection.updateDocument(document: document, data: data);

    if (results) {
      if (callback != null) {
        callback(res: (true, "Document updated"));
      }
    } else {
      if (callback != null) {
        callback(
          error: "Failed to update document $document",
        );
      }
    }

    return results;
  }

  Future<bool> removeDocument({
    required String reference,
    required bool Function(Document document) query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return false;

    Document? document = collection.documents.values.where(query).firstOrNull;

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
  }

  Future<bool> removeDocuments({
    required String reference,
    required bool Function(Document document) query,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
      callback: (errorMsg) {
        if (callback != null) callback(error: errorMsg);
      },
    );

    if (collection == null) return false;

    var documents = collection.documents.values.where(query).toList();

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
      String errorMessage = "Failed to delete documents: ${failedDocuments.map(
        (document) => document.toJson(
          serialize: true,
        ),
      )}";
      log(errorMessage);

      if (callback != null) callback(error: errorMessage);
    }

    return results;
  }
}
