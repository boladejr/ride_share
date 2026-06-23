import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import stripe

app = FastAPI(title="RideShare Stripe Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

stripe.api_key = os.environ.get(
    "STRIPE_SECRET_KEY",
    "sk_test_51TbBjK8AjltEVd16ffaHUdJzDNqMTng5HgbW9bKI4EIg5OpEKihvLTZUnhm19hXT9vCUQeLSotYsFqw54hPSUcFX00RZWQsRyP",
)


class PaymentIntentRequest(BaseModel):
    amount: int  # in cents
    currency: str = "usd"


class PaymentIntentResponse(BaseModel):
    clientSecret: str
    paymentIntentId: str


@app.post("/create-payment-intent", response_model=PaymentIntentResponse)
async def create_payment_intent(request: PaymentIntentRequest):
    if request.amount < 50:
        raise HTTPException(status_code=400, detail="Amount must be at least 50 cents")

    try:
        intent = stripe.PaymentIntent.create(
            amount=request.amount,
            currency=request.currency,
            automatic_payment_methods={"enabled": True},
        )
        return PaymentIntentResponse(
            clientSecret=intent.client_secret,
            paymentIntentId=intent.id,
        )
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/health")
async def health():
    return {"status": "ok"}
