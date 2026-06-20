import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F5F0,
      ), // Matching background from image
      appBar: AppBar(
        title: const Text(
          "My Wishlist ❤️",
          style: TextStyle(
            color: Color(0xFF3B2A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Color(0xFF3B2A1A)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: user == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('wishlist')
                  .doc(user.uid)
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Wishlist is empty 💔"));
                }

                final items = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final data = items[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // Allows dynamic card height
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. PRODUCT IMAGE
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              data['image'],
                              height:
                                  180, // Giving the image slightly more prominence
                              fit: BoxFit.cover,
                            ),
                          ),

                          // 2. DETAILS & ADD TO CART (Combined in a nested column)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF3B2A1A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Rs. ${data['price']}",
                                            style: const TextStyle(
                                              color: Color(0xFF8A6E53),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // DELETE BUTTON in the same row as name/price
                                    IconButton(
                                      onPressed: () {
                                        data.reference.delete();
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ), // Spacing before the button
                                // ADD TO CART BUTTON (Nested below details)
                                SizedBox(
                                  height: 36, // Smaller, more compact height
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF3B2A1A,
                                      ), // Matching color from image
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      elevation: 1,
                                    ),
                                    onPressed: () async {
                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user == null) return;

                                      await FirebaseFirestore.instance
                                          .collection('cart')
                                          .doc(user.uid)
                                          .collection('items')
                                          .add({
                                            'name': data['name'],
                                            'price': data['price'],
                                            'image': data['image'],
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Added to Cart 🛒"),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Add to Cart",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
