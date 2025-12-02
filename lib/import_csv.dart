import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads a File object from Flutter Web as text using dart:js_interop
Future<String> readFileAsText(web.File file) async {
  final reader = web.FileReader();
  final completer = Completer<String>();

  reader.onLoadEnd.listen((event) {
    final JSAny? resultJs = reader.result;
    final result = resultJs?.toDartString();
    if (result != null) {
      completer.complete(result);
    } else {
      completer.completeError('Failed to read file as text');
    }
  });

  reader.readAsText(file);
  return completer.future;
}

/// Extension helper to convert JSAny to Dart String
extension JSAnyToString on JSAny {
  String? toDartString() {
    if (this is String) return this as String;
    return null;
  }
}

/// Imports a CSV file into Firestore with duplicate prevention.
///
/// Duplicate rule: Combination of `fullName` + `phoneNumber`
Future<void> importCsvFile(
  web.File file, {
  void Function(int current, int total)? progressCallback,
}) async {
  // 1️⃣ Read CSV content
  final csvText = await readFileAsText(file);

  // 2️⃣ Parse CSV rows
  final rows = const CsvToListConverter().convert(csvText);
  if (rows.isEmpty) return;

  // 3️⃣ Extract CSV headers
  final headers = rows.first.map((h) => h.toString().trim()).toList();

  // 4️⃣ Firestore batch init
  WriteBatch batch = FirebaseFirestore.instance.batch();
  int batchCount = 0;

  final totalRows = rows.length - 1;

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    final data = Map<String, dynamic>.fromIterables(headers, row);

    // Extract key identifiers
    final fullName = data['Full Name']?.toString().trim() ?? '';
    final phoneNumber = data['Phone Number']?.toString().trim() ?? '';

    // Skip invalid entries
    if (fullName.isEmpty || phoneNumber.isEmpty) continue;

    // 5️⃣ Create deterministic document ID
    final safeName = fullName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
    final safePhone = phoneNumber.replaceAll(RegExp(r'[^0-9]+'), '');
    final docId = "${safeName}_$safePhone";

    // 6️⃣ Transform CSV row to Firestore schema
    final attendeeDoc = {
      'timestamp': data['Timestamp']?.toString() ?? '',
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': data['Email Address']?.toString() ?? '',
      'residence': data['Country & City of Residence']?.toString() ?? '',
      'ageGroup': data['Age Group']?.toString() ?? '',
      'program': data['Which part of the program are you registering for?']?.toString() ?? '',
      'attendance.bothDays': data['Will you attend on both days of the crusade?']?.toString() ?? '',
      'attendance.attendingAs': data['Are you attending as:']?.toString() ?? '',
      'church_or_ministry': data['Name of your church / ministry']?.toString() ?? '',
      'accommodation_or_special_assistence':
          data['Do you require assistance or special accommodation (e.g., wheelchair access)?']?.toString() ?? '',
      'accommodationDetails': data['If yes, specify']?.toString() ?? '',
      'heardFrom': data['How did you hear about the crusade?']?.toString() ?? '',
      'consentUpdates': data['Do you consent to be contacted for updates regarding the event? (Yes/No)']?.toString() ?? '',
      'consentMedia': data['Do you agree that photos/videos taken at the event may be used for ministry purposes? (Yes/No)']
              ?.toString() ??
          '',
    };

    final docRef = FirebaseFirestore.instance.collection('attendees').doc(docId);

    // 🔥 set(doc, merge: true) = ensures duplicates update instead of adding new documents
    batch.set(docRef, attendeeDoc, SetOptions(merge: true));

    batchCount++;
    progressCallback?.call(i, totalRows);

    if (batchCount == 500) {
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }
}
