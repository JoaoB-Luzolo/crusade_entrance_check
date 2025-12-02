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
    // Use JSAny? from dart:js_interop
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

/// Imports a CSV file into Firestore with optional progress callback
///
/// [file] = CSV file from <input type="file">
/// [progressCallback] = optional function(currentRow, totalRows)
Future<void> importCsvFile(
  web.File file, {
  void Function(int current, int total)? progressCallback,
}) async {
  // 1️⃣ Read CSV as text
  final csvText = await readFileAsText(file);

  // 2️⃣ Convert CSV to rows
  final rows = const CsvToListConverter().convert(csvText);

  if (rows.isEmpty) return;

  // 3️⃣ Extract headers
  final headers = rows.first.map((h) => h.toString().trim()).toList();

  // 4️⃣ Initialize Firestore batch
  WriteBatch batch = FirebaseFirestore.instance.batch();
  int batchCount = 0;

  final totalRows = rows.length - 1;

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final data = Map<String, dynamic>.fromIterables(headers, row);

    // Transform CSV row to Firestore format
    final residenceParts = data['Country & City of Residence']?.toString().split(',') ?? [];

    final attendeeDoc = {
      'timestamp': data['Timestamp']?.toString() ?? '',
      'fullName': data['Full Name']?.toString() ?? '',
      'phoneNumber': data['Phone Number']?.toString() ?? '',
      'email': data['Email Address']?.toString() ?? '',
      'residence': data['Country & City of Residence']?.toString() ?? '',
      'ageGroup': data['Age Group']?.toString() ?? '',
      'program': data['Which part of the program are you registering for?']?.toString() ?? '',
      'attendance.bothDays': data['Will you attend on both days of the crusade?']?.toString() ?? '',
      'attendance.attendingAs': data['Are you attending as:']?.toString() ?? '',
      'church_or_ministry': data['Name of your church / ministry']?.toString() ?? '',
      'accommodation_or_special_assistence': data['Do you require assistance or special accommodation (e.g., wheelchair access)?']?.toString() ?? '',
      'accommodationDetails': data['If yes, specify']?.toString() ?? '',
      'heardFrom': data['How did you hear about the crusade?']?.toString() ?? '',
      'consentUpdates': data['Do you consent to be contacted for updates regarding the event? (Yes/No)']?.toString() ?? '',
      'consentMedia': data['Do you agree that photos/videos taken at the event may be used for ministry purposes? (Yes/No)']?.toString() ?? '',
    };

    final docRef = FirebaseFirestore.instance.collection('attendees').doc();
    batch.set(docRef, attendeeDoc);
    batchCount++;

    // Call progress callback if provided
    progressCallback?.call(i, totalRows);

    // Commit batch every 500 writes
    if (batchCount == 500) {
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      batchCount = 0;
    }
  }

  // Commit any remaining documents
  if (batchCount > 0) {
    await batch.commit();
  }
}
