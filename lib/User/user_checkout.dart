import 'package:babyshophub/User/homescreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserCheckout extends StatefulWidget {
  final double total;
  final List<QueryDocumentSnapshot> items;

  const UserCheckout({super.key, required this.total, required this.items});

  @override
  State<UserCheckout> createState() => _UserCheckoutState();
}

class _UserCheckoutState extends State<UserCheckout> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // form key
  final _formkey = GlobalKey<FormState>();

  // address controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final zipController = TextEditingController();

  // payment controllers
  final cardNameController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  // selected payment method
  String paymentMethod = "Card";
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    zipController.dispose();
    cardNameController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  // place order
  void placeOrder() async {
    // Form validation check
    if (!_formkey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User is not logged in.")));
        return;
      }

      // 1. Order save karein firestore me
      final orderRef = await firestore.collection("orders").add({
        'userId': user.uid,
        'email': user.email,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'zip': zipController.text.trim(),
        'payment': paymentMethod,
        'total': widget.total,
        'status': "Pending",
        'createdAt': FieldValue.serverTimestamp(),
        'items': widget.items
            .map(
              (item) => {
                'name': item['name'],
                'price': item['price'],
                'quantity': item['quantity'],
                'image': item['image'],
              },
            )
            .toList(),
      });

      // 2. Cart items ko clean karein
      final cartRef = firestore
          .collection("cart")
          .doc(user.uid)
          .collection("items");
      final cartItems = await cartRef.get();

      final batch = firestore.batch();
      for (var doc in cartItems.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      setState(() => isLoading = false);

      // Success screen par le jayein
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OrderSuccessScreen(orderId: orderRef.id, total: widget.total),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${err.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EDE6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3B2A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Color(0xFF3B2A1A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Form(
        key: _formkey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── ORDER SUMMARY ──────────────────────
                  _sectionTitle("Order Summary"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ...widget.items.map((item) {
                          final qty =
                              int.tryParse(item['quantity'].toString()) ?? 1;
                          final price =
                              double.tryParse(item['price'].toString()) ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      item['image'] != null &&
                                          item['image'] != ""
                                      ? Image.network(
                                          item['image'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: const Color(0xFFE8E0D0),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Baby Product',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF3B2A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Qty: $qty",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 👈 CHANGED: Yahan Rs. laga diya hai
                                Text(
                                  "Rs. ${(price * qty).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF3B2A1A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            // 👈 CHANGED: Yahan Rs. laga diya hai
                            Text(
                              "Rs. ${widget.total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF3B2A1A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── DELIVERY ADDRESS ───────────────────
                  _sectionTitle("Delivery Address"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField(
                          controller: nameController,
                          hint: "Full Name",
                          icon: Icons.person_outline,
                          validator: (v) =>
                              v!.trim().isEmpty ? "Name is required" : null,
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: phoneController,
                          hint: "Phone Number",
                          icon: Icons.phone_outlined,
                          number: true,
                          validator: (v) =>
                              v!.trim().isEmpty ? "Phone is required" : null,
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: addressController,
                          hint: "Street Address",
                          icon: Icons.location_on_outlined,
                          validator: (v) =>
                              v!.trim().isEmpty ? "Address is required" : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                controller: cityController,
                                hint: "City",
                                icon: Icons.location_city_outlined,
                                validator: (v) =>
                                    v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _inputField(
                                controller: zipController,
                                hint: "ZIP Code",
                                icon: Icons.pin_outlined,
                                number: true,
                                validator: (v) =>
                                    v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── PAYMENT METHOD ─────────────────────
                  _sectionTitle("Payment Method"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _paymentChip("Card", Icons.credit_card),
                            const SizedBox(width: 10),
                            _paymentChip("Cash", Icons.money),
                            const SizedBox(width: 10),
                            _paymentChip("JazzCash", Icons.phone_android),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (paymentMethod == "Card") ...[
                          _inputField(
                            controller: cardNameController,
                            hint: "Name on Card",
                            icon: Icons.person_outline,
                            validator: (v) =>
                                (paymentMethod == "Card" && v!.trim().isEmpty)
                                ? "Required"
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _inputField(
                            controller: cardNumberController,
                            hint: "Card Number",
                            icon: Icons.credit_card,
                            number: true,
                            validator: (v) {
                              if (paymentMethod != "Card") return null;
                              if (v!.trim().isEmpty) return "Required";
                              if (v.trim().length < 16) {
                                return "Enter valid card number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _inputField(
                                  controller: expiryController,
                                  hint: "MM/YY",
                                  icon: Icons.date_range_outlined,
                                  validator: (v) =>
                                      (paymentMethod == "Card" &&
                                          v!.trim().isEmpty)
                                      ? "Required"
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _inputField(
                                  controller: cvvController,
                                  hint: "CVV",
                                  icon: Icons.lock_outline,
                                  number: true,
                                  validator: (v) {
                                    if (paymentMethod != "Card") return null;
                                    if (v!.trim().isEmpty) return "Required";
                                    if (v.trim().length < 3) {
                                      return "Invalid CVV";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (paymentMethod == "Cash") ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Pay with cash on delivery",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (paymentMethod == "JazzCash") ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.phone_android,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "JazzCash payment on confirmation",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(color: Colors.black54),
                ),
                // 👈 CHANGED: Yahan Rs. laga diya hai
                Text(
                  "Rs. ${widget.total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF3B2A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B2A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : placeOrder,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Place Order",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3B2A1A),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool number = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF3B2A1A).withOpacity(0.6)),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFBF9F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _paymentChip(String type, IconData icon) {
    bool isSelected = paymentMethod == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => paymentMethod = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3B2A1A)
                : const Color(0xFFFBF9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B2A1A)
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF3B2A1A),
              ),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF3B2A1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ORDER SUCCESS SCREEN ──────────────────────────────────────
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final double total;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE6),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Order Placed!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B2A1A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your order has been confirmed",
                  style: TextStyle(color: Colors.black45, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Order ID",
                            style: TextStyle(color: Colors.black45),
                          ),
                          Text(
                            "#${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B2A1A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Amount Paid",
                            style: TextStyle(color: Colors.black45),
                          ),
                          // 👈 CHANGED: Yahan Rs. laga diya hai
                          Text(
                            "Rs. ${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF3B2A1A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Status",
                            style: TextStyle(color: Colors.black45),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Pending",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B2A1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const homescreen()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Continue Shopping",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
