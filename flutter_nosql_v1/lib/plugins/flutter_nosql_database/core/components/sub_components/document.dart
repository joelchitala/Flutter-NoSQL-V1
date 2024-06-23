import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/base_component.dart';

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

    return results;
  }

  @override
  bool update({required Map<String, dynamic> data}) {
    var updateData = Map<String, dynamic>.from(data);
    bool results = true;

    for (var field in data.entries) {
      var key = field.key;
      var value = field.value;

      if (key.toLowerCase() == "!unset") {
        updateData.remove(key);

        if (value.runtimeType == List<String>) {
          if (results) results = removeField(keys: value);
        } else {
          throw "!unset key expects value with the runtime type List<String> not ${value.runtimeType} ($value)";
        }
      }
    }
    fields.addAll(updateData);

    broadcastObjectsChanges();

    return results;
  }

  @override
  Map<String, dynamic> toJson({required bool serialize}) {
    return super.toJson(serialize: serialize)
      ..addAll(
        {
          "type": serialize ? type.toString() : type,
          "fields": serialize ? fields : fields,
        },
      );
  }
}
