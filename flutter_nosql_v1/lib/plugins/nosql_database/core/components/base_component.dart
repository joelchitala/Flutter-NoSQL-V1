import 'dart:async';

abstract class BaseComponent<T, G> {
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

  void update({required Map<String, dynamic> data});

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

  void disposeObjects() {
    _streamController.close();
  }

  Map<String, dynamic> toJson({required bool serialize}) {
    return {
      "objectId": objectId,
      "timestamp": serialize ? timestamp?.toIso8601String() : timestamp,
    };
  }
}
