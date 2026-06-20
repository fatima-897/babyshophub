import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  // User ka status toggle (Block/Unblock) karne ka function
  Future<void> _toggleUserStatus(
    BuildContext context,
    String docId,
    bool currentBlockStatus,
    String username,
  ) async {
    try {
      await FirebaseFirestore.instance.collection("users").doc(docId).update({
        'isBlocked': !currentBlockStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentBlockStatus
                ? "$username has been Blocked"
                : "$username is now Active",
          ),
          backgroundColor: const Color(0xFFD81B60),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Status update failed: $e")));
    }
  }

  // User account permanently delete karne ka function
  Future<void> _deleteUser(
    BuildContext context,
    String docId,
    String username,
  ) async {
    // Confirmation Dialog dikhana behtar hota hai taake galti se delete na ho
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Account?"),
            content: Text(
              "Are you sure you want to permanently delete $username's account?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$username removed successfully"),
            backgroundColor: Colors.black87,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Deletion failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD81B60)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No users found",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};

            final username = data['username']?.toString() ?? "No Name";
            final email = data['email']?.toString() ?? "No Email";
            final role = data['role']?.toString() ?? "user";
            final bool isBlocked =
                data['isBlocked'] ?? false; // Firestore status check
            final bool isAdmin = role == "admin";

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isAdmin
                                ? const Color(0xFF2C5270)
                                : const Color(0xFFD81B60),
                            child: Text(
                              email.isNotEmpty ? email[0].toUpperCase() : "U",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? const Color(0xFF2C5270).withOpacity(0.1)
                                      : const Color(
                                          0xFFD81B60,
                                        ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color: isAdmin
                                        ? const Color(0xFF2C5270)
                                        : const Color(0xFFD81B60),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Block Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isBlocked ? "Blocked" : "Active",
                                  style: TextStyle(
                                    color: isBlocked
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Agar khud admin nahi hai to control buttons show honge
                      if (!isAdmin) ...[
                        const Divider(height: 20, color: Colors.black12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Block/Unblock Text Button
                            TextButton.icon(
                              onPressed: () => _toggleUserStatus(
                                context,
                                doc.id,
                                isBlocked,
                                username,
                              ),
                              icon: Icon(
                                isBlocked
                                    ? Icons.lock_open
                                    : Icons.lock_outline,
                                size: 16,
                                color: isBlocked ? Colors.green : Colors.orange,
                              ),
                              label: Text(
                                isBlocked ? "Unblock User" : "Block User",
                                style: TextStyle(
                                  color: isBlocked
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Delete Account Text Button
                            TextButton.icon(
                              onPressed: () =>
                                  _deleteUser(context, doc.id, username),
                              icon: const Icon(
                                Icons.delete_forever,
                                size: 16,
                                color: Colors.red,
                              ),
                              label: const Text(
                                "Remove",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
