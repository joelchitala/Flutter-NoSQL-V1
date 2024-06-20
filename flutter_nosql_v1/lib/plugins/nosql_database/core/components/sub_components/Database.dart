import 'dart:async';

import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/base_component.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/entity_types.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';

class Database extends BaseComponent {
  String name;
  EntityType type = EntityType.database;
  final _streamController = StreamController<List<Collection>>.broadcast();

  Map<String, Collection> collections = {};

  Database({
    required super.objectId,
    super.timestamp,
    required this.name,
  });

  factory Database.fromJson({required Map<String, dynamic> data}) {
    Map<String, Collection> collections = {};

    Map<String, dynamic>? jsonCollections = data["collections"];

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

          collections.addAll(
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

    database.collections = collections;

    return database;
  }

  Stream<List<Collection>> stream(
      {bool Function(Collection collection)? query}) {
    if (query != null) {
      return _streamController.stream.map((collections) {
        return collections.where(query).toList();
      });
    }

    return _streamController.stream;
  }

  void _broadcastChanges() {
    _streamController.add(List<Collection>.from(collections.values.toList()));
  }

  void dispose() {
    _streamController.close();
  }

  bool addCollection({
    required Collection collection,
  }) {
    bool results = true;
    var name = collection.name;

    if (collections.containsKey(name)) {
      return false;
    }

    collections.addAll({name: collection});
    _broadcastChanges();
    return results;
  }

  bool updateCollection({
    required Collection collection,
    required Map<String, dynamic> data,
  }) {
    bool results = true;

    var object = collections[collection.name];

    if (object == null) {
      return false;
    }

    object.update(data: data);
    _broadcastChanges();

    return results;
  }

  bool removeCollection({
    required Collection collection,
  }) {
    bool results = true;

    var object = collections.remove(collection.name);

    if (object == null) {
      return false;
    }
    _broadcastChanges();

    return results;
  }

  @override
  void update({required Map<String, dynamic> data}) {
    name = data["name"] ?? name;
  }

  @override
  Map<String, dynamic> toJson({required bool serialize}) {
    Map<String, Map> collectionEntries = {};

    collections.forEach(
      (key, value) {
        collectionEntries.addAll(
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
          "collections": serialize ? collectionEntries : collections,
        },
      );
  }
}
