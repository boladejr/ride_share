import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripePaymentService {
  static final StripePaymentService _instance = StripePaymentService._internal();
  factory StripePaymentService() => _instance;
  StripePaymentService._internal();

  bool get isConfigured => StripeConfig.isConfigured;

  Future<Map<String, dynamic>?> createPaymentIntent({
    required int amountInCents,
    String currency = 'usd',
  }) async {
    if (!isConfigured) return null;

    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.paymentBackendUrl}/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Stripe payment error: $e');
      return null;
    }
  }

  Future<bool> confirmPayment(String clientSecret) async {
    if (!isConfigured) return true;

    // In a real implementation, this would use Stripe.instance.confirmPayment()
    // which requires the Stripe SDK to be properly initialized with the
    // publishable key. For web, this uses Stripe.js under the hood.
    //
    // Example:
    // await Stripe.instance.confirmPayment(
    //   paymentIntentClientSecret: clientSecret,
    //   data: PaymentMethodParams.card(
    //     paymentMethodData: PaymentMethodData(),
    //   ),
    // );
    return true;
  }
}
