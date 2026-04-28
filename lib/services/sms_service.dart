import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SmsService {
  // Production credentials loaded from .env file
  static String get _accountSid => dotenv.get('TWILIO_ACCOUNT_SID', fallback: '');
  static String get _authToken => dotenv.get('TWILIO_AUTH_TOKEN', fallback: '');
  static String get _messagingServiceSid => dotenv.get('TWILIO_MESSAGING_SERVICE_SID', fallback: '');

  /// Sends an SMS message to the specified [phone] number.
  static Future<bool> sendSMS({
    required String phone,
    required String message,
  }) async {
    if (_accountSid.isEmpty || _accountSid.contains('YOUR_TWILIO')) {
      debugPrint('SmsService: API Keys not set. SMS to $phone would say: "$message"');
      return true;
    }

    // Standardize phone number format if needed (e.g., ensure it has a country code)
    // Assuming Saudi numbers for Wadiah, adding +966 if not present.
    String formattedPhone = phone;
    if (formattedPhone.startsWith('05')) {
      formattedPhone = '+966${formattedPhone.substring(1)}';
    }

    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_accountSid:$_authToken'))}',
        },
        body: {
          'MessagingServiceSid': _messagingServiceSid,
          'To': formattedPhone,
          'Body': message,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('SMS sent successfully to $formattedPhone');
        return true;
      } else {
        debugPrint('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }
}
