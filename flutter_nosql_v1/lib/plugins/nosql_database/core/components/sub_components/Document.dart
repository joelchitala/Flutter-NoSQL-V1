import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/entity_types.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/events.dart';

class Document extends BaseComponent {
  EntityType type = EntityType.document;
  Map<String, dynamic> fields = {};

  Document({
    required super.objectId,
    super.timestamp,
  });

  factory Document.fromJson({required Map<String, dynamic> data}) {
    Document document = Document(
      objectId: data["objectId"],
      timestamp: DateTime.tryParse("${data["timestamp"]}"),
    );

    document.fields = data["fields"] ?? {};

    return document;
  }

  bool addField({
    required Map<String, dynamic> field,
    bool sanitize = false,
  }) {
    bool results = true;

    for (var key in fields.keys) {
      field.remove(key);
      if (field.containsKey(key) && results) {
        results = false;
      }
    }

    fields.addAll(field);

    broadcastObjectsChanges();

    broadcastEventStream<Map<String, dynamic>>(
      eventNotifier: EventNotifier(
        event: EventType.add,
        entityType: EntityType.map,
        object: fields,
      ),
    );

    return results;
  }

  bool updateField({
    required Map<String, dynamic> field,
  }) {
    bool results = true;

    for (var key in field.keys) {
      if (!fields.containsKey(key)) {
        field.remove(key);
        if (results) results = false;
      }
    }

    fields.addAll(field);
    broadcastObjectsChanges();

    broadcastEventStream<Map<String, dynamic>>(
      eventNotifier: EventNotifier(
        event: EventType.remove,
        entityType: EntityType.map,
        object: fields,
      ),
    );

    return results;
  }

  bool removeField({
    required List<String> keys,
  }) {
    bool results = true;

    for (var key in keys) {
      var obj = fields.remove(key);

      if (obj == null && results) {
        results = false;
      }
    }

    broadcastObjectsChanges();

    broadcastEventStream<Map<String, dynamic>>(
      eventNotifier: EventNotifier(
        event: EventType.remove,
        entityType: EntityType.map,
        object: fields,
      ),
    );

    return results;
  }

  @override
  void update({required Map<String, dynamic> data}) {
    fields = data;

    broadcastObjectsChanges();
  }

  @override
  Map<String, dynamic> toJson({required bool serialize}) {
    return super.toJson(serialize: serialize)
      ..addAll(
        {
          "type": serialize ? type.toString() : type,
          "fields": fields,
        },
      );
  }
}
