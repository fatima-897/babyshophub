import 'package:babyshophub/User/ProductDetailScreen.dart';
import 'package:babyshophub/User/TrackOrder.dart';
import 'package:babyshophub/User/homescreen.dart';
import 'package:babyshophub/user/user_cart.dart';
import 'package:babyshophub/user/user_drawer.dart';
import 'package:babyshophub/user/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductCatalog extends StatefulWidget {
  const ProductCatalog({super.key});

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final int _currentIndex = 1;
  final searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory = "All";

  final List<Map<String, dynamic>> categories = [
    {"name": "All", "icon": Icons.grid_view_rounded},
    {"name": "Apparel (Clothes)", "icon": Icons.checkroom_rounded},
    {"name": "Diapers & Wipes", "icon": Icons.clean_hands_rounded},
    {"name": "Feeding & Nursing", "icon": Icons.child_care_rounded},
    {"name": "Toys & Learning", "icon": Icons.toys_rounded},
    {"name": "Bath & Skin Care", "icon": Icons.bathtub_rounded},
    {"name": "Nursery & Bedding", "icon": Icons.bed_rounded},
    {"name": "Health & Safety", "icon": Icons.health_and_safety_rounded},
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // WISHLIST TOGGLE FUNCTION
  void toggleWishlist(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first to use Wishlist")),
      );
      return;
    }

    final wishDocRef = firestore
        .collection("wishlist")
        .doc(user.uid)
        .collection("items")
        .doc(productId);

    try {
      final docSnapshot = await wishDocRef.get();

      if (docSnapshot.exists) {
        await wishDocRef.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed from Wishlist ❤️")),
        );
      } else {
        await wishDocRef.set({
          'productId': productId,
          'name': productData["name"] ?? 'Unknown Item',
          'price': productData["price"] ?? 0.0,
          'image': productData["image"] ?? '',
          'detail': productData["detail"] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Added to Wishlist! ❤️")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Wishlist error: $e")));
    }
  }

  // 👈 FIXED: Pehle isme productId nahi aa rahi thi, ab parameter me add kar di ha
  void addToCart(String productId, Map<String, dynamic> productData) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    try {
      await firestore.collection("cart").doc(user.uid).collection("items").add({
        'productId':
            productId, // 👈 FIXED: Yeh line cart screen par synchronization ke liye zaroori ha
        'name': productData["name"] ?? 'Unknown Item',
        'price': productData["price"] ?? 0.0,
        'image': productData["image"] ?? '',
        'description': productData["detail"] ?? 'No description available',
        'quantity': 1,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Added to cart! ✨")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding to cart: $e")));
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2EDE6),
      drawer: const UserAppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EDE6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF3B2A1A)),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: const Text(
          "BabyShopHub",
          style: TextStyle(
            color: Color(0xFF3B2A1A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF3B2A1A),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search for tiny essentials...",
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6E5442),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B2A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => selectedCategory = "All");
                  },
                  child: const Text(
                    "See All",
                    style: TextStyle(
                      color: Color(0xFF6E5442),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Categories Horizontal Scroll
          SizedBox(
            height: 95,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat["name"];

                String displayName = cat["name"];
                if (displayName.contains("(")) {
                  displayName = displayName.split(" ")[0];
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat["name"];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B2A1A)
                                : const Color(0xFFE8E0D0),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3B2A1A,
                                      ).withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            cat["icon"],
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6E5442),
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF3B2A1A)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              "New Arrivals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B2A1A),
              ),
            ),
          ),

          // Products Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection("products").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B2A1A)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                final products = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) return false;

                  final name = (data["name"] ?? "").toString().toLowerCase();
                  final cat = data["category"] ?? "General";

                  final matchSearch =
                      searchQuery.isEmpty || name.contains(searchQuery);
                  final matchCategory =
                      selectedCategory == "All" || cat == selectedCategory;

                  return matchSearch && matchCategory;
                }).toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      "No products available in this category",
                      style: TextStyle(color: Colors.black45),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final productData = doc.data() as Map<String, dynamic>;
                    final productId = doc.id;

                    final String name = productData["name"] ?? 'Baby Product';
                    final String price =
                        productData["price"]?.toString() ?? '0.0';
                    final String? image = productData["image"];
                    final String description =
                        productData["detail"] ?? 'No description available';
                    final bool inStock = productData["stock"] == "In stock";
                    final String rating =
                        productData["rating"]?.toString() ?? "4.5";

                    final user = _auth.currentUser;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              productId: productId,
                              productData: productData,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                  ),
                                  child: image != null && image.isNotEmpty
                                      ? Image.network(
                                          image,
                                          height: 125,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                height: 125,
                                                color: const Color(0xFFE8E0D0),
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          height: 125,
                                          color: const Color(0xFFE8E0D0),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                ),
                                // Wishlist Button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: user == null
                                      ? GestureDetector(
                                          onTap: () => toggleWishlist(
                                            productId,
                                            productData,
                                          ),
                                          child: _buildWishlistIcon(false),
                                        )
                                      : StreamBuilder<DocumentSnapshot>(
                                          stream: firestore
                                              .collection("wishlist")
                                              .doc(user.uid)
                                              .collection("items")
                                              .doc(productId)
                                              .snapshots(),
                                          builder: (context, wishSnapshot) {
                                            final bool isFavorite =
                                                wishSnapshot.hasData &&
                                                wishSnapshot.data!.exists;
                                            return GestureDetector(
                                              onTap: () => toggleWishlist(
                                                productId,
                                                productData,
                                              ),
                                              child: _buildWishlistIcon(
                                                isFavorite,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Rating
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Product Name
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3B2A1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // Description
                                  Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Price & Stock status
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Rs. $price",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF3B2A1A),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: inStock
                                              ? Colors.green[50]
                                              : Colors.red[50],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          inStock ? "In stock" : "Out of stock",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: inStock
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Add to Cart Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: ElevatedButton(
                                      key: const ValueKey(
                                        "add_to_cart_btn_text",
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: inStock
                                            ? const Color(0xFF3B2A1A)
                                            : Colors.grey[400],
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      // 👈 FIXED: Ab yahan productId aur productData dono pass ho rahy hain
                                      onPressed: inStock
                                          ? () => addToCart(
                                              productId,
                                              productData,
                                            )
                                          : null,
                                      child: const Text(
                                        "Add to Cart",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B2A1A),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const homescreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserCart()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TrackOrderScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserProfileScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Categories",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pin_drop_rounded),
            label: "Track",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistIcon(bool isFavorite) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 16,
        color: isFavorite ? Colors.red : const Color(0xFF6E5442),
      ),
    );
  }
}
