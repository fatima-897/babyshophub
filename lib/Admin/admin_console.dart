import 'package:babyshophub/Admin/admin_inventory.dart';
import 'package:babyshophub/Admin/admin_orders.dart';
import 'package:babyshophub/Admin/admin_chat_list_page.dart'; // 💬 Live Chat Page Import Kiya
import 'package:babyshophub/Admin/admin_users.dart';
import 'package:babyshophub/User/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminConsole extends StatefulWidget {
  const AdminConsole({super.key});

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final imageController = TextEditingController();
  final detailController = TextEditingController();

  String stockValue = "In stock";
  String categoryValue = "Apparel (Clothes)"; // Default category value

  //  OPTIMIZED CATEGORIES LIST (Baby Shop Ke Hisab Se) 
  final List<String> categoryOptions = [
    "Apparel (Clothes)",
    "Diapers & Wipes",
    "Feeding & Nursing",
    "Toys & Learning",
    "Bath & Skin Care",
    "Nursery & Bedding",
    "Health & Safety",
  ];

  // ── ADD PRODUCT ──────────────────────────────────────────
  void showAddProductDialog() {
    nameController.clear();
    priceController.clear();
    imageController.clear();
    detailController.clear();

    // BUG FIX: Dialog khulne par default values hamesha fresh reset hongi
    setState(() {
      stockValue = "In stock";
      categoryValue = "Apparel (Clothes)";
    });

    showDialog(
      context: context,
      builder: (_) => _productDialog(
        title: "Add Product",
        onSave: () async {
          if (nameController.text.isEmpty || priceController.text.isEmpty) {
            return;
          }
          await firestore.collection("products").add({
            'name': nameController.text.trim(),
            'price': priceController.text.trim(),
            'image': imageController.text.trim(),
            'detail': detailController.text.trim(),
            'category': categoryValue, // Dropdown se chuni hui value save hogi
            'stock': stockValue,
            'rating': "4.5",
          });
          if (!mounted) return;
          Navigator.pop(context);
          _snack("Product added!");
        },
        btnLabel: "Add",
      ),
    );
  }

  // ── EDIT PRODUCT ─────────────────────────────────────────
  void showEditProductDialog(DocumentSnapshot product) {
    nameController.text = product['name'];
    priceController.text = product['price'].toString();
    imageController.text = product['image'] ?? '';
    detailController.text = product['detail'] ?? '';
    stockValue = product['stock'] ?? 'In stock';

    // Agar database ki purani category list me nahi hai toh default apparel handle karega taake code crash na ho
    String dbCategory = product['category'] ?? 'Apparel (Clothes)';
    if (categoryOptions.contains(dbCategory)) {
      categoryValue = dbCategory;
    } else {
      categoryValue = "Apparel (Clothes)";
    }

    showDialog(
      context: context,
      builder: (_) => _productDialog(
        title: "Edit Product",
        onSave: () async {
          await firestore.collection("products").doc(product.id).update({
            'name': nameController.text.trim(),
            'price': priceController.text.trim(),
            'image': imageController.text.trim(),
            'detail': detailController.text.trim(),
            'category': categoryValue, // Updated Dropdown value
            'stock': stockValue,
          });
          if (!mounted) return;
          Navigator.pop(context);
          _snack("Product updated!");
        },
        btnLabel: "Save",
      ),
    );
  }

  // ── SHARED DIALOG WIDGET ─────────────────────────────────
  Widget _productDialog({
    required String title,
    required VoidCallback onSave,
    required String btnLabel,
  }) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B2A1A),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  nameController,
                  "Product Name",
                  Icons.label_outline,
                ),
                _dialogField(
                  priceController,
                  "Price",
                  Icons.attach_money,
                  number: true,
                ),
                _dialogField(
                  imageController,
                  "Image URL",
                  Icons.image_outlined,
                ),
                _dialogField(
                  detailController,
                  "Short Detail",
                  Icons.notes_outlined,
                ),
                const SizedBox(height: 8),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: categoryValue,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F0E8),
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                      color: Color(0xFF6E5442),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: categoryOptions.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => categoryValue = val!);
                  },
                ),

                const SizedBox(height: 8),

                // Stock Dropdown
                DropdownButtonFormField<String>(
                  initialValue: stockValue,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F0E8),
                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF6E5442),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "In stock",
                      child: Text("In Stock"),
                    ),
                    DropdownMenuItem(
                      value: "Out of stock",
                      child: Text("Out of Stock"),
                    ),
                  ],
                  onChanged: (val) {
                    setDialogState(() => stockValue = val!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B2A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onSave,
              child: Text(
                btnLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // dialog text field helper
  Widget _dialogField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBCC2CD)),
          prefixIcon: Icon(icon, color: const Color(0xFF6E5442)),
          filled: true,
          fillColor: const Color(0xFFF5F0E8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── DELETE ───────────────────────────────────────────────
  void confirmDelete(String productId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Product",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await firestore.collection("products").doc(productId).delete();
              if (!mounted) return;
              Navigator.pop(context);
              _snack("Product deleted!");
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    imageController.dispose();
    detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Admin Console",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),

      // ── TAB VIEWS CONTROLLER ───────────────────────────────
      body: _currentIndex == 0
          ? _buildHomeTab()
          : _currentIndex == 1
          ? const AdminInventory()
          : _currentIndex == 2
          ? const AdminOrders()
          : _currentIndex == 3
          ? const AdminChatListPage() //  AdminTickets Ki Jagah Live Chat List Set Ho Gayi
          : const AdminUsers(),

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF3B2A1A),
              onPressed: showAddProductDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Product",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ── BOTTOM NAVIGATION BAR ───────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B2A1A),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 12,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Console",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: "Inventory",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded), // 👈 Chat Icon Setup
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: "Chats", // 👈 Tickets se badal kar Chats kar diya
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Users",
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome back 👋",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Admin Console",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B2A1A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B2A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: firestore.collection("orders").snapshots(),
                        builder: (context, snapshot) {
                          double total = 0;
                          if (snapshot.hasData) {
                            for (var d in snapshot.data!.docs) {
                              total +=
                                  double.tryParse(d['total'].toString()) ?? 0;
                            }
                          }
                          return _statCard(
                            icon: Icons.account_balance_wallet_outlined,
                            label: "Hub Revenue",
                            value: "PKR ${total.toStringAsFixed(2)}",
                            bg: const Color(0xFF3B2A1A),
                            sub: "Total earnings",
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: firestore.collection("orders").snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData
                              ? snapshot.data!.docs.length
                              : 0;
                          return _statCard(
                            icon: Icons.shopping_bag_outlined,
                            label: "Product Sales",
                            value: "$count",
                            bg: const Color(0xFF6E5442),
                            sub: "Orders placed",
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Active Store Catalog",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B2A1A),
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection("products").snapshots(),
                      builder: (context, snapshot) {
                        int count = snapshot.hasData
                            ? snapshot.data!.docs.length
                            : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B2A1A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$count items",
                            style: const TextStyle(
                              color: Color(0xFF3B2A1A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection("products").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "No products yet\nTap + Add Product to get started",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final products = snapshot.data!.docs;
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  final bool inStock = product['stock'] == "In stock";
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child:
                              product['image'] != null && product['image'] != ""
                              ? Image.network(
                                  product['image'],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 90,
                                  height: 90,
                                  color: const Color(0xFFE8E0D0),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF3B2A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: inStock
                                            ? Colors.green[50]
                                            : Colors.red[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        inStock ? "In Stock" : "Out",
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
                                const SizedBox(height: 4),
                                Text(
                                  product['detail'] ?? "No description",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "PKR ${product['price']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF3B2A1A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2EDE6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product['category'] ?? "General",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF6E5442),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF2C5270),
                                  size: 20,
                                ),
                                onPressed: () => showEditProductDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => confirmDelete(product.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: products.length),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color bg,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
