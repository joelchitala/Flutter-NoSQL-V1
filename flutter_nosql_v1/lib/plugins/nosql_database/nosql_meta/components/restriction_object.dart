String cleanRestrictionTypes({required String type}) {
  if (type.isEmpty) return type;

  if (type[0] != "_") return type;

  String str = "";

  for (var i = 0; i < type.length; i++) {
    String char = type[i];
    if (i == 0 && char == "_") continue;

    str += char;
  }

  return str;
}

List<List<T>> arrayPairer<T>(List<T> values) {
  List<List<T>> pairs = [];
  try {
    if (values.length % 2 != 0) {
      throw ArgumentError(
          "The input list must have an even number of elements");
    }

    for (int i = 0; i < values.length; i += 2) {
      pairs.add([values[i], values[i + 1]]);
    }

    for (var pair in pairs) {
      pair.sort(((a, b) => a.toString().compareTo(b.toString())));
    }
  } catch (_) {}
  return pairs;
}

enum RestrictionFieldTypes {
  fieldRestriction,
  invFieldRestriction,
}

RestrictionFieldTypes? toRestrictionFieldTypes(String type) {
  for (var value in RestrictionFieldTypes.values) {
    if (value.toString() == type) return value;
  }
  return null;
}

enum RestrictionValueTypes {
  valueRestrictionEQ,
  valueRestrictionINVEQ,
  valueRestrictionGT,
  valueRestrictionLT,
  valueRestrictionEQGT,
  valueRestrictionEQLT,
  valueRestrictionRANGE,
  valueRestrictionINVRANGE,
  valueRestrictionEQRANGE,
  valueRestrictionINVEQRANGE,
}

RestrictionValueTypes? toRestrictionValueTypes(String type) {
  for (var value in RestrictionValueTypes.values) {
    if (value.toString() == type) return value;
  }
  return null;
}

class RestrictionFieldObject {
  final String objectId;
  String key;
  RestrictionFieldTypes restrictionType;
  String? expectedType = dynamic.toString();
  bool unique;
  bool isRequired, exclude;
  bool caseSensitive;
  String collectionId;

  RestrictionFieldObject({
    required this.objectId,
    required this.key,
    required this.restrictionType,
    required this.collectionId,
    this.unique = false,
    this.expectedType,
    this.isRequired = false,
    this.exclude = false,
    this.caseSensitive = false,
  });

  factory RestrictionFieldObject.fromJson(
      {required Map<String, dynamic> data}) {
    return RestrictionFieldObject(
      objectId: data["objectId"],
      key: data["key"],
      restrictionType: toRestrictionFieldTypes(data["restrictionType"]) ??
          RestrictionFieldTypes.fieldRestriction,
      collectionId: data["collectionId"],
      unique: data["unique"],
      isRequired: data["isRequired"],
      exclude: data["exclude"],
      expectedType: data["expectedType"],
      caseSensitive: data["caseSensitive"],
    );
  }

  bool validate({
    required Map<String, dynamic> json,
    List<Map<String, dynamic>>? dataList,
    Function(String? error)? callback,
  }) {
    var data = json[key];

    String runtimeType =
        cleanRestrictionTypes(type: data.runtimeType.toString());
    String expectedRuntimeType =
        cleanRestrictionTypes(type: expectedType.toString());

    bool validRuntimeType() {
      return ((runtimeType == expectedRuntimeType) ||
          (expectedType == dynamic.toString()));
    }

    bool isUnique() {
      if (!unique || dataList == null) return true;
      return dataList.where((x) {
        if (caseSensitive) return x[key] == data;

        return x[key].toString().toLowerCase() == data.toString().toLowerCase();
      }).isEmpty;
    }

    switch (restrictionType) {
      case RestrictionFieldTypes.fieldRestriction:
        if (isRequired && data == null) {
          return false;
        }

        if (data == null) return true;

        if (!validRuntimeType()) return false;

        if (!isUnique()) return false;

        break;
      case RestrictionFieldTypes.invFieldRestriction:
        if (exclude && data != null) return false;

        if (data == null) return true;

        if (!validRuntimeType()) return false;

        if (!isUnique()) return false;

        break;

      default:
        return false;
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      "objectId": objectId,
      "key": key,
      "collectionId": collectionId,
      "restrictionType": restrictionType.toString(),
      "expectedType": expectedType.toString(),
      "unique": unique,
      "isRequired": isRequired,
      "exclude": exclude,
      "caseSensitive": caseSensitive,
    };
  }
}

class RestrictionValueObject {
  String key;
  RestrictionValueTypes restrictionType;
  List expectedValues;
  bool caseSensitive = false;

  RestrictionValueObject({
    required this.key,
    required this.restrictionType,
    required this.expectedValues,
    this.caseSensitive = false,
  });

  factory RestrictionValueObject.fromJson(
      {required Map<String, dynamic> data}) {
    return RestrictionValueObject(
      key: data["key"],
      restrictionType: toRestrictionValueTypes(data["restrictionType"]) ??
          RestrictionValueTypes.valueRestrictionEQ,
      expectedValues: data["expectedValues"],
      caseSensitive: data["caseSensitive"],
    );
  }

  bool validate({
    required Map<String, dynamic> json,
  }) {
    var data = json[key];

    var cleanedList = [];

    if (!caseSensitive) {
      if (data.runtimeType == String) data = data.toLowerCase();

      List tempArray = [];

      for (var value in expectedValues) {
        value = value.runtimeType == String ? value.toLowerCase() : value;
        tempArray.add(value);
      }
      cleanedList = tempArray;
    } else {
      cleanedList = [...expectedValues];
    }

    switch (restrictionType) {
      case RestrictionValueTypes.valueRestrictionEQ:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) return true;
        }
        return false;
      case RestrictionValueTypes.valueRestrictionINVEQ:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) return false;
        }
        return true;
      case RestrictionValueTypes.valueRestrictionGT:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) return true;
        }
        return false;
      case RestrictionValueTypes.valueRestrictionLT:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) return false;
        }
        return true;
      case RestrictionValueTypes.valueRestrictionEQGT:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) return true;
        }
        return false;
      case RestrictionValueTypes.valueRestrictionEQLT:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) return false;
        }
        return true;
      case RestrictionValueTypes.valueRestrictionRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) return true;
        }

        return false;
      case RestrictionValueTypes.valueRestrictionINVRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) return false;
        }

        return true;
      case RestrictionValueTypes.valueRestrictionEQRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data >= expectedValue1) && (data <= expectedValue2)) return true;
        }

        return false;
      case RestrictionValueTypes.valueRestrictionINVEQRANGE:
        var pairs = arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data >= expectedValue1) && (data <= expectedValue2)) {
            return false;
          }
        }

        return true;

      default:
        return false;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "key": key,
      "restrictionType": restrictionType.toString(),
      "expectedValues": expectedValues,
      "caseSensitive": caseSensitive,
    };
  }
}

class RestrictionObject {}
