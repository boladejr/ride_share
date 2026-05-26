class StripeConfig {
  // TODO: Replace with your Stripe publishable key from
  // https://dashboard.stripe.com/test/apikeys
  static const String publishableKey = 'pk_test_51TbBjK8AjltEVd16moj68a3L4HK1GQiR39gvRpKDBqQQFEqr7909znUaqxy9krouBHCD72S7NTh0MbtfR5cEXJnJ00ZHfurPhW';

  // TODO: Replace with your backend URL that creates PaymentIntents
  // You'll need a simple backend (e.g. Firebase Cloud Function) that calls
  // Stripe's API with your secret key to create PaymentIntents.
  static const String paymentBackendUrl = 'YOUR_PAYMENT_BACKEND_URL';

  static bool get isConfigured =>
      publishableKey != 'YOUR_STRIPE_PUBLISHABLE_KEY';
}
