import 'package:intl/intl.dart';

class Utils {
  static const DEFAULT_DATE_FORMAT_FILE = 'yyyy-MM-dd_HH.mm.ss';
  static const DEFAULT_DATE_FORMAT_DISPLAY = 'yyyy-MM-dd HH:mm:ss';

  // Prints a string with the given prefix, dateFormat, and date, if supplied.
  /// Defaults:
  ///   prefix: ''
  ///   dateFormat: DEFAULT_DATE_FORMAT_DISPLAY (e.g. yyyy-MM-dd HH:mm:ss)
  ///   date: current date and time
  static void printTime({String prefix, String dateFormat, DateTime date}) {
    print(createDateString(prefix: prefix, dateFormat: dateFormat, date: date));
  }

  // Returns a string with the given prefix, dateFormat, and date, if supplied.
  /// Defaults:
  ///   prefix: ''
  ///   dateFormat: DEFAULT_DATE_FORMAT_FILE (e.g. yyyy-MM-dd_HH.mm.ss)
  ///   date: current date and time
  static String createDateString(
      {String prefix, String dateFormat, DateTime date}) {
    final formattedDate = DateFormat(dateFormat ?? DEFAULT_DATE_FORMAT_FILE)
        .format(date ?? DateTime.now());
    return '${prefix ?? ""}_$formattedDate';
  }

  static String generateUniqueName(String prefix, List<String> excludedNames) {
    prefix = prefix ?? 'New';
    int i = 1;
    String name = '$prefix ' + i.toString();
    while (excludedNames.contains(name)) {
      name = '$prefix ' + (++i).toString();
    }
    return name;
  }
}