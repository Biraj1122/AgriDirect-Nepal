import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../farm_osm_screen.dart';
import '../user_data.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _addNewAddress() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const FarmOsmScreen()),
    );

    if (result == null || result['address'] == null || user == null) return;

    final String address = result['address'].toString();
    final double? lat = (result['lat'] as num?)?.toDouble();
    final double? lng = (result['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) return;

    // Show dialog to pick label
    String selectedLabel = 'Home';
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Address Label"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _labelOption(context, 'Home', Icons.home, (val) => Navigator.pop(context, val)),
            _labelOption(context, 'Work', Icons.work, (val) => Navigator.pop(context, val)),
            _labelOption(context, 'Other', Icons.location_on, (val) => Navigator.pop(context, val)),
          ],
        ),
      ),
    );

    if (label != null) {
      selectedLabel = label;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('addresses')
          .add({
        'label': selectedLabel,
        'address': address,
        'lat': lat,
        'lng': lng,
        'isDefault': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _labelOption(BuildContext context, String label, IconData icon, Function(String) onSelect) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(label),
      onTap: () => onSelect(label),
    );
  }

  Future<void> _setDefault(String docId, String address, double lat, double lng) async {
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    
    // Unset current default
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();
    
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    // Set new default
    batch.update(
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('addresses')
          .doc(docId),
      {'isDefault': true},
    );

    // Update main user doc for legacy compatibility
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(user!.uid),
      {'address': address, 'lat': lat, 'lng': lng},
    );

    await batch.commit();
    
    // Sync local
    UserData.setAddress(address: address, latitude: lat, longitude: lng);
  }

  Future<void> _deleteAddress(String docId) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('addresses')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("My Addresses", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 15),
                  const Text("No addresses saved", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _addNewAddress,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Add New Address", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bool isDefault = data['isDefault'] ?? false;
              final String label = data['label'] ?? 'Home';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            label == 'Home' ? Icons.home : (label == 'Work' ? Icons.work : Icons.location_on),
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                              child: const Text("DEFAULT", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteAddress(docs[index].id),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(data['address'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 15),
                      if (!isDefault)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _setDefault(docs[index].id, data['address'], data['lat'], data['lng']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Set as Default"),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAddress,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}