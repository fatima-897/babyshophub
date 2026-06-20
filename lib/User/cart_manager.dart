// lib/cart_manager.dart

class CartManager {
  // Yeh global list aapke saare cart items ko save rakhegi
  static final List<Map<String, dynamic>> cartItems = [];

  static void addToCart(Map<String, dynamic> item) {
    // Agar product pehle se cart mein hai, toh sirf uski quantity barha do
    int index = cartItems.indexWhere((element) => element['id'] == item['id']);
    if (index >= 0) {
      cartItems[index]['quantity'] += item['quantity'];
    } else {
      // Agar naya product hai, toh list mein add kar do
      cartItems.add(item);
    }
  }
}