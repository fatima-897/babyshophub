import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'whatsapp_service.dart'; // Email service ka import hata diya hai

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = [
    "All",
    "Pending",
    "Confirmed",
    "Shipped",
    "Delivered",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showStatusUpdateSheet(
    BuildContext context,
    String docId,
    String currentStatus,
    Map<String, dynamic> orderData,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update Order Status",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ..._statuses.skip(1).map((status) {
                final bool isSelected = status == currentStatus;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    status,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFD81B60)
                          : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFFD81B60))
                      : const Icon(
                          Icons.circle_outlined,
                          color: Colors.black12,
                        ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      // 1. Firebase update
                      await FirebaseFirestore.instance
                          .collection("orders")
                          .doc(docId)
                          .update({'status': status});

                      String userName =
                          orderData['userName'] ??
                          orderData['name'] ??
                          'Customer';
                      String userPhone =
                          orderData['phone'] ??
                          orderData['phoneNo'] ??
                          orderData['phoneNumber'] ??
                          '';

                      String snackBarMessage = "Status updated successfully!";

                      // 2. WhatsApp Alert Trigger (Only WhatsApp Active)
                      if (userPhone.isNotEmpty) {
                        await WhatsAppService.sendOrderStatusUpdate(
                          phoneNumber: userPhone,
                          customerName: userName,
                          orderId: docId,
                          status: status,
                        );
                        snackBarMessage += " & WhatsApp redirected";
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(snackBarMessage),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              }), // <-- Bracket Error Fixed here
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF5),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Manage Orders 📦",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFD81B60),
          labelColor: const Color(0xFFD81B60),
          unselectedLabelColor: Colors.black45,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: _statuses.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((statusFilter) {
          final Stream<QuerySnapshot> streamPipeline = (statusFilter == "All")
              ? FirebaseFirestore.instance.collection("orders").snapshots()
              : FirebaseFirestore.instance
                    .collection("orders")
                    .where("status", isEqualTo: statusFilter)
                    .snapshots();

          return StreamBuilder<QuerySnapshot>(
            stream: streamPipeline,
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
                  child: Text(
                    "No $statusFilter orders found",
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                );
              }

              final orders = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final o = orders[index];
                  final Map<String, dynamic>? data =
                      o.data() as Map<String, dynamic>?;
                  final String currentStatus = data?['status'] ?? "Pending";
                  final String orderId = o.id.length > 6
                      ? o.id.substring(0, 6).toUpperCase()
                      : o.id.toUpperCase();
                  final List itemsList = data?['items'] ?? [];

                  final String customerName =
                      data?['userName'] ?? data?['name'] ?? 'Unknown Customer';
                  final String customerEmail =
                      data?['userEmail'] ??
                      data?['email'] ??
                      'No Email Provided';
                  final String customerPhone =
                      data?['phone'] ??
                      data?['phoneNo'] ??
                      data?['phoneNumber'] ??
                      'No Phone Provided';

                  // ✨ Feedback Data Retrieval
                  final Map<String, dynamic>? feedbackData =
                      data?['feedback'] as Map<String, dynamic>?;

                  Color statusColor = const Color(0xFFD81B60);
                  if (currentStatus == "Delivered") statusColor = Colors.green;
                  if (currentStatus == "Shipped") statusColor = Colors.blue;
                  if (currentStatus == "Confirmed") {
                    statusColor = Colors.amber.shade800;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ID: #$orderId",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                currentStatus,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            "Total: Rs. ${data?['total'] ?? '0'}",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        children: [
                          const Divider(color: Color(0xFFF5F5F5), thickness: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Customer: $customerName",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "WhatsApp: $customerPhone",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Email: $customerEmail",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (data?['address'] != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    data?['address'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemsList.length,
                            itemBuilder: (context, itemIndex) {
                              final item = itemsList[itemIndex];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${item['name'] ?? 'Product'}  x${item['quantity'] ?? 1}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "PKR ${item['price'] ?? '0'}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          //  Integrated: Beautiful Feedback Box UI
                          if (feedbackData != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFF0F5,
                                ), // Subtle Pink Touch
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFC0CB),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.rate_review_outlined,
                                            size: 16,
                                            color: Color(0xFFD81B60),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "Customer Feedback",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFFD81B60),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          final int currentRating =
                                              feedbackData['rating'] ?? 0;
                                          return Icon(
                                            Icons.star,
                                            size: 14,
                                            color: starIndex < currentRating
                                                ? Colors.amber
                                                : Colors.grey.shade300,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (feedbackData['review'] != null &&
                                      feedbackData['review']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '"${feedbackData['review']}"',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showStatusUpdateSheet(
                                context,
                                o.id,
                                currentStatus,
                                data ?? {},
                              ),
                              icon: const Icon(
                                Icons.edit_road_rounded,
                                size: 16,
                              ),
                              label: const Text("Change Delivery Stage"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD81B60),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 38),
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
          );
        }).toList(),
      ),
    );
  }
}
