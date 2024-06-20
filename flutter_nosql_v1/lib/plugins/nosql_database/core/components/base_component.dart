abstract class BaseComponent {
  final String objectId;
  DateTime? timestamp;

  BaseComponent({
    required this.objectId,
    this.timestamp,
  }) {
    timestamp = timestamp ?? DateTime.now();
  }

  void update({required Map<String, dynamic> data});

  Map<String, dynamic> toJson({required bool serialize}) {
    return {
      "objectId": objectId,
      "timestamp": serialize ? timestamp?.toIso8601String() : timestamp,
    };
  }
}
