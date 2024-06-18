class LogEntries {
  DateTime? timestamp, closeTimestamp;

  Map<String, dynamic> _entries = {};

  LogEntries({this.timestamp, this.closeTimestamp}) {
    timestamp = timestamp ?? DateTime.now();
  }

  factory LogEntries.fromJson(Map<String, dynamic> data) {
    LogEntries logEntries = LogEntries(
      timestamp: DateTime.tryParse(data["timestamp"]),
      closeTimestamp: DateTime.tryParse(data["closeTimestamp"]),
    );

    logEntries._entries = data["entries"] ?? {};

    return logEntries;
  }

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp?.toIso8601String(),
        "closeTimestamp": closeTimestamp?.toIso8601String(),
        "entries": _entries,
      };
}

class Logger {
  final Map<String, LogEntries> entries = {};
  final LogEntries currentEntry = LogEntries();

  Logger._();

  static final Logger _instance = Logger._();

  factory Logger() {
    return _instance;
  }

  Future<void> initialize({required Map<String, dynamic> data}) async {
    try {
      if (data["entries"] != null) {
        data["entries"].forEach(
          (key, value) {
            LogEntries logEntries = LogEntries.fromJson(value);
            entries.addAll({key: logEntries});
          },
        );
      }
    } catch (e) {
      log(
        "Failed to initialize logger, error -> $e occured",
      );
    }
  }

  void log(String message) {
    currentEntry._entries.addAll({DateTime.now().toIso8601String(): message});
  }

  Map<String, dynamic> toJson() {
    var tempEntries = {};

    entries.forEach((key, value) {
      tempEntries.addAll({key: value.toJson()});
    });

    currentEntry.closeTimestamp = DateTime.now();

    tempEntries.addAll(
      {
        currentEntry.timestamp!.toIso8601String(): currentEntry.toJson(),
      },
    );

    return {
      "entries": tempEntries,
    };
  }
}
