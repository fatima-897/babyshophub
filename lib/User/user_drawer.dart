import 'package:babyshophub/User/TrackOrder.dart';
import 'package:babyshophub/User/chat_page.dart';
import 'package:babyshophub/User/login_screen.dart';
import 'package:babyshophub/User/product_catalog.dart';
import 'package:babyshophub/User/user_wishlist.dart';
import 'package:babyshophub/user/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_cart.dart';
import 'user_orders.dart';
import 'homescreen.dart';

class UserAppDrawer extends StatelessWidget {
  const UserAppDrawer({super.key});

  static const primary = Color(0xFF6E5442);
  static const bg = Color(0xFFFAF8F5);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: bg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER (Real-time Auth and Firestore tracker)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                final user = authSnapshot.data;

                // Agar user login nahi hai (Guest hai)
                if (user == null) {
                  return const Text(
                    "Welcome Guest",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                // Agar user login hai, to Firestore se snapshots dynamic listen karo
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(
                        "users",
                      ) // ⚠️ Check karein aapke DB mein 'users' small letters mein hi hai na?
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, firestoreSnapshot) {
                    if (firestoreSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    // Firestore data parsing
                    final data =
                        firestoreSnapshot.data?.data() as Map<String, dynamic>?;

                    // 🌟 FIX: Agar database mein 'username' nahi mila, to 'name' check karega, agar woh bhi nahi mila to Auth profile ka name uthayega
                    String name = '';
                    if (data != null) {
                      name =
                          (data['username'] ??
                                  data['name'] ??
                                  data['fullName'] ??
                                  '')
                              .toString()
                              .trim();
                    }

                    // Fallback to Firebase Auth Display Name if Firestore fields are completely empty
                    if (name.isEmpty) {
                      name = user.displayName ?? 'User';
                    }

                    final email = (data?['email'] ?? user.email ?? '')
                        .toString();
                    final initial = name.isNotEmpty ? name[0] : "U";

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            initial.toUpperCase(),
                            style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          _sectionTitle("MAIN"),
          _menuCard(
            icon: Icons.home_outlined,
            title: "Home",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const homescreen()),
              );
            },
          ),

          _menuCard(
            icon: Icons.storefront_outlined,
            title: "Shop",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductCatalog()),
              );
            },
          ),

          const SizedBox(height: 10),

          _sectionTitle("ACCOUNT"),

          _menuCard(
            icon: Icons.person_outline,
            title: "My Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),

          _menuCard(
            icon: Icons.shopping_cart_outlined,
            title: "My Cart",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserCart()),
              );
            },
          ),

          _menuCard(
            icon: Icons.heart_broken_outlined,
            title: "My WishList",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserWishlist()),
              );
            },
          ),

          _menuCard(
            icon: Icons.pin_drop_rounded,
            title: "Track Order",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackOrderScreen()),
              );
            },
          ),

          _menuCard(
            icon: Icons.receipt_long,
            title: "My Orders",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserOrders()),
              );
            },
          ),

          _menuCard(
            icon: Icons.support_agent,
            title: "Customer Support",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
            },
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E5442),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                "Logout",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECTION TITLE ----------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ---------------- MENU CARD ----------------
  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
