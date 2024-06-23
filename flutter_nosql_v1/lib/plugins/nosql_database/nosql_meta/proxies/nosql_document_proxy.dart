import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/document.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/nosql_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/components/restriction_object.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/utils.dart';

mixin NoSqlDocumentProxy {
  RestrictionBuilder? getFieldObjectsByCollection({
    required Collection collection,
  }) {
    return NoSQLManager()
        .getNoSqlDatabase()
        .metaManger
        .metaRestrictionObject
        .getRestrictionBuilder(
          objectId: collection.objectId,
        );
  }

  List<Map<String, dynamic>> generateDocumentList({
    required Collection collection,
  }) {
    return collection.objects.values
        .map(
          (e) => e.toJson(
            serialize: false,
          ),
        )
        .toList();
  }

  bool fieldValidator({
    required Map<String, dynamic> data,
    required List<RestrictionFieldObject> objects,
    List<Map<String, dynamic>> dataList = const [],
    String? specificKey,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    bool results = true;

    for (var object in objects) {
      results = object.validate(
        json: data,
        dataList: dataList,
        specificKey: specificKey,
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

  bool valueValidator({
    required Map<String, dynamic> data,
    required List<RestrictionValueObject> objects,
    void Function({String? error, (bool res, String msg)? res})? callback,
  }) {
    bool results = true;

    for (var object in objects) {
      results = object.validate(
        json: data,
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

    var builder = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    results = fieldValidator(
      data: data,
      objects: builder?.fieldObjectsList ?? [],
      specificKey: "fields",
      dataList: dataList,
      callback: callback,
    );

    results = valueValidator(
      data: data,
      objects: builder?.valueObjectsList ?? [],
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

    var builder = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    for (var field in data) {
      results = fieldValidator(
        data: field,
        objects: builder?.fieldObjectsList ?? [],
        dataList: dataList,
        specificKey: "fields",
        callback: callback,
      );

      results = valueValidator(
        data: field,
        objects: builder?.valueObjectsList ?? [],
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
    Document? document = collection.objects.values.where(query).firstOrNull;

    if (document == null) {
      if (callback != null) {
        callback(error: "Document not found");
      }
      return false;
    }

    var builder = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    bool results = true;

    results = fieldValidator(
      data: data,
      objects: builder?.fieldObjectsList ?? [],
      dataList: dataList,
      specificKey: "fields",
      callback: callback,
    );

    results = valueValidator(
      data: data,
      objects: builder?.valueObjectsList ?? [],
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
    List<Document> documents = collection.objects.values
        .where(
          query,
        )
        .toList();

    var builder = getFieldObjectsByCollection(collection: collection);

    var dataList = generateDocumentList(collection: collection);

    bool results = true;

    var updatedDocuments = [];
    var failedDocuments = [];

    results = fieldValidator(
      data: data,
      objects: builder?.fieldObjectsList ?? [],
      dataList: dataList,
      specificKey: "fields",
      callback: callback,
    );

    if (!results) {
      return false;
    }

    results = valueValidator(
      data: data,
      objects: builder?.valueObjectsList ?? [],
      callback: callback,
    );

    if (!results) {
      return false;
    }

    for (var document in documents) {
      bool res = collection.updateDocument(
        document: document,
        data: data,
      );

      if (!res) {
        failedDocuments.add(document);

        results = false;
        break;
      }

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
