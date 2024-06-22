import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/entity_types.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/events.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/document.dart';

class Collection extends BaseComponent<Collection, Document> {
  // final _streamController = StreamController<List<Document>>.broadcast();
  String name;
  EntityType type = EntityType.collection;
  // Map<String, Document> objects = {};

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

  // Stream<List<Document>> stream({bool Function(Document document)? query}) {
  //   if (query != null) {
  //     return _streamController.stream.map((objects) {
  //       return objects.where(query).toList();
  //     });
  //   }

  //   return _streamController.stream;
  // }

  // void _broadcastChanges() {
  //   _streamController.add(List<Document>.from(objects.values.toList()));
  // }

  // void dispose() {
  //   _streamController.close();
  // }

  bool addDocument({
    required Document document,
  }) {
    bool results = true;

    if (objects.containsKey(document.objectId)) {
      return false;
    }

    objects.addAll({document.objectId: document});

    broadcastObjectsChanges();

    broadcastEventStream<Document>(
      eventNotifier: EventNotifier(
        event: EventType.add,
        entityType: EntityType.document,
        object: document,
      ),
    );

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
    broadcastEventStream<Document>(
      eventNotifier: EventNotifier(
        event: EventType.update,
        entityType: EntityType.document,
        object: document,
      ),
    );

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
    broadcastEventStream<Document>(
      eventNotifier: EventNotifier(
        event: EventType.remove,
        entityType: EntityType.document,
        object: document,
      ),
    );

    return results;
  }

  @override
  void update({required Map<String, dynamic> data}) {
    name = data["name"] ?? name;
  }

  @override
  Map<String, dynamic> toJson({required bool serialize}) {
    Map<String, Map> documentEntries = {};

    objects.forEach(
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
          "type": serialize ? type.toString() : type,
          "objects": serialize ? documentEntries : objects,
        },
      );
  }
}
