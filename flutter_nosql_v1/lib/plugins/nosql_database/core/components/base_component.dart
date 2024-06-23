import 'dart:async';

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
    Map<String, Map> objectEntries = {};

    objects.forEach(
      (key, value) {
        objectEntries.addAll(
          {
            key: value.toJson(serialize: serialize),
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
