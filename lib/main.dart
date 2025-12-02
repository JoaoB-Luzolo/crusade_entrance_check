import 'package:crusade_entrance_check_app/background_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:web/web.dart' as web;
import 'import_csv.dart';
import 'admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registration Check App',
      debugShowCheckedModeBanner: false,

      // Global Theme
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(179, 36, 35, 35),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 3,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),

      // Apply background to every page
      builder: (context, child) {
        return AppBackground(
          child: child!,
        );
      },

      home: const HomeScreen(),
    );
  }
}


/// Home Screen with polished UI
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Check App'),
        centerTitle: true,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CsvImportScreen()),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: const [
                          Icon(Icons.upload_file, size: 48, color: Colors.blue),
                          SizedBox(height: 12),
                          Text(
                            'Import CSV',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboard()),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: const [
                          Icon(Icons.dashboard, size: 48, color: Colors.blue),
                          SizedBox(height: 12),
                          Text(
                            'Dashboard',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CSV Import Screen with polished UI
class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  String status = "No file selected";
  bool isImporting = false;

  void pickFile() {
    final uploadInput = web.HTMLInputElement();
    uploadInput.type = 'file';
    uploadInput.accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files?.item(0);
      if (file == null) {
        setState(() => status = "No file selected");
        return;
      }

      setState(() {
        isImporting = true;
        status = "Importing...";
      });

      try {
        await importCsvFile(file, progressCallback: (current, total) {
          setState(() => status = "Importing $current / $total rows...");
        });
        setState(() => status = "CSV Imported Successfully!");
      } catch (e) {
        setState(() => status = "Error: $e");
      } finally {
        setState(() => isImporting = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV'), centerTitle: true),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(200.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file, size: 70, color: Colors.blue,),
                  label: const Text('Select CSV File', style: TextStyle(color: Colors.blueAccent),),
                  onPressed: isImporting ? null : pickFile,
                ),
                const SizedBox(height: 24),
                if (isImporting)
                  const LinearProgressIndicator(minHeight: 8),
                const SizedBox(height: 12),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
