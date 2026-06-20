import 'dart:async';
import 'package:babyshophub/User/TrackOrder.dart';
import 'package:babyshophub/User/chat_page.dart';
import 'package:babyshophub/User/product_catalog.dart';
import 'package:babyshophub/user/user_cart.dart';
import 'package:babyshophub/user/user_drawer.dart';
import 'package:babyshophub/user/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class homescreen extends StatefulWidget {
  const homescreen({super.key});

  @override
  State<homescreen> createState() => _homescreenState();
}

class _homescreenState extends State<homescreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;

  final PageController _pageController = PageController(initialPage: 0);
  int _activeSliderIndex = 0;
  Timer? _sliderTimer;

  final List<Map<String, dynamic>> promoBanners = [
    {
      "title": "Welcome Pack 🎉",
      "subtitle": "Get Flat 20% Off on your first order",
      "color": const Color(0xFFFF6584),
      "buttonText": "Claim Voucher",
    },
    {
      "title": "Premium Wooden Toys",
      "subtitle": "Non-toxic organic items safe for babies",
      "color": const Color(0xFF6E5442),
      "buttonText": "Explore Collection",
    },
  ];

  final List<Map<String, String>> ageGroups = [
    {"title": "Newborn", "subtitle": "0-6 Mos", "emoji": "👶"},
    {"title": "Infant", "subtitle": "6-12 Mos", "emoji": "🍼"},
    {"title": "Toddler", "subtitle": "1-2 Yrs", "emoji": "🧸"},
    {"title": "Preschool", "subtitle": "3+ Yrs", "emoji": "🎨"},
    {"title": "Feeding", "subtitle": "Essentials", "emoji": "🥣"},
    {"title": "Bath Care", "subtitle": "Baby Care", "emoji": "🛁"},
    {"title": "Safety", "subtitle": "Protection", "emoji": "🛡️"},
  ];

  final List<Map<String, dynamic>> premiumReviews = [
    {
      "name": "Sana Fatima",
      "location": "Karachi",
      "comment":
          "The organic cotton rompers are incredibly soft. Highly recommended! ✨",
      "rating": 5,
      "date": "2d ago",
    },
    {
      "name": "Zainab Ahmed",
      "location": "Lahore",
      "comment":
          "Super fast delivery and premium gift box packing. Highly satisfied.",
      "rating": 5,
      "date": "1w ago",
    },
    {
      "name": "Ayesha Khan",
      "location": "Karachi",
      "comment": "Best quality material. Best place to buy essentials.",
      "rating": 5,
      "date": "3d ago",
    },
  ];

  void toggleWishlist(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final wishDocRef = firestore
        .collection("wishlist")
        .doc(user.uid)
        .collection("items")
        .doc(productId);

    final docSnapshot = await wishDocRef.get();

    if (docSnapshot.exists) {
      await wishDocRef.delete();
    } else {
      await wishDocRef.set({
        'productId': productId,
        'name': productData["name"],
        'price': productData["price"],
        'image': productData["image"],
        'detail': productData["detail"],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void addToCart(String productId, Map<String, dynamic> productData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await firestore.collection("cart").doc(user.uid).collection("items").add({
      'productId': productId,
      'name': productData["name"],
      'price': productData["price"],
      'image': productData["image"],
      'description': productData["detail"],
      'quantity': 1,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Added to Cart 🛒")));
  }

  // // WhatsApp Chat open karne ka function
  // Future<void> openAdminWhatsAppChat() async {
  //   // 📝 Apna admin/business WhatsApp number yahan likhein (shuru me 92 ke sath, bina + ya 0 ke)
  //   String adminNumber = "923102600950";

  //   // Jo message aap chahti hain ke customer ke chatbox me pehle se likha hua aaye
  //   String customMessage =
  //       "Hello BabyShopHub! Mujhe ek product ke baare mein maloomat chahiye.";

  //   String url =
  //       "https://wa.me/$adminNumber?text=${Uri.encodeComponent(customMessage)}";
  //   final Uri whatsappUri = Uri.parse(url);

  //   try {
  //     if (await canLaunchUrl(whatsappUri)) {
  //       await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  //     } else {
  //       // Android 11+ ke liye fallback mechanism
  //       await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  //     }
  //   } catch (e) {
  //     debugPrint("Chatbox error: $e");
  //   }
  // }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_activeSliderIndex < promoBanners.length - 1) {
        _activeSliderIndex++;
      } else {
        _activeSliderIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _activeSliderIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToAllProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductCatalog()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userName = _auth.currentUser?.displayName ?? "Mamma";

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
            fontSize: 20,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back, $userName! ✨",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B2A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Discover the finest essentials for your bundle of joy.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // 2. Premium Promotional Slider Banner
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _pageController,
                itemCount: promoBanners.length,
                onPageChanged: (index) =>
                    setState(() => _activeSliderIndex = index),
                itemBuilder: (context, index) {
                  final banner = promoBanners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: banner["color"],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                banner["title"],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner["subtitle"],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF3B2A1A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  onPressed: _navigateToAllProducts,
                                  child: Text(
                                    banner["buttonText"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white24,
                          size: 45,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Slider Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                promoBanners.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 8,
                  ),
                  width: _activeSliderIndex == index ? 14 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _activeSliderIndex == index
                        ? const Color(0xFF3B2A1A)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // 3. Shop by Age Group
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Text(
                "Shop Collections by Age",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B2A1A),
                ),
              ),
            ),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ageGroups.length,
                itemBuilder: (context, index) {
                  final age = ageGroups[index];
                  return GestureDetector(
                    onTap: _navigateToAllProducts,
                    child: Container(
                      width: 95,
                      margin: const EdgeInsets.only(right: 10, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            age["emoji"]!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            age["title"]!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B2A1A),
                            ),
                          ),
                          Text(
                            age["subtitle"]!,
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. LIVE NEW ARRIVALS SECTION (Updated & Refined)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Trending Arrivals",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B2A1A),
                    ),
                  ),
                  GestureDetector(
                    onTap: _navigateToAllProducts,
                    child: const Text(
                      "See All →",
                      style: TextStyle(
                        color: Color.fromARGB(255, 58, 46, 23),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection("products").limit(4).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B2A1A),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }

                final products = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio:
                        0.60, // Isko optimize kiya taake details fit ho sakein
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final productId = product.id;
                    final productData = product.data() as Map<String, dynamic>;
                    final user = _auth.currentUser;
                    final String imageUrl = product['image'] ?? "";
                    final String productName =
                        product['name'] ?? "Baby Essential";
                    final dynamic productPrice = product['price'] ?? "0";
                    final String description = product['detail'] ?? "";

                    return GestureDetector(
                      onTap: _navigateToAllProducts,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B2A1A).withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image + Floating Wishlist Button
                            Expanded(
                              flex: 11,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: const Color(0xFFE8E0D0),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Wishlist (Heart) Badge
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      height: 28,
                                      width: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: user == null
                                          ? GestureDetector(
                                              onTap: () => toggleWishlist(
                                                productId,
                                                productData,
                                              ),
                                              child: Icon(
                                                Icons.favorite_border_rounded,
                                                size: 16,
                                                color: const Color(0xFFFF6584),
                                              ),
                                            )
                                          : StreamBuilder<DocumentSnapshot>(
                                              stream: firestore
                                                  .collection("wishlist")
                                                  .doc(user.uid)
                                                  .collection("items")
                                                  .doc(productId)
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                final bool isFavorite =
                                                    snapshot.hasData &&
                                                    snapshot.data!.exists;

                                                return GestureDetector(
                                                  onTap: () => toggleWishlist(
                                                    productId,
                                                    productData,
                                                  ),
                                                  child: Icon(
                                                    isFavorite
                                                        ? Icons.favorite_rounded
                                                        : Icons
                                                              .favorite_border_rounded,
                                                    size: 16,
                                                    color: isFavorite
                                                        ? Colors.red
                                                        : const Color(
                                                            0xFFFF6584,
                                                          ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Product Details (Title, Rating, Price, Quick Add)
                            Expanded(
                              flex: 8,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              "4.8",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3B2A1A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 2),

                                        Text(
                                          description,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "PKR $productPrice",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFF6584),
                                          ),
                                        ),
                                        // Quick Add Button
                                        Container(
                                          height: 26,
                                          width: 26,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B2A1A),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              addToCart(productId, productData);
                                            },
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

            // 5. Gift Pack Feature Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6DCD0), Color(0xFFDCD0C0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Send Premium Gift Boxes 🎁",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B2A1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Customize your custom baby gift pack with velvet soft boxes.",
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 36,
                    color: Color(0xFF6E5442),
                  ),
                ],
              ),
            ),

            // 6. Professional Wall of Reviews
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                "Words From Loving Parents ❤️",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B2A1A),
                ),
              ),
            ),

            SizedBox(
              height: 105,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: premiumReviews.length,
                itemBuilder: (context, index) {
                  final review = premiumReviews[index];
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review["name"],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B2A1A),
                              ),
                            ),
                            Text(
                              review["date"],
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          review["comment"],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: List.generate(
                            review["rating"],
                            (i) => const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // ✨ YEH UPDATED CHATBOX WIDGET HAI ✨
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // WhatsApp hata kar naye Firebase ChatPage par navigate karein
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        },
        // BabyShopHub ki theme ke mutabiq color
        backgroundColor: const Color.fromARGB(255, 77, 66, 30),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
        label: const Text(
          "Chat with Us",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // Bottom Nav Bar Controls
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B2A1A),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            _navigateToAllProducts();
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
}
