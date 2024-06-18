import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/BaseComponent.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/EntityTypes.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/Document.dart';

class Collection extends BaseComponent {
  String name;
  EntityType type = EntityType.document;
  Map<String, Document> documents;

  Collection({
    required super.objectId,
    super.timestamp,
    required this.name,
    this.documents = const {},
  });

  factory Collection.fromJson({required Map<String, dynamic> data}) {
    Map<String, Document> documents = {};

    Map<String, dynamic>? jsonDocuments = data["documents"];

    if (jsonDocuments != null) {
      try {
        for (var entry in jsonDocuments.entries) {
          var key = entry.key;
          var value = entry.value;

          Map<String, dynamic> tempEntries = {};

          value.forEach(
            (key, value) {
              tempEntries.addAll({key: value});
            },
          );

          if (tempEntries.isEmpty) continue;

          documents.addAll(
            {
              key: Document.fromJson(data: tempEntries),
            },
          );
        }
      } catch (e) {
        rethrow;
      }
    }

    Collection collection = Collection(
      objectId: data["_objectId"],
      name: data["name"],
      timestamp: DateTime.tryParse("${data["timestamp"]}"),
      documents: documents,
    );

    return collection;
  }

  bool addDocument({
    required Document document,
  }) {
    bool results = true;

    if (documents.containsKey(document.objectId)) {
      return false;
    }
    return results;
  }

  bool updateDocument({
    required Document document,
    required Map<String, dynamic> data,
  }) {
    bool results = true;

    var object = documents[document.objectId];

    if (object == null) {
      return false;
    }

    object.update(data: data);

    return results;
  }

  bool removeDocument({
    required Document document,
  }) {
    bool results = true;

    var object = documents.remove(document.objectId);

    if (object == null) {
      return false;
    }

    return results;
  }

  @override
  void update({required Map<String, dynamic> data}) {
    name = data["name"] ?? name;
  }

  @override
  Map<String, dynamic> toJson({required bool serialize}) {
    Map<String, Map> documentEntries = {};

    documents.forEach(
      (key, value) {
        documentEntries.addAll(
          {
            key: value.toJson(serialize: serialize),
          },
        );
      },
    );

    return super.toJson(serialize: serialize)
      ..addAll(
        {
          "name": name,
          "documents": serialize ? documentEntries : documents,
        },
      );
  }
}
