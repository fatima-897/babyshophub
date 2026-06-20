import 'package:babyshophub/User/TrackOrder.dart';
import 'package:babyshophub/User/user_cart.dart';
import 'package:babyshophub/User/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserOrders extends StatelessWidget {
  const UserOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your orders.')),
      );
    }

    // UPDATED QUERY: Humne .orderBy hata diya hai taake index ka error khatam ho jaye.
    // Ab yeh mobile aur web dono par bina kisi error ke direct chalega.
    final ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A1A),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B2A1A)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No orders found.',
                style: TextStyle(color: Color(0xFF3B2A1A), fontSize: 16),
              ),
            );
          }

          // Flutter code ke andar hi orders ko sort kar rahe hain taake index ki zaroorat na pare
          final orders = snapshot.data!.docs.toList();
          orders.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'];
            final bTime = bData['createdAt'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime); // Naye orders upar aayenge
            }
            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;

              final status = (data['status'] ?? 'Pending').toString();

              // Safe Double Parsing
              final total = data['total'];
              double parsedTotal = 0.00;
              if (total is num) {
                parsedTotal = total.toDouble();
              } else if (total is String) {
                parsedTotal = double.tryParse(total) ?? 0.00;
              }

              // Safe DateTime Parsing
              final createdAt = data['createdAt'];
              DateTime? createdAtDt;
              if (createdAt is Timestamp) {
                createdAtDt = createdAt.toDate();
              } else if (createdAt is DateTime) {
                createdAtDt = createdAt;
              } else if (createdAt is String) {
                createdAtDt = DateTime.tryParse(createdAt);
              } else if (createdAt is int) {
                createdAtDt = DateTime.fromMillisecondsSinceEpoch(createdAt);
              }

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${(orderDoc.id.length >= 6 ? orderDoc.id.substring(0, 6) : orderDoc.id).toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B2A1A),
                              fontSize: 15,
                            ),
                          ),
                          _StatusPill(status: status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: \$${parsedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (createdAtDt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Placed: ${_formatDateTime(createdAtDt)}',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            _showOrderItemsBottomSheet(context, data);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B2A1A),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text(
                            'View Items',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B2A1A),
        unselectedItemColor: Colors.black45,
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
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
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pin_drop_rounded),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showOrderItemsBottomSheet(
    BuildContext context,
    Map<String, dynamic> orderData,
  ) {
    final itemsDynamic = orderData['items'];
    final items = (itemsDynamic is List)
        ? itemsDynamic
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF2EDE6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Ordered Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B2A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No items found.')),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final name = (item['name'] ?? 'Unknown Item')
                              .toString();
                          final image = (item['image'] ?? '').toString();
                          final qty =
                              int.tryParse(
                                item['quantity']?.toString() ?? '',
                              ) ??
                              1;
                          final price =
                              double.tryParse(
                                item['price']?.toString() ?? '',
                              ) ??
                              0.0;

                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: image.isNotEmpty
                                        ? Image.network(
                                            image,
                                            width: 54,
                                            height: 54,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                  width: 54,
                                                  height: 54,
                                                  color: const Color(
                                                    0xFFE8E0D0,
                                                  ),
                                                  child: const Icon(
                                                    Icons.image_outlined,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 54,
                                            height: 54,
                                            color: const Color(0xFFE8E0D0),
                                            child: const Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3B2A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty: $qty',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${(price * qty).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3B2A1A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF7B9E7B).withOpacity(0.12);
    Color fg = const Color(0xFF7B9E7B);

    switch (status.toLowerCase()) {
      case 'pending':
        bg = const Color(0xFFFFC107).withOpacity(0.16);
        fg = const Color(0xFFFFA000);
        break;
      case 'confirmed':
        bg = const Color(0xFF1976D2).withOpacity(0.12);
        fg = const Color(0xFF1976D2);
        break;
      case 'shipped':
        bg = const Color(0xFF9C27B0).withOpacity(0.12);
        fg = const Color(0xFF9C27B0);
        break;
      case 'delivered':
        bg = const Color(0xFF2E7D32).withOpacity(0.12);
        fg = const Color(0xFF2E7D32);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
