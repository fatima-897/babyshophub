import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserWishlist extends StatelessWidget {
  const UserWishlist({super.key});

  Future<void> addToCart(
    BuildContext context,
    String userId,
    String productId,
    Map<String, dynamic> itemData,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final cartDoc = firestore
          .collection("cart")
          .doc(userId)
          .collection("items")
          .doc(productId);

      await cartDoc.set({
        "name": itemData["name"],
        "price": itemData["price"],
        "image": itemData["image"],
        "quantity": 1,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${itemData["name"]} added to cart! 🛒"),
            backgroundColor: const Color(0xFFD81B60), // Theme primary deep pink
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add to cart: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5), // Soft elegant beige background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF5),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Wishlist",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: user == null
          ? const Center(
              child: Text(
                "Please login to see your wishlist",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection("wishlist")
                  .doc(user.uid)
                  .collection("items")
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD81B60),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            size: 70,
                            color: Color(0xFFD81B60),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Your wishlist is empty!",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Explore items and save your favorites here.",
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final wishlistItems = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wishlistItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio:
                        0.62, // Overflow/Renderflex errors se bachane ke liye safe aspect ratio
                  ),
                  itemBuilder: (context, index) {
                    final doc = wishlistItems[index];
                    final itemData = doc.data() as Map<String, dynamic>;
                    final String productId = doc.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Stack Section
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    child:
                                        itemData["image"] != null &&
                                            itemData["image"]
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                            itemData["image"],
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: const Color(0xFFF3E5D0),
                                            child: const Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                ),
                                // Premium Frosted Glass Delete Button
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5,
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await firestore
                                              .collection("wishlist")
                                              .doc(user.uid)
                                              .collection("items")
                                              .doc(productId)
                                              .delete();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Text Info Details
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemData["name"] ?? 'Product Name',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Rs. ${itemData["price"]}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(
                                      0xFFD81B60,
                                    ), // Highlighted deep pink price
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Modern Add To Cart Button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: ElevatedButton(
                              onPressed: () => addToCart(
                                context,
                                user.uid,
                                productId,
                                itemData,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFD81B60,
                                ), // Deep Pink theme tone
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 38),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 15),
                                  SizedBox(width: 6),
                                  Text(
                                    "Add to Cart",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
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
