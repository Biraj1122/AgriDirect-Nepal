import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final unreadNotifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadNotifications.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in unreadNotifications.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please login to see notifications"))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Unable to load notifications",
                      style: TextStyle(color: Colors.red[700], fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please try again later",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final notifications = snapshot.data?.docs ?? [];

          // Sort by createdAt in descending order
          notifications.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final item = doc.data() as Map<String, dynamic>;

              IconData icon;
              Color color;

              String type = item['type']?.toString().toLowerCase() ?? 'default';
              String title = item['title']?.toString().toLowerCase() ?? '';
              String body = item['body']?.toString().toLowerCase() ?? '';

              if (type.contains('delivery') || type.contains('delivered') || type.contains('way') ||
                  title.contains('order') || body.contains('order')) {
                icon = Icons.local_shipping_outlined;
                color = Colors.green;
              } else if (type.contains('stock')) {
                icon = Icons.eco_outlined;
                color = Colors.amber;
              } else if (type.contains('promo') || type.contains('banner')) {
                icon = Icons.campaign_outlined;
                color = Colors.orange;
              } else {
                icon = Icons.notifications_active_outlined;
                color = Colors.blue;
              }

              String timeStr = "Just now";
              if (item['createdAt'] != null) {
                final timestamp = item['createdAt'] as Timestamp;
                final date = timestamp.toDate();
                timeStr = DateFormat('jm').format(date); // e.g. 5:30 PM
                if (DateTime.now().difference(date).inDays > 0) {
                  timeStr = DateFormat('MMM d, jm').format(date);
                }
              } else if (item['time'] != null) {
                timeStr = item['time'].toString();
              }

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  try {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('notifications')
                        .doc(doc.id)
                        .delete();
                  } catch (e) {
                    debugPrint("Error deleting notification: $e");
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] ?? 'Notification',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['body'] ?? '',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
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
    );
  }
}