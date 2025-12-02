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
                fillColor: Colors.white.withValues(alpha: 0.2),

                labelText: 'Search Registrant by Name or Phone number',
                labelStyle: const TextStyle(color: Colors.white),

                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
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

              // 🔥 ADD THIS BACK
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
            ),


            const SizedBox(height: 16),

            // 🔹 Registrants table with scroll
            Expanded(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),

                  // 🔹 StreamBuilder INSIDE the static card
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
                        return const Center(
                          child: Text(
                            'No registrants found.',
                            style: TextStyle(color: Colors.black54, fontSize: 18),
                          ),
                        );
                      }

                      // 🔹 Apply search filter
                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final name = doc['fullName']?.toString().toLowerCase() ?? '';
                        final phone = doc['phoneNumber']?.toString().toLowerCase() ?? '';
                        return name.contains(searchQuery) || phone.contains(searchQuery);
                      }).toList();

                      // 🔹 When search returns 0 results
                      if (filteredDocs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No records match your search.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      // 🔹 Show data table
                      return Scrollbar(
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
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
