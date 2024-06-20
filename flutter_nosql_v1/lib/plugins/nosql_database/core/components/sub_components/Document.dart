import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/BaseComponent.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/EntityTypes.dart';

class Document extends BaseComponent {
  EntityType type = EntityType.collection;
  Map<String, dynamic> fields = {};

  Document({
    required super.objectId,
    super.timestamp,
  });

  factory Document.fromJson({required Map<String, dynamic> data}) {
    Document document = Document(
      objectId: data["_objectId"],
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
      if (sanitize) {
        field.remove(key);
      } else {
        if (field.containsKey(key)) {
          return false;
        }
      }
    }

    fields.addAll(field);

    return results;
  }

  bool updateField({
    required Map<String, dynamic> field,
    bool sanitize = false,
  }) {
    bool results = true;

    for (var key in field.keys) {
      if (!fields.containsKey(key)) {
        if (sanitize) {
          field.remove(key);
        } else {
          return false;
        }
      }
    }

    fields.addAll(field);

    return results;
  }

  bool removeField({
    required List<String> keys,
    bool sanitize = false,
  }) {
    bool results = true;

    if (!sanitize) {
      for (var key in keys) {
        if (!fields.containsKey(key)) {
          return false;
        }
      }
    }

    for (var key in keys) {
      fields.remove(key);
    }

    return results;
  }

  @override
  void update({required Map<String, dynamic> data}) {
    fields.addAll(data);
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
