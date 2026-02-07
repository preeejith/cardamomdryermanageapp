import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<bool> sendMessage({
    required String phone,
    required String message,
  }) async {
    // Clean phone number
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Create WhatsApp URL
    final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error launching WhatsApp: $e');
      return false;
    }
  }

  static String getStockReceivedMessage({
    required String customerName,
    required double weight,
    required String date,
  }) {
    return '''
Hello $customerName,

We have received your cardamom for drying:

📦 Weight: $weight KG
📅 Date: $date

We will notify you once the drying process is complete.

Thank you for your business!
''';
  }

  static String getDryingCompletedMessage({
    required String customerName,
    required double freshWeight,
    required double driedWeight,
    required double amount,
  }) {
    return '''
Hello $customerName,

Your cardamom drying is complete!

📦 Fresh Weight: $freshWeight KG
📊 Dried Weight: $driedWeight KG
💰 Amount: ₹$amount

Please collect your cardamom at your convenience.

Thank you!
''';
  }

  static String getPaymentReminderMessage({
    required String customerName,
    required double balanceAmount,
  }) {
    return '''
Hello $customerName,

This is a friendly reminder about your pending payment:

💰 Balance Amount: ₹$balanceAmount

Please make the payment at your earliest convenience.

Thank you!
''';
  }

  static String getBillMessage({
    required String customerName,
    required double totalAmount,
    required double paidAmount,
    required double balanceAmount,
  }) {
    return '''
Hello $customerName,

Here is your bill summary:

💰 Total Amount: ₹$totalAmount
✅ Paid Amount: ₹$paidAmount
⚠️ Balance: ₹$balanceAmount

Thank you for your business!
''';
  }
}
