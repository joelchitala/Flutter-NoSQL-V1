import 'dart:async';

import 'package:flutter_nosql_v1/plugins/flutter_nosql_database/core/components/sub_components/document.dart';

enum EntityType {
  database,
  collection,
  document,
  map,
}

EntityType? toEntityType(String type) {
  for (var value in EntityType.values) {
    if (value.toString() == type) return value;
  }
  return null;
}

abstract class BaseComponent<T, G extends BaseComponent<dynamic, dynamic>> {
  final String objectId;
  DateTime? timestamp;
  final _streamController = StreamController<List<G>>.broadcast();
  Map<String, G> objects = {};

  BaseComponent({
    required this.objectId,
    this.timestamp,
  }) {
    timestamp = timestamp ?? DateTime.now();
  }

  bool update({required Map<String, dynamic> data});

  bool commit({required Map<String, G> data}) {
    bool results = true;

    List<String> removeKeys = [];
    for (var entry in objects.entries) {
      var key = entry.key;
      if (!data.keys.contains(key)) {
        removeKeys.add(key);
      }
    }

    for (var key in removeKeys) {
      var obj = objects.remove(key);
      if (results) results = obj == null ? false : true;
    }

    if (!results) return false;

    List<(String, G)> addObjects = [];

    for (var entry in data.entries) {
      var key = entry.key;
      var value = objects[key];

      if (value != null) {
        if (value.runtimeType == Document) {
          if (results) {
            results = value.commit(
              data: entry.value.toJson(serialize: false)["fields"],
            );
          }
        } else {
          if (results) results = value.commit(data: entry.value.objects);
        }
        continue;
      }

      if (value == null) {
        addObjects.add((key, entry.value));
        continue;
      }
    }

    if (!results) return false;

    for (var pair in addObjects) {
      objects.addAll({pair.$1: pair.$2});
    }

    if (results) {
      broadcastObjectsChanges();
    }

    return results;
  }

  Stream<List<G>> stream({bool Function(G object)? query}) {
    if (query != null) {
      return _streamController.stream.map((objects) {
        return objects.where(query).toList();
      });
    }

    return _streamController.stream;
  }

  void broadcastObjectsChanges() {
    _streamController.add(List<G>.from(objects.values.toList()));
  }

  void disposeStreamObjects() {
    _streamController.close();
  }

  Map<String, dynamic> toJson({required bool serialize}) {
    Map<String, dynamic> objectEntries = {};

    objects.forEach(
      (key, value) {
        objectEntries.addAll(
          {
            key: Map<String, dynamic>.from(value.toJson(serialize: serialize)),
          },
        );
      },
    );

    return {
      "objectId": objectId,
      "timestamp": serialize ? timestamp?.toIso8601String() : timestamp,
      "objects": serialize ? objectEntries : objects,
    };
  }
}
