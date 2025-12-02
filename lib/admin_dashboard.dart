import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Search bar
            TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white), // White text
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.2), // Slightly transparent white box

                labelText: 'Search Registrant by Name or Phone',
                labelStyle: const TextStyle(color: Colors.white), // White label

                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white), // White icon
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchQuery = '');
                  },
                ),

                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Registrants table with scroll
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendees')
                    .orderBy('fullName')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No registrants found.'));
                  }

                  // Filter results by searchQuery
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final name = doc['fullName']?.toString().toLowerCase() ?? '';
                    final phone = doc['phoneNumber']?.toString().toLowerCase() ?? '';
                    return name.contains(searchQuery) || phone.contains(searchQuery);
                  }).toList();

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 24,
                              headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),
                              columns: const [
                                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Country', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Age Group', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Attending As', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Church or Ministry', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DataRow(cells: [
                                  DataCell(Text(data['fullName'] ?? '')),
                                  DataCell(Text(data['phoneNumber'] ?? '')),
                                  DataCell(Text(data['email'] ?? '')),
                                  DataCell(Text(data['residence'] ?? '')),
                                  DataCell(Text(data['ageGroup'] ?? '')),
                                  DataCell(Text(data['attendance.attendingAs'] ?? '')),
                                  DataCell(Text(data['church_or_ministry'] ?? '')),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
