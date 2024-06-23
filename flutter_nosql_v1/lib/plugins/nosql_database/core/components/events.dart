import 'dart:async';

import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/base_component.dart';

enum EventType {
  add,
  update,
  remove,
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
  String? message;

  EventNotifier({
    required this.event,
    required this.entityType,
    required this.object,
  });

  @override
  String toString() =>
      'Event: $event, EntityType: $entityType, Object: $object, Message: $message';
}

class EventStream {
  final _controller = StreamController<EventNotifier>.broadcast();

  EventStream._();
  static final _intance = EventStream._();
  factory EventStream() => _intance;
  Stream<EventNotifier> get eventStream => _controller.stream;

  void broadcastEventStream<T>({
    required EventNotifier<T> eventNotifier,
  }) {
    _controller.add(eventNotifier);
  }
}

class EventStreamWrapper {
  final EventStream _eventStream = EventStream();

  void broadcastEventStream<T>({
    required EventNotifier<T> eventNotifier,
  }) {
    _eventStream.broadcastEventStream<T>(eventNotifier: eventNotifier);
  }
}
