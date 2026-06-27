import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _currentIndex = 0;

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text("Delivery Partner", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout),
        ],
      ),
      body: _currentIndex == 0 ? _AvailableOrders(uid: uid) : _MyDeliveries(uid: uid),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Available"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "My Tasks"),
        ],
      ),
    );
  }
}

class _AvailableOrders extends StatelessWidget {
  final String uid;
  const _AvailableOrders({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Awaiting Pickup')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No orders waiting for pickup nearby."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                title: Text("Order from ${data['farmName'] ?? 'Farm'}"),
                subtitle: Text("Deliver to: ${data['userName']}"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => _acceptOrder(docs[i].reference, uid, data),
                  child: const Text("Accept", style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptOrder(DocumentReference docRef, String uid, Map<String, dynamic> data) async {
    await docRef.update({
      'status': 'Picked Up',
      'deliveryPersonId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final userId = data['userId'];
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
        'title': 'Order Picked Up',
        'body': 'A delivery partner has picked up your order and is on the way.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }
}

class _MyDeliveries extends StatelessWidget {
  final String uid;
  const _MyDeliveries({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: uid)
          .where('status', isEqualTo: 'Picked Up')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No active deliveries."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                title: Text("Deliver to ${data['userName']}"),
                subtitle: Text("Location: ${data['address'] ?? 'N/A'}"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => _completeDelivery(docs[i].reference, data),
                  child: const Text("Complete", style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeDelivery(DocumentReference docRef, Map<String, dynamic> data) async {
    await docRef.update({
      'status': 'Delivered',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final userId = data['userId'];
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').add({
        'title': 'Order Delivered',
        'body': 'Your order has been delivered successfully. Enjoy!',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }
}
