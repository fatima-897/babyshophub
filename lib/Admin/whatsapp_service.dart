import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> sendOrderStatusUpdate({
    required String phoneNumber,
    required String customerName,
    required String orderId,
    required String status,
  }) async {
    // Clean phone number (e.g., removing spaces or dashes)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Country code handling (Agar Pakistan ka number hai aur 0 se shuru horha hai)
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '92${cleanNumber.substring(1)}';
    }

    String message =
        "Salaam *$customerName*,\n\n"
        "Your order *#$orderId* status has been updated to: *\"$status\"*. 📦\n\n"
        "Thank you for shopping with us!";

    String url =
        "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}";
    final Uri whatsappUri = Uri.parse(url);

    try {
      // Pehle standard tarike se check karke chalayein
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Agar canLaunchUrl false de (jo Android 11+ par aam hai),
        // to direct force launch karein, yeh chal jata hai.
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Agar dono tarike fail ho jayein (jaise mobile me WhatsApp install hi na ho)
      debugPrint("WhatsApp error: $e");
      throw 'Could not launch WhatsApp for $cleanNumber';
    }
  }
}
