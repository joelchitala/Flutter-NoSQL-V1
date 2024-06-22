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
