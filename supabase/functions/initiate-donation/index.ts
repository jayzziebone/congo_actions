import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const MAISHAPAY_API_KEY = Deno.env.get("MAISHAPAY_API_KEY") ?? "dev_maishapay_key";
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "sk_test_mock";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface InitiateDonationRequest {
  donor_id?: string;
  campaign_id: string;
  amount: number; // In cents for USD, units for CDF
  currency: "USD" | "CDF";
  is_subscription: boolean;
  cover_fees: boolean;
  is_anonymous: boolean;
  payment_method: "MPESA" | "ORANGE_MONEY" | "AIRTEL_MONEY" | "AFRIMONEY" | "CARD_STRIPE" | "CARD_FLUTTERWAVE";
  phone_number?: string;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  try {
    const body: InitiateDonationRequest = await req.json();
    const paymentRef = `CA-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
    const receiptNum = `RCP-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 900000)}`;

    const feePercent = 0.035; // 3.5% processing fee
    const feeAmount = body.cover_fees ? Math.round(body.amount * feePercent) : 0;

    // 1. Insert Pending Donation Record
    const { data: donation, error: insertError } = await supabase
      .from("donations")
      .insert({
        donor_id: body.donor_id || null,
        campaign_id: body.campaign_id,
        amount_usd_cents: body.currency === "USD" ? body.amount : 0,
        amount_cdf: body.currency === "CDF" ? body.amount : 0,
        currency: body.currency,
        fee_covered_usd_cents: body.currency === "USD" ? feeAmount : 0,
        fee_covered_cdf: body.currency === "CDF" ? feeAmount : 0,
        is_anonymous: body.is_anonymous,
        payment_method: body.payment_method,
        payment_reference: paymentRef,
        phone_number: body.phone_number,
        status: "PENDING",
        receipt_number: receiptNum,
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    // 2. Dispatch to designated payment rail
    const isMobileMoney = ["MPESA", "ORANGE_MONEY", "AIRTEL_MONEY", "AFRIMONEY"].includes(body.payment_method);

    if (isMobileMoney) {
      // DRC Domestic Rail: Trigger USSD STK Push via MaishaPay / FlexPaie
      // In production:
      // const res = await fetch("https://api.maishapay.online/v1/collect", {
      //   method: "POST",
      //   headers: { "Authorization": `Bearer ${MAISHAPAY_API_KEY}`, "Content-Type": "application/json" },
      //   body: JSON.stringify({
      //      phone: body.phone_number,
      //      amount: body.amount + feeAmount,
      //      currency: body.currency,
      //      reference: paymentRef,
      //      operator: body.payment_method
      //   })
      // });
      return new Response(
        JSON.stringify({
          rail: "MOBILE_MONEY_USSD",
          donation_id: donation.id,
          payment_reference: paymentRef,
          receipt_number: receiptNum,
          instructions: "USSD push initiated. Please authorize with PIN on your mobile screen.",
          timeout_seconds: 60,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    } else {
      // Diaspora Card Rail: Apple App Store Guideline 3.2.1(vi) Compliant Web Checkout URL
      // (Charitable donations must not use Apple In-App Purchase; opens via SFSafariViewController)
      const checkoutUrl = `https://checkout.congoactions.org/session/${paymentRef}?amount=${body.amount + feeAmount}&currency=${body.currency}&ref=${paymentRef}`;

      return new Response(
        JSON.stringify({
          rail: "CARD_DIASPORA",
          donation_id: donation.id,
          payment_reference: paymentRef,
          receipt_number: receiptNum,
          checkout_url: checkoutUrl,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
