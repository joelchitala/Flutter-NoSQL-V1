import '../base_component.dart';
import 'collection.dart';

class Database extends BaseComponent<Database, Collection> {
  String name;
  EntityType type = EntityType.database;

  Database({
    required super.objectId,
    super.timestamp,
    required this.name,
  });

  factory Database.fromJson({required Map<String, dynamic> data}) {
    Map<String, Collection> objects = {};

    Map<String, dynamic>? jsonCollections = data["objects"];

    if (jsonCollections != null) {
      try {
        for (var entry in jsonCollections.entries) {
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
              key: Collection.fromJson(data: tempEntries),
            },
          );
        }
      } catch (e) {
        rethrow;
      }
    }

    Database database = Database(
      objectId: data["objectId"],
      name: data["name"],
      timestamp: DateTime.tryParse("${data["timestamp"]}"),
    );

    database.objects = objects;

    return database;
  }

  bool addCollection({
    required Collection collection,
  }) {
    bool results = true;
    var name = collection.name.toLowerCase();

    if (objects.containsKey(name)) {
      return false;
    }

    objects.addAll({name: collection});
    broadcastObjectsChanges();

    return results;
  }

  bool updateCollection({
    required Collection collection,
    required Map<String, dynamic> data,
  }) {
    bool results = true;
    var name = collection.name.toLowerCase();
    var object = objects[name];

    if (object == null) {
      return false;
    }

    var updateName = data["name"];
    if (updateName != null) {
      var isKey = objects.containsKey(updateName);

      if (isKey) {
        if (objects[updateName] != collection) {
          return false;
        }
      } else {
        objects[updateName] = collection;
        objects.remove(name);
      }
    }

    object.update(data: data);

    broadcastObjectsChanges();

    return results;
  }

  bool removeCollection({
    required Collection collection,
  }) {
    bool results = true;

    var name = collection.name.toLowerCase();
    var object = objects.remove(name);

    if (object == null) {
      return false;
    }
    broadcastObjectsChanges();

    return results;
  }

  @override
  bool update({required Map<String, dynamic> data}) {
    var updateName = data["name"];
    if (updateName != null) {
      name = "$updateName".toLowerCase();
    }

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
