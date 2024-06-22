import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/entity_types.dart';

enum EventType {
  databaseAdd,
  databaseUpdate,
  databaseDelete,
  collectionAdd,
  collectionUpdate,
  collectionDelete,
  documentAdd,
  documentUpdate,
  documentDelete,
}

EventType? toEntityType(String type) {
  for (var value in EventType.values) {
    if (value.toString() == type) return value;
  }
  return null;
}

class EventNotifier<T> {
  EventType event;
  T object;
  EntityType entityType;

  EventNotifier({
    required this.event,
    required this.entityType,
    required this.object,
  });

  @override
  String toString() =>
      'Event: $event, EntityType: $entityType, Object: $object';
}
