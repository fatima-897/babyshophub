import 'package:babyshophub/User/TrackOrder.dart';
import 'package:babyshophub/User/homescreen.dart';
import 'package:babyshophub/user/product_catalog.dart';
import 'package:babyshophub/user/user_cart.dart';
import 'package:babyshophub/user/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _currentIndex = 4;

  // --- PREMIUM BROWN & BEIGE THEME PALETTE ---
  static const Color colorPrimaryDark = Color(0xFF3B2A1A); // Deep Dark Brown
  static const Color colorBrownMedium = Color(0xFF7A5C43); // Rich Medium Brown
  static const Color colorBeigeAccent = Color(0xFF9E826C); // Soft Warm Beige
  static const Color colorBeigeBackground = Color(
    0xFFF5EFE9,
  ); // Creamy Beige Background
  static const Color colorBeigeSurface = Color(
    0xFFEFE6DC,
  ); // Light Warm Beige Surface
  static const Color colorHintText = Color(0xFFC4B2A1); // Muted Clay Hint

  // Form Field State Trackers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();

  // Async process lifecycle monitors
  bool _isSavingProfile = false;
  bool _isSavingAddress = false;
  bool _isSavingCard = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.redAccent : colorBrownMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- BUSINESS LOGIC ACTIONS ---

  Future<void> _updatePersonalInfo() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showSnackBar("Please fill in all profile fields.", isError: true);
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      String uid = _auth.currentUser!.uid;
      await _db.collection("users").doc(uid).update({
        'username': name,
        'phone': phone,
      });
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Personal profile updated successfully!");
    } catch (e) {
      _showSnackBar("Failed to update profile: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _addAddress() async {
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final zip = _zipController.text.trim();

    if (street.isEmpty || city.isEmpty || zip.isEmpty) {
      _showSnackBar("All address fields are required.", isError: true);
      return;
    }

    setState(() => _isSavingAddress = true);

    try {
      String uid = _auth.currentUser!.uid;
      await _db.collection("users").doc(uid).collection("addresses").add({
        'street': street,
        'city': city,
        'zip': zip,
        'isDefault': false,
      });
      _streetController.clear();
      _cityController.clear();
      _zipController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Address added successfully!");
    } catch (e) {
      _showSnackBar("Could not save address: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSavingAddress = false);
    }
  }

  Future<void> _addPaymentMethod() async {
    final cardHolder = _cardNameController.text.trim();
    final rawCard = _cardNumberController.text.trim();
    final expiry = _cardExpiryController.text.trim();

    if (cardHolder.isEmpty || rawCard.isEmpty || expiry.isEmpty) {
      _showSnackBar("All card details are required.", isError: true);
      return;
    }

    setState(() => _isSavingCard = true);

    try {
      String uid = _auth.currentUser!.uid;
      String maskedCard = rawCard.length > 4
          ? "**** **** **** ${rawCard.substring(rawCard.length - 4)}"
          : rawCard;

      await _db.collection("users").doc(uid).collection("payments").add({
        'cardHolder': cardHolder,
        'cardNumber': maskedCard,
        'expiry': expiry,
      });
      _cardNameController.clear();
      _cardNumberController.clear();
      _cardExpiryController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Payment method linked successfully!");
    } catch (e) {
      _showSnackBar("Could not link card: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSavingCard = false);
    }
  }

  Future<void> _deleteAddress(String docId) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _db
          .collection("users")
          .doc(uid)
          .collection("addresses")
          .doc(docId)
          .delete();
      _showSnackBar("Address deleted successfully.");
    } catch (e) {
      _showSnackBar("Failed to delete address.", isError: true);
    }
  }

  Future<void> _deletePayment(String docId) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _db
          .collection("users")
          .doc(uid)
          .collection("payments")
          .doc(docId)
          .delete();
      _showSnackBar("Payment method removed.");
    } catch (e) {
      _showSnackBar("Failed to remove card.", isError: true);
    }
  }

  // --- MODAL SHEETS MANAGEMENT ---

  void _showEditProfileDialog(String currentName, String currentPhone) {
    _nameController.text = currentName;
    _phoneController.text = currentPhone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorHintText.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Edit Profile Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorPrimaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  _nameController,
                  "Full Name",
                  Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _phoneController,
                  "Phone Number",
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  "Update Profile",
                  _isSavingProfile
                      ? null
                      : () async {
                          setModalState(() => _isSavingProfile = true);
                          await _updatePersonalInfo();
                          setModalState(() => _isSavingProfile = false);
                        },
                  isLoading: _isSavingProfile,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddAddressDialog() {
    _streetController.clear();
    _cityController.clear();
    _zipController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorHintText.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Add New Address",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorPrimaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  _streetController,
                  "Street Address",
                  Icons.home_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _cityController,
                        "City",
                        Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildTextField(
                        _zipController,
                        "ZIP Code",
                        Icons.markunread_mailbox_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  "Save New Address",
                  _isSavingAddress
                      ? null
                      : () async {
                          setModalState(() => _isSavingAddress = true);
                          await _addAddress();
                          setModalState(() => _isSavingAddress = false);
                        },
                  isLoading: _isSavingAddress,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddPaymentDialog() {
    _cardNameController.clear();
    _cardNumberController.clear();
    _cardExpiryController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorHintText.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Link Payment Card",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorPrimaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  _cardNameController,
                  "Cardholder Name",
                  Icons.account_box_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _cardNumberController,
                  "Card Number",
                  Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _cardExpiryController,
                  "Expiry Date (MM/YY)",
                  Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  "Link Card Securely",
                  _isSavingCard
                      ? null
                      : () async {
                          setModalState(() => _isSavingCard = true);
                          await _addPaymentMethod();
                          setModalState(() => _isSavingCard = false);
                        },
                  isLoading: _isSavingCard,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- CORE VIEW LAYOUT RENDERING ---

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? "";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorBeigeBackground,
      drawer: const UserAppDrawer(),
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: colorBeigeBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: colorPrimaryDark,
            size: 28,
          ),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        // FIXED BUG: Real-time username injected directly into the AppBar Greeting
        title: StreamBuilder<DocumentSnapshot>(
          stream: uid.isNotEmpty
              ? _db.collection("users").doc(uid).snapshots()
              : null,
          builder: (context, snapshot) {
            String displayedName = "User";
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              displayedName = data?['username'] ?? "User";
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "BabyShopHub",
                  style: TextStyle(
                    color: colorPrimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Hello, $displayedName! 👋",
                  style: const TextStyle(
                    color: colorBrownMedium,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: colorBeigeSurface,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: colorPrimaryDark,
                size: 24,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text(
                "Please login to view your profile.",
                style: TextStyle(
                  color: colorPrimaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: _db.collection("users").doc(uid).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return const Center(
                    child: Text("Something went wrong loading data."),
                  );
                }
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: colorBrownMedium),
                  );
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};

                // FIXED BUG: Dynamic User Name assignment from Firestore response instead of fallback
                final name = userData['username'] ?? 'User Name';
                final email = userData['email'] ?? 'No email associated';
                final phone = userData['phone'] ?? 'Add phone number';

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Hero Card - Warm Brown & Beige Styling
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorPrimaryDark.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorBeigeBackground,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: colorBeigeAccent,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name, // Displays logged-in user name dynamically
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: colorPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: colorBrownMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: colorBeigeBackground,
                              borderRadius: BorderRadius.circular(12),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit_note_rounded,
                                  color: colorPrimaryDark,
                                  size: 24,
                                ),
                                onPressed: () => _showEditProfileDialog(
                                  name,
                                  phone == 'Add phone number' ? '' : phone,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Address Section
                      _buildSectionHeader(
                        "Delivery Addresses",
                        _showAddAddressDialog,
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection("users")
                            .doc(uid)
                            .collection("addresses")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyStateMessage(
                              "No saved addresses found. Add one to checkout faster!",
                            );
                          }

                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final addr =
                                  docs[index].data() as Map<String, dynamic>;
                              final docId = docs[index].id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorBeigeSurface,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: colorBeigeSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: colorBrownMedium,
                                      size: 22,
                                    ),
                                  ),
                                  // ---> FIXED LINE IS HERE <---
                                  title: Text(
                                    addr['street'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorPrimaryDark,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${addr['city'] ?? ''}, ${addr['zip'] ?? ''}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () => _deleteAddress(docId),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Payment Card Section
                      _buildSectionHeader(
                        "Payment Methods",
                        _showAddPaymentDialog,
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection("users")
                            .doc(uid)
                            .collection("payments")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyStateMessage(
                              "No digital payment cards linked securely.",
                            );
                          }

                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final card =
                                  docs[index].data() as Map<String, dynamic>;
                              final docId = docs[index].id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorBeigeSurface,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: colorBeigeSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.credit_card_rounded,
                                      color: colorBrownMedium,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    card['cardNumber'] ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      color: colorPrimaryDark,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    (card['cardHolder'] ?? '')
                                        .toString()
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () => _deletePayment(docId),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorPrimaryDark,
          unselectedItemColor: Colors.black38,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const homescreen()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProductCatalog()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserCart()),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrackOrderScreen(),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: "Categories",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart_rounded),
              label: "Cart",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pin_drop_outlined),
              activeIcon: Icon(Icons.pin_drop_rounded),
              label: "Track",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE UI BUILDERS ---

  Widget _buildSectionHeader(String title, VoidCallback onAddPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorPrimaryDark,
          ),
        ),
        TextButton.icon(
          onPressed: onAddPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(
            Icons.add_rounded,
            size: 16,
            color: colorBrownMedium,
          ),
          label: const Text(
            "Add New",
            style: TextStyle(
              color: colorBrownMedium,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: colorPrimaryDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: colorHintText, fontSize: 14),
        prefixIcon: Icon(icon, color: colorBrownMedium, size: 22),
        filled: true,
        fillColor: colorBeigeSurface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: colorBrownMedium, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback? onPressed, {
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimaryDark,
          elevation: 0,
          disabledBackgroundColor: colorPrimaryDark.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyStateMessage(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: colorBrownMedium,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }
}
