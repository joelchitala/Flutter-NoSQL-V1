import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/document.dart';

class Collection extends BaseComponent<Collection, Document> {
  String name;
  EntityType type = EntityType.collection;

  Collection({
    required super.objectId,
    super.timestamp,
    required this.name,
  });

  factory Collection.fromJson({required Map<String, dynamic> data}) {
    Map<String, Document> objects = {};

    Map<String, dynamic>? jsonDocuments = data["objects"];

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

          objects.addAll(
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
      objectId: data["objectId"],
      name: data["name"],
      timestamp: DateTime.tryParse("${data["timestamp"]}"),
    );

    collection.objects = objects;

    return collection;
  }

  bool addDocument({
    required Document document,
  }) {
    bool results = true;

    if (objects.containsKey(document.objectId)) {
      return false;
    }

    objects.addAll({document.objectId: document});

    broadcastObjectsChanges();

    return results;
  }

  bool updateDocument({
    required Document document,
    required Map<String, dynamic> data,
  }) {
    bool results = true;

    var object = objects[document.objectId];

    if (object == null) {
      return false;
    }

    object.update(data: data);

    broadcastObjectsChanges();

    return results;
  }

  bool removeDocument({
    required Document document,
  }) {
    bool results = true;

    var object = objects.remove(document.objectId);

    if (object == null) {
      return false;
    }

    broadcastObjectsChanges();

    return results;
  }

  @override
  bool update({required Map<String, dynamic> data}) {
    name = data["name"] ?? name;

    return true;
  }

  @override
  Map<String, dynamic> toJson({required bool serialize}) {
    return super.toJson(serialize: serialize)
      ..addAll(
        {
          "name": name,
          "type": serialize ? type.toString() : type,
        },
      );
  }
}
