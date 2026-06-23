const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Stripe = require("stripe");
const cors = require("cors")({origin: true});

admin.initializeApp();

const stripe = new Stripe(functions.config().stripe.secret_key);

exports.createPaymentIntent = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    try {
      const {amount, currency = "usd"} = req.body;

      if (!amount || amount < 50) {
        res.status(400).json({error: "Amount must be at least 50 cents"});
        return;
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency,
        automatic_payment_methods: {enabled: true},
      });

      res.json({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      });
    } catch (error) {
      res.status(400).json({error: error.message});
    }
  });
});

exports.health = functions.https.onRequest((req, res) => {
  cors(req, res, () => {
    res.json({status: "ok"});
  });
});
