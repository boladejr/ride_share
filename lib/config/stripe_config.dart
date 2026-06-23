class StripeConfig {
  // TODO: Replace with your Stripe publishable key from
  // https://dashboard.stripe.com/test/apikeys
  static const String publishableKey = 'pk_test_51TbBjK8AjltEVd16moj68a3L4HK1GQiR39gvRpKDBqQQFEqr7909znUaqxy9krouBHCD72S7NTh0MbtfR5cEXJnJ00ZHfurPhW';

  // Replace with your permanent backend URL that creates PaymentIntents.
  // The backend must have your Stripe secret key and expose a
  // POST /create-payment-intent endpoint. Deploy options:
  // - Firebase Cloud Functions
  // - Fly.io / Railway / Render
  // - Any server that can run the stripe-backend/ FastAPI app
  static const String paymentBackendUrl = 'https://rideshare-production-a046.up.railway.app';

  static bool get isConfigured =>
      publishableKey != 'YOUR_STRIPE_PUBLISHABLE_KEY';
}
