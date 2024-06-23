import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/addons/nosql_transactional/nosql_transactional.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/events.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/sub_components/database.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/sub_components/document.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/meta/components/sub_components/restriction_object.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/utils/core_utils.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/utils/fileoperations.dart';
import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/nosql_manager.dart';

class NoSQLUtility {
  final NoSQLManager _noSQLManager = NoSQLManager();
  final EventStreamWrapper _streamWrapper = EventStreamWrapper();

  late final Future<bool> Function({required Future<bool> Function() func})
      _opMapper;

  NoSQLUtility() {
    _opMapper = _noSQLManager.opMapper;
  }

  Future<bool> clean({
    String databasePath = "database.json",
    required bool delete,
  }) async {
    bool results = true;

    if (delete) {
      return results;
    }

    results = await cleanFile(
      databasePath,
    );

    return results;
  }

  Future<bool> initialize({
    required String databasePath,
  }) async {
    bool results = true;

    Map<String, dynamic>? databaseData = await readFile(databasePath);
    if (databaseData != null) {
      _noSQLManager.initialize(data: databaseData);
    }
    return results;
  }

  Future<bool> commitToDisk({
    required String databasePath,
  }) async {
    bool results = true;

    results = await writeFile(
      databasePath,
      _noSQLManager.toJson(
        serialize: true,
      ),
    );
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
  }) async {
    return await _opMapper(func: () async {
      Database? db = await getDatabase(reference: name);

      if (name.isEmpty || db != null) {
        return false;
      }

      var database = Database(
        objectId: generateUUID(),
        name: name,
        timestamp: DateTime.now(),
      );

      bool results = _noSQLManager.getNoSqlDatabase().addDatabase(
            database: database,
          );

      if (results) {
        _streamWrapper.broadcastEventStream<Database>(
          eventNotifier: EventNotifier(
            event: EventType.add,
            entityType: EntityType.database,
            object: database,
          ),
        );
      }

      return results;
    });
  }

  Future<Database?> getDatabase({
    required String reference,
  }) async {
    String name = reference.toLowerCase();

    if (name.contains(".")) {
      name = reference.split(".")[0];
    }

    Database? db = _noSQLManager.getNoSqlDatabase().objects[name];
    return db;
  }

  Future<List<Database>> getDatabases({
    bool Function(Database database)? query,
  }) async {
    return query == null
        ? _noSQLManager.getNoSqlDatabase().objects.values.toList()
        : _noSQLManager.getNoSqlDatabase().objects.values.where(query).toList();
  }

  Stream<List<Database>> getDatabaseStream({
    bool Function(Database database)? query,
  }) async* {
    yield* _noSQLManager.getNoSqlDatabase().stream(query: query);
  }

  Future<bool> updateDatabase({
    required String name,
    required Map<String, dynamic> data,
  }) async {
    return await _opMapper(
      func: () async {
        Database? db = await getDatabase(reference: name);

        if (db == null) return false;

        bool results = _noSQLManager.getNoSqlDatabase().updateDatabase(
              database: db,
              data: data,
            );

        if (results) {
          _streamWrapper.broadcastEventStream<Database>(
            eventNotifier: EventNotifier(
              event: EventType.update,
              entityType: EntityType.database,
              object: db,
            ),
          );
        }

        return results;
      },
    );
  }

  Future<bool> removeDatabase({
    required String name,
  }) async {
    return await _opMapper(
      func: () async {
        Database? db = await getDatabase(reference: name);

        if (db == null) return false;

        bool results = _noSQLManager.getNoSqlDatabase().removeDatabase(
              database: db,
            );

        if (results) {
          _streamWrapper.broadcastEventStream<Database>(
            eventNotifier: EventNotifier(
              event: EventType.remove,
              entityType: EntityType.database,
              object: db,
            ),
          );
        }

        return results;
      },
    );
  }

  Future<bool> setRestrictions({
    required String reference,
    required RestrictionBuilder builder,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
        );

        if (collection == null) return false;

        bool results = _noSQLManager
            .getNoSqlDatabase()
            .metaManger
            .metaRestrictionObject
            .addRestriction(
              objectId: collection.objectId,
              restrictionBuilder: builder,
            );

        return results;
      },
    );
  }

  Future<bool> removeRestrictions({
    required String reference,
    List<String> fieldObjectKeys = const [],
    List<String> valueObjectKeys = const [],
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
        );

        if (collection == null) return false;

        var metaManger = _noSQLManager.getNoSqlDatabase().metaManger;

        bool results = metaManger.metaRestrictionObject.removeRestriction(
          objectId: collection.objectId,
          fieldObjectKeys: fieldObjectKeys,
          valueObjectKeys: valueObjectKeys,
        );

        return results;
      },
    );
  }

  Future<bool> createCollection({
    required String reference,
  }) async {
    return await _opMapper(
      func: () async {
        reference = reference.toLowerCase();

        Database? database;
        String collectionName;

        if (reference.contains(".")) {
          database = await getDatabase(reference: reference.split(".")[0]);
          collectionName = reference.split(".")[1];
        } else {
          database = _noSQLManager.getNoSqlDatabase().currentDatabase;
          collectionName = reference;
        }

        if (database == null || collectionName.isEmpty) {
          return false;
        }

        var collection = Collection(
          objectId: generateUUID(),
          name: collectionName,
        );

        bool results = database.addCollection(collection: collection);

        if (results) {
          _streamWrapper.broadcastEventStream<Collection>(
            eventNotifier: EventNotifier(
              event: EventType.add,
              entityType: EntityType.collection,
              object: collection,
            ),
          );
        }

        return results;
      },
    );
  }

  Future<Collection?> getCollection({
    required String reference,
  }) async {
    Database? database;
    Collection? collection;

    reference = reference.toLowerCase();

    if (reference.contains(".")) {
      database = await getDatabase(reference: reference);
      collection = database?.objects[reference.split(".")[1]];
    } else {
      database = _noSQLManager.getNoSqlDatabase().currentDatabase;
      collection = database?.objects[reference];
    }

    return collection;
  }

  Future<List<Collection>> getCollections({
    String? databaseName,
    bool Function(Database database)? query,
  }) async {
    Database? database;

    if (databaseName == null) {
      database = _noSQLManager.getNoSqlDatabase().currentDatabase;
    } else {
      database = await getDatabase(reference: databaseName);
    }

    if (database == null) return [];

    return database.objects.values.toList();
  }

  Stream<List<Collection>> getCollectionStream({
    String? databaseName,
    bool Function(Collection collection)? query,
  }) async* {
    Database? database = databaseName == null
        ? _noSQLManager.getNoSqlDatabase().currentDatabase
        : await getDatabase(
            reference: databaseName,
          );

    if (database == null) {
      yield* Stream<List<Collection>>.value([]);
    } else {
      yield* database.stream(query: query);
    }
  }

  Future<bool> updateCollection({
    required String reference,
    required Map<String, dynamic> data,
  }) async {
    return await _opMapper(
      func: () async {
        Database? database = await getDatabase(reference: reference);
        Collection? collection = await getCollection(reference: reference);

        if (database == null || collection == null) return false;

        bool results = database.updateCollection(
          collection: collection,
          data: data,
        );

        if (results) {
          _streamWrapper.broadcastEventStream<Collection>(
            eventNotifier: EventNotifier(
              event: EventType.update,
              entityType: EntityType.collection,
              object: collection,
            ),
          );
        }

        return results;
      },
    );
  }

  Future<bool> removeCollection({
    required String reference,
  }) async {
    return await _opMapper(
      func: () async {
        Database? database = await getDatabase(reference: reference);
        Collection? collection = await getCollection(reference: reference);

        if (database == null || collection == null) return false;

        bool results = database.removeCollection(collection: collection);

        if (results) {
          _streamWrapper.broadcastEventStream<Collection>(
            eventNotifier: EventNotifier(
              event: EventType.remove,
              entityType: EntityType.collection,
              object: collection,
            ),
          );
        }

        return results;
      },
    );
  }

  Future<bool> insertDocuments({
    required String reference,
    required List<Map<String, dynamic>> data,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
        );

        if (collection == null) return false;

        bool results = true;

        results = _noSQLManager.insertDocumentsProxy(
          collection: collection,
          data: data,
        );

        return results;
      },
    );
  }

  Future<List<Document>> getDocuments({
    required String reference,
    bool Function(Document document)? query,
  }) async {
    Collection? collection = await getCollection(
      reference: reference,
    );

    if (collection == null) return [];

    return query == null
        ? collection.objects.values.toList()
        : collection.objects.values.where(query).toList();
  }

  Stream<List<Document>> getDocumentStream({
    required String reference,
    bool Function(Document document)? query,
  }) async* {
    reference = reference.toLowerCase();

    Collection? collection = await getCollection(
      reference: reference,
    );

    if (collection == null) {
      yield* Stream<List<Document>>.value([]);
    } else {
      yield* collection.stream(query: query);
    }
  }

  Future<bool> updateDocuments({
    required String reference,
    required bool Function(Document document) query,
    required Map<String, dynamic> data,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
        );

        if (collection == null) return false;

        bool results = _noSQLManager.updateDocumentsProxy(
          collection: collection,
          query: query,
          data: data,
        );
        return results;
      },
    );
  }

  Future<bool> removeDocuments({
    required String reference,
    required bool Function(Document document) query,
  }) async {
    return await _opMapper(
      func: () async {
        Collection? collection = await getCollection(
          reference: reference,
        );

        if (collection == null) return false;

        var documents = collection.objects.values.where(query).toList();

        bool results = true;

        for (var document in documents) {
          bool docRes = collection.removeDocument(document: document);
          if (!docRes) {
            results = false;
            continue;
          }
          _streamWrapper.broadcastEventStream<Document>(
            eventNotifier: EventNotifier(
              event: EventType.remove,
              entityType: EntityType.document,
              object: document,
            ),
          );
        }
        return results;
      },
    );
  }
}
