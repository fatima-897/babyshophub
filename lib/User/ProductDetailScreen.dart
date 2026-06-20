import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isFavorite = false; // 👈 Wishlist state track karne ke liye variable

  @override
  void initState() {
    super.initState();
    checkIfFavorite(); // 👈 Page load hote hi check karega ke item pehle se wishlist me hai ya nahi
  }

  // CHECK IF ITEM IS ALREADY IN WISHLIST
  void checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await firestore
          .collection("wishlist")
          .doc(user.uid)
          .collection("items")
          .doc(widget.productId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          isFavorite = true;
        });
      }
    }
  }

  // WISHLIST ME DATA SAVE / REMOVE KARNE KA FUNCTION
  void toggleWishlist(
    String name,
    String price,
    String image,
    String description,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first to use wishlist")),
      );
      return;
    }

    final docRef = firestore
        .collection("wishlist")
        .doc(user.uid)
        .collection("items")
        .doc(widget.productId);

    try {
      if (isFavorite) {
        // Agar pehle se favorite hai toh remove kardo
        await docRef.delete();
        setState(() => isFavorite = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name removed from wishlist 💔")),
        );
      } else {
        // Agar favorite nahi hai toh add kardo
        await docRef.set({
          'productId': widget.productId,
          'name': name,
          'price': double.tryParse(price) ?? 0.0,
          'image': image,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() => isFavorite = true);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$name added to wishlist! ❤️")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating wishlist: $e")));
    }
  }

  // FIRESTORE ME DATA SAVE / UPDATE KARNE KA FUNCTION
  void addToCart(
    String name,
    String price,
    String image,
    String description,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first to add items")),
      );
      return;
    }

    try {
      final docRef = firestore
          .collection("cart")
          .doc(user.uid)
          .collection("items")
          .doc(widget.productId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        int existingQuantity = docSnapshot.data()?['quantity'] ?? 0;
        await docRef.update({
          'quantity': existingQuantity + quantity,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'productId': widget.productId,
          'name': name,
          'price': double.tryParse(price) ?? 0.0,
          'image': image,
          'description': description,
          'quantity': quantity,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE91E63),
          behavior: SnackBarBehavior.floating,
          content: Text("$quantity x $name added to cart successfully! ✨"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding to cart: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.productData["name"] ?? 'Baby Product';
    final String price = widget.productData["price"]?.toString() ?? '0.0';
    final String image = widget.productData["image"] ?? '';
    final String description =
        widget.productData["detail"] ?? 'No description available.';

    final bool isAvailable = widget.productData["stock"] == "In stock";

    const Color primaryColor = Color(0xFF3B2A1A);
    const Color darkTextColor = Color(0xFF2C2C2C);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: darkTextColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: Icon(
                  // 👈 Change icon dynamically based on status
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : primaryColor,
                ),
                onPressed: () {
                  // 👈 Wishlist function called here
                  toggleWishlist(name, price, image, description);
                },
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: image.isNotEmpty
                    ? Image.network(image, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Rs. $price",
                        style: const TextStyle(
                          fontSize: 22,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        "Quantity:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: isAvailable
                                  ? () {
                                      if (quantity > 1) {
                                        setState(() => quantity--);
                                      }
                                    }
                                  : null,
                            ),
                            Text(
                              "$quantity",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? Colors.black : Colors.grey,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: isAvailable
                                  ? () => setState(() => quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 40,
                    thickness: 1,
                    color: Color(0xFFECE6DD),
                  ),
                  const Text(
                    "Product Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black.withOpacity(0.6),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isAvailable
                ? () => addToCart(name, price, image, description)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? primaryColor : Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAvailable
                      ? Icons.shopping_bag_outlined
                      : Icons.gpp_bad_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  isAvailable ? "Add to Cart" : "Out of Stock",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
