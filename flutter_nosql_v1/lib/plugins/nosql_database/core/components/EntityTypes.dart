// ignore_for_file: file_names

enum EntityType {
  database,
  collection,
  document,
}

EntityType? toEntityType(String type) {
  for (var value in EntityType.values) {
    if (value.toString() == type) return value;
  }
  return null;
}
