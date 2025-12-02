import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirestore() async {
  try {
    CollectionReference testCollection =
        FirebaseFirestore.instance.collection('test');

    await testCollection.add({
      'message': 'Hello from Flutter Web!',
      'timestamp': FieldValue.serverTimestamp(),
    });

    print('✅ Data added successfully!');
  } catch (e, stack) {
    print('❌ Error connecting to Firestore: $e');
    print(stack);
  }
}
