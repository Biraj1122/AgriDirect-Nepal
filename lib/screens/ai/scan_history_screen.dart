import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/translations.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text("Please login to see your history"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('research_submissions')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("No scans found yet.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Sort manually in memory to avoid needing a Firestore index right now
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                    final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final diagnosis = data['diagnosis'] ?? "Unknown";
                    final isNepali = data['isNepali'] ?? false;
                    final imageUrl = data['imageUrl'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                                  ),
                                )
                              : const Icon(Icons.medication, color: Colors.green),
                        ),
                        title: Text(
                          AppTranslations.translate(diagnosis, 'name_ne', isNepali: isNepali),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm').format(date)),
                        trailing: Text(
                          "${((data['confidence'] ?? 0) * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
