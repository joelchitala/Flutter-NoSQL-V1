import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/document.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/components/restriction_object.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/nosql_meta_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/utils.dart';

mixin NoSqlDocumentProxy {
  final NoSqlMetaManager _metaManager = NoSqlMetaManager();

  List<RestrictionFieldObject> getFieldObjectsByCollection({
    required Collection collection,
  }) {
    return _metaManager.metaObject.getFieldObjects(
      query: (object) {
        return object.collectionId == collection.objectId;
      },
    );
  }

  List<Map<String, dynamic>> generateDocumentList({
    required Collection collection,
  }) {
    return collection.documents.values
        .map(
          (e) => e.toJson(
            serialize: false,
          ),
        )
        .toList();
  }

  bool validate({
    required Map<String, dynamic> data,
    required List<RestrictionFieldObject> objects,
    List<Map<String, dynamic>> dataList = const [],
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    bool results = true;

    for (var object in objects) {
      results = object.validate(
        json: data,
        dataList: dataList,
        callback: (error) {
          if (callback != null) callback(error: error);
        },
      );
      if (!results) {
        return false;
      }
    }

    return results;
  }

  bool insertDocumentProxy({
    required Collection collection,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    bool results = true;

    var objects = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    results = validate(
      data: data,
      objects: objects,
      dataList: dataList,
      callback: callback,
    );

    if (!results) return results;

    Document document = Document(
      objectId: generateUUID(),
      timestamp: DateTime.now(),
    );
    document.addField(field: data);

    results = collection.addDocument(document: document);

    return results;
  }

  bool insertDocumentsProxy({
    required Collection collection,
    required List<Map<String, dynamic>> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    bool results = true;

    var objects = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    for (var field in data) {
      results = validate(
        data: field,
        objects: objects,
        dataList: dataList,
        callback: callback,
      );

      if (!results) return results;

      Document document = Document(
        objectId: generateUUID(),
        timestamp: DateTime.now(),
      );
      document.addField(field: field);
      results = collection.addDocument(document: document);

      if (!results) return false;
    }

    return results;
  }

  bool updateDocumentProxy({
    required Collection collection,
    required bool Function(Document document) query,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    Document? document = collection.documents.values.where(query).firstOrNull;

    if (document == null) {
      if (callback != null) {
        callback(error: "Document not found");
      }
      return false;
    }

    var objects = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    bool results = true;

    results = validate(
      data: data,
      objects: objects,
      dataList: dataList,
      callback: callback,
    );

    if (!results) return false;

    results = collection.updateDocument(
      document: document,
      data: data,
    );

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

  bool updateDocumentsProxy({
    required Collection collection,
    required bool Function(Document document) query,
    required Map<String, dynamic> data,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    List<Document> documents = collection.documents.values
        .where(
          query,
        )
        .toList();

    var objects = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    bool results = true;

    var updatedDocuments = [];
    var failedDocuments = [];

    for (var document in documents) {
      results = validate(
        data: data,
        objects: objects,
        dataList: dataList,
      );

      if (!results) {
        failedDocuments.add(document);
        break;
      }

      results = collection.updateDocument(
        document: document,
        data: data,
      );
      updatedDocuments.add(document);
    }

    if (results) {
      if (callback != null) {
        callback(
          res: (
            true,
            "The following documents were updated.\n$updatedDocuments"
          ),
        );
      }
    } else {
      if (callback != null) {
        callback(
          error: "Failed to update the following documents./n $failedDocuments",
        );
      }
    }

    return results;
  }
}
