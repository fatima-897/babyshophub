import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static Future<void> sendOrderUpdateEmail({
    required String toEmail,
    required String customerName,
    required String orderId,
    required String status,
  }) async {
    const String serviceId = 'service_r15u9fi';
    const String templateId = 'template_cge7mq7';
    const String publicKey = 'n8Ew_Lcc793p-jI4U';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      print('📤 Sending email to: $toEmail');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id':
              publicKey, // 👈 EmailJS still uses "user_id" field but value = public key
          'template_params': {
            'to_email': toEmail,
            'customer_name': customerName,
            'order_id': orderId,
            'order_status': status,
          },
        }),
      );

      print('📩 Status Code: ${response.statusCode}');
      print('📩 Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Email sent successfully!');
      } else {
        print('❌ Email failed!');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }
}
