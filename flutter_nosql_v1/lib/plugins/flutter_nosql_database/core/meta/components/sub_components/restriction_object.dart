import 'dart:math';

String _cleanRestrictionTypes({required String type}) {
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

List<List<T>> _arrayPairer<T>(List<T> values) {
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

String _generateFullTimeStamp() {
  DateTime now = DateTime.now();
  return "${now.second}:${now.minute}:${now.hour}::${now.day}-${now.month}-${now.year}";
}

String _generateUUID({int max = 10000}) {
  return "${Random().nextInt(max)}_${_generateFullTimeStamp()}";
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
  eq,
  inveq,
  gt,
  lt,
  eqgt,
  eqlt,
  range,
  invrange,
  eqrange,
  inveqrange,
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

  RestrictionFieldObject({
    required this.objectId,
    required this.key,
    required this.restrictionType,
    this.unique = false,
    this.expectedType,
    this.isRequired = false,
    this.exclude = false,
    this.caseSensitive = false,
  });

  factory RestrictionFieldObject.fromJson({
    required Map<String, dynamic> data,
  }) {
    return RestrictionFieldObject(
      objectId: data["objectId"],
      key: data["key"],
      restrictionType: toRestrictionFieldTypes(data["restrictionType"]) ??
          RestrictionFieldTypes.fieldRestriction,
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
    String? specificKey,
  }) {
    var data = json[key];

    String runtimeType =
        _cleanRestrictionTypes(type: data.runtimeType.toString());
    String expectedRuntimeType =
        _cleanRestrictionTypes(type: expectedType.toString());

    bool validRuntimeType() {
      bool res = ((runtimeType == expectedRuntimeType) ||
          (expectedType == dynamic.toString()));

      return res;
    }

    bool isUnique() {
      if (!unique || dataList == null) return true;

      var obj = dataList.where((x) {
        var temp = specificKey == null ? x[key] : x[specificKey][key];

        if (caseSensitive) return temp == data;

        return "$temp".toLowerCase() == "$data".toLowerCase();
      }).firstOrNull;

      bool res = obj == null ? true : false;

      return res;
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
  final String objectId;
  String key;
  RestrictionValueTypes restrictionType;
  List expectedValues;
  bool caseSensitive = false;

  RestrictionValueObject({
    required this.objectId,
    required this.key,
    required this.restrictionType,
    required this.expectedValues,
    this.caseSensitive = false,
  });

  factory RestrictionValueObject.fromJson({
    required Map<String, dynamic> data,
  }) {
    return RestrictionValueObject(
      objectId: data["objectId"],
      key: data["key"],
      restrictionType: toRestrictionValueTypes(
            data["restrictionType"],
          ) ??
          RestrictionValueTypes.eq,
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
      case RestrictionValueTypes.eq:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) return true;
        }

        return false;
      case RestrictionValueTypes.inveq:
        for (var expectedValue in cleanedList) {
          if (data == expectedValue) {
            return false;
          }
        }
        return true;
      case RestrictionValueTypes.gt:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) return true;
        }

        return false;
      case RestrictionValueTypes.lt:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) {
            return false;
          }
        }

        return true;
      case RestrictionValueTypes.eqgt:
        for (var expectedValue in cleanedList) {
          if (data >= expectedValue) return true;
        }

        return false;
      case RestrictionValueTypes.eqlt:
        for (var expectedValue in cleanedList) {
          if (data > expectedValue) {
            return false;
          }
        }

        return true;
      case RestrictionValueTypes.range:
        var pairs = _arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) return true;
        }

        return false;
      case RestrictionValueTypes.invrange:
        var pairs = _arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data > expectedValue1) && (data < expectedValue2)) {
            return false;
          }
        }

        return true;
      case RestrictionValueTypes.eqrange:
        var pairs = _arrayPairer(cleanedList);

        for (var pair in pairs) {
          var expectedValue1 = pair[0];
          var expectedValue2 = pair[1];

          if ((data >= expectedValue1) && (data <= expectedValue2)) return true;
        }

        return false;
      case RestrictionValueTypes.inveqrange:
        var pairs = _arrayPairer(cleanedList);

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
      "objectId": objectId,
      "key": key,
      "restrictionType": restrictionType.toString(),
      "expectedValues": expectedValues,
      "caseSensitive": caseSensitive,
    };
  }
}

class RestrictionBuilder {
  final Map<String, RestrictionFieldObject> fieldObjects = {};
  final Map<String, RestrictionValueObject> valueObjects = {};

  RestrictionBuilder();

  factory RestrictionBuilder.fromJson({required Map<String, dynamic> data}) {
    RestrictionBuilder builder = RestrictionBuilder();

    Map<String, dynamic>? fieldObjectsData = data["fieldObjects"];
    var valueObjectsData = data["valueObjects"];

    fieldObjectsData?.forEach(
      (key, value) {
        builder.fieldObjects.addAll(
          {
            key: RestrictionFieldObject.fromJson(data: value),
          },
        );
      },
    );

    valueObjectsData?.forEach(
      (key, value) {
        builder.valueObjects.addAll(
          {
            key: RestrictionValueObject.fromJson(data: value),
          },
        );
      },
    );

    return builder;
  }

  List<RestrictionFieldObject> get fieldObjectsList =>
      fieldObjects.values.toList();

  List<RestrictionValueObject> get valueObjectsList =>
      valueObjects.values.toList();

  bool addFieldObject({
    required RestrictionFieldObject object,
  }) {
    bool results = true;

    if (fieldObjects[object.key] != null) {
      return false;
    }

    fieldObjects[object.key] = object;

    return results;
  }

  bool addValueObject({
    required RestrictionValueObject object,
  }) {
    bool results = true;

    if (valueObjects[object.key] != null) {
      return false;
    }

    valueObjects[object.key] = object;

    return results;
  }

  RestrictionFieldObject? getFieldObject(String key) {
    return fieldObjects.values.where((x) => x.key == key).firstOrNull;
  }

  RestrictionValueObject? getValueObject(String key) {
    return valueObjects.values.where((x) => x.key == key).firstOrNull;
  }

  RestrictionBuilder addField({
    required String key,
    bool unique = false,
    Type expectedType = dynamic,
    bool exclude = false,
    bool caseSensitive = false,
    RestrictionFieldTypes type = RestrictionFieldTypes.fieldRestriction,
  }) {
    addFieldObject(
      object: RestrictionFieldObject(
        objectId: _generateUUID(),
        key: key,
        restrictionType: type,
        unique: unique,
        expectedType: expectedType.toString(),
        exclude: exclude,
        caseSensitive: caseSensitive,
      ),
    );
    return this;
  }

  bool removeField({
    required String key,
  }) {
    bool results = true;

    if (fieldObjects.remove(key) == null) {
      return false;
    }

    return results;
  }

  RestrictionBuilder addValue({
    required String key,
    required List expectedValues,
    bool caseSensitive = false,
    RestrictionValueTypes type = RestrictionValueTypes.eq,
  }) {
    addValueObject(
      object: RestrictionValueObject(
        objectId: _generateUUID(),
        key: key,
        restrictionType: type,
        expectedValues: expectedValues,
        caseSensitive: caseSensitive,
      ),
    );
    return this;
  }

  bool removeValue({
    required String key,
  }) {
    bool results = true;
    if (valueObjects.remove(key) == null) {
      return false;
    }

    return results;
  }

  Map<String, dynamic> toJson({
    required bool serialize,
  }) {
    Map<String, dynamic> fieldObjectsJson = {};

    for (var object in fieldObjects.entries) {
      var key = object.key;
      var value = object.value;

      fieldObjectsJson.addAll({key: value.toJson()});
    }

    Map<String, dynamic> valueObjectsJson = {};

    for (var object in valueObjects.entries) {
      var key = object.key;
      var value = object.value;

      valueObjectsJson.addAll({key: value.toJson()});
    }

    return {
      "fieldObjects": serialize ? fieldObjectsJson : fieldObjects,
      "valueObjects": serialize ? valueObjectsJson : valueObjects,
    };
  }
}
