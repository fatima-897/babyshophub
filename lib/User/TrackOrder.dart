import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _orderData;
  String?
  _actualDocId; // FIX: Original Firestore Document ID ko track karne ke liye
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // Feedback States
  int _selectedRating = 5;
  bool _feedbackSubmitted = false;
  bool _isSubmittingFeedback = false;

  // Premium App Identity Colors (Brown Aesthetic)
  static const Color colorPrimaryDark = Color(
    0xFF3B2A1A,
  ); // Rich Deep Dark Brown
  static const Color colorBrownMedium = Color(
    0xFF7A5C43,
  ); // Smooth Caramel Brown Accent
  static const Color colorBrownLight = Color(0xFFBA9B81); // Light Sand Accent
  static const Color colorBeigeBg = Color(
    0xFFFBF9F6,
  ); // Premium Pearl Off-White
  static const Color colorWarmSurface = Color(0xFFF3EDE6); // Warm Soft Beige

  int _getStatusStep(String status) {
    switch (status) {
      case 'Pending':
        return 0;
      case 'Confirmed':
        return 1;
      case 'Shipped':
        return 2;
      case 'Delivered':
        return 3;
      default:
        return 0;
    }
  }

  void _searchOrder() async {
    final String inputId = _orderIdController.text.trim();

    if (inputId.isEmpty) {
      setState(() {
        _errorMessage = "Kripya sahi Order ID enter karein.";
        _orderData = null;
        _actualDocId = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
      _feedbackSubmitted = false; // Reset feedback state on new search
      _feedbackController.clear();
      _selectedRating = 5;
      _actualDocId = null;
    });

    try {
      DocumentSnapshot doc = await _db.collection("orders").doc(inputId).get();

      if (doc.exists) {
        setState(() {
          _orderData = doc.data() as Map<String, dynamic>?;
          _actualDocId = doc.id; // Exact ID mil gayi
          _isLoading = false;
          if (_orderData!.containsKey('feedback')) {
            _feedbackSubmitted = true;
          }
        });
      } else {
        final querySnapshot = await _db.collection("orders").get();
        DocumentSnapshot? matchingDoc;

        for (var d in querySnapshot.docs) {
          if (d.id.toLowerCase().startsWith(inputId.toLowerCase()) ||
              d.id.toLowerCase() == inputId.toLowerCase()) {
            matchingDoc = d;
            break;
          }
        }

        if (matchingDoc != null) {
          setState(() {
            _orderData = matchingDoc!.data() as Map<String, dynamic>?;
            _actualDocId = matchingDoc
                .id; // Partial search se mili hui correct ID save karli
            _isLoading = false;
            if (_orderData!.containsKey('feedback')) {
              _feedbackSubmitted = true;
            }
          });
        } else {
          setState(() {
            _orderData = null;
            _actualDocId = null;
            _errorMessage = "Order ID nahi mili. Sahi details check karein.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _orderData = null;
        _actualDocId = null;
        _errorMessage = "Server connectivity issue. Dobara koshish karein.";
        _isLoading = false;
      });
    }
  }

  void _submitFeedback() async {
    // FIX: TextField ke bajaye track kiye gaye _actualDocId ko priority dein
    final String orderId = _actualDocId ?? _orderIdController.text.trim();
    final String reviewText = _feedbackController.text.trim();

    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sahi Order ID dastyab nahi hai.")),
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      await _db.collection("orders").doc(orderId).update({
        'feedback': {
          'rating': _selectedRating,
          'review': reviewText,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      setState(() {
        _isSubmittingFeedback = false;
        _feedbackSubmitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback dene ka shukriya! ❤️"),
          backgroundColor: colorPrimaryDark,
        ),
      );
    } catch (e) {
      // Is print se aap debug console/terminal mein exact error dekh sakti hain agar rules ka masla ho
      print("Firebase Submit Error: $e");

      setState(() {
        _isSubmittingFeedback = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback submit nahi ho saka. Dobara koshish karein."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDelivered =
        _orderData != null && (_orderData!['status'] == 'Delivered');

    return Scaffold(
      backgroundColor: colorBeigeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Track Order",
          style: TextStyle(
            color: colorPrimaryDark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colorPrimaryDark,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glassmorphic Input Section
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorPrimaryDark.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Apna Order Track Karein",
                        style: TextStyle(
                          color: colorPrimaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: colorBeigeBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _orderIdController,
                          style: const TextStyle(
                            color: colorPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: "Order ID enter karein...",
                            hintStyle: TextStyle(
                              color: colorBrownMedium.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.tag_rounded,
                              color: colorBrownMedium,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _searchOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimaryDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Status Check Karein",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // LIVE RESULT DETAILS
            if (_orderData != null && !_isLoading) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Customer Name",
                        style: TextStyle(
                          color: colorBrownMedium.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _orderData!['userName'] ??
                            _orderData!['name'] ??
                            'Guest Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: colorPrimaryDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorWarmSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "PKR ${_orderData!['total'] ?? '0'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: colorBrownMedium,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEFEAE4), thickness: 1.2),
              const SizedBox(height: 20),

              // DYNAMIC FEEDBACK SECTION (Visible only if order is delivered)
              if (isDelivered) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorPrimaryDark.withOpacity(0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _feedbackSubmitted
                      ? const Column(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: colorBrownMedium,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Aapka Feedback Humein Mil Chuka Hai!",
                              style: TextStyle(
                                color: colorPrimaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Humari shopping experience ko behtar banane ke liye shukriya.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorBrownMedium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Apna Experience Share Karein ⭐",
                              style: TextStyle(
                                color: colorPrimaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Aapko product aur service kaisi lagi? Humein zaroor batayein.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Interactive Star Rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < _selectedRating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: index < _selectedRating
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedRating = index + 1;
                                    });
                                  },
                                );
                              }),
                            ),
                            const SizedBox(height: 8),

                            // Feedback Text Field
                            Container(
                              decoration: BoxDecoration(
                                color: colorBeigeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _feedbackController,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: colorPrimaryDark,
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      "Koi sujhao ya experience likhein (Optional)...",
                                  hintStyle: TextStyle(
                                    color: Colors.black26,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: _submitFeedback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorBrownMedium,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmittingFeedback
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Feedback Submit Karein",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 28),
              ],

              const Text(
                "Live Tracking Timeline",
                style: TextStyle(
                  color: colorPrimaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),

              // Timeline Design
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    _buildTimelineRow(
                      "Order Placed",
                      "Aapka order receive ho chuka hai.",
                      _getStatusStep(_orderData!['status'] ?? 'Pending') >= 0,
                    ),
                    _buildLineConnector(
                      _getStatusStep(_orderData!['status'] ?? 'Pending') >= 1,
                    ),
                    _buildTimelineRow(
                      "Order Confirmed",
                      "Vendor ne order confirm kar diya hai.",
                      _getStatusStep(_orderData!['status'] ?? 'Pending') >= 1,
                    ),
                    _buildLineConnector(
                      _getStatusStep(_orderData!['status'] ?? 'Pending') >= 2,
                    ),
                    _buildTimelineRow(
                      "Shipped",
                      "Rider aapki taraf nikal chuka hai.",
                      _getStatusStep(_orderData!['status'] ?? 'Pending') >= 2,
                    ),
                    _buildLineConnector(
                      _getStatusStep(_orderData!['status'] ?? 'Pending') >= 3,
                    ),
                    _buildTimelineRow(
                      "Delivered",
                      "Parcel kamyabi se pohnch gaya hai. Enjoy! 🎉",
                      _getStatusStep(_orderData!['status'] ?? 'Pending') >= 3,
                    ),
                  ],
                ),
              ),
            ] else if (_hasSearched &&
                !_isLoading &&
                _errorMessage == null) ...[
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "Koi details fetch nahi ho sakeen.",
                  style: TextStyle(
                    color: colorBrownMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(String title, String subtitle, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isCompleted ? colorBrownMedium : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? colorBrownMedium : Colors.grey.shade300,
              width: isCompleted ? 0 : 2.5,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCompleted ? colorPrimaryDark : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted
                      ? colorBrownMedium.withOpacity(0.8)
                      : Colors.grey.shade400,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineConnector(bool isActive) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 36,
        width: 2.5,
        color: isActive ? colorBrownMedium : Colors.grey.shade200,
      ),
    );
  }
}
