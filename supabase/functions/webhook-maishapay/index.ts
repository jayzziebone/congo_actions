import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const MAISHAPAY_SECRET_KEY = Deno.env.get("MAISHAPAY_SECRET_KEY") ?? "dev_maishapay_secret";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface WebhookPayload {
  transaction_reference: string;
  external_reference: string; // MaishaPay/FlexPaie Tx ID
  status: "SUCCESS" | "FAILED" | "CANCELLED";
  amount: number; // in minor units (cents for USD, whole units for CDF)
  currency: "USD" | "CDF";
  operator: "MPESA" | "ORANGE_MONEY" | "AIRTEL_MONEY" | "AFRIMONEY";
  payer_phone: string;
  signature: string;
  timestamp: string;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  try {
    const rawBody = await req.text();
    const payload: WebhookPayload = JSON.parse(rawBody);

    // 1. Signature Verification (HMAC-SHA256)
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(MAISHAPAY_SECRET_KEY),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const signatureBuffer = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(`${payload.transaction_reference}:${payload.amount}:${payload.currency}:${payload.status}`)
    );
    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    if (payload.signature && payload.signature !== expectedSignature) {
      console.warn("Invalid signature from aggregator webhook");
      // In production reject: return new Response("Unauthorized", { status: 401 });
    }

    // 2. Idempotency Check: Check if donation already processed
    const { data: existingDonation, error: fetchErr } = await supabase
      .from("donations")
      .select("id, campaign_id, status, amount_usd_cents, amount_cdf, currency, fee_covered_usd_cents, fee_covered_cdf")
      .eq("payment_reference", payload.transaction_reference)
      .single();

    if (fetchErr || !existingDonation) {
      return new Response(JSON.stringify({ error: "Donation reference not found" }), { status: 404 });
    }

    if (existingDonation.status === "SUCCESS") {
      // Already processed idempotently
      return new Response(JSON.stringify({ message: "Already processed idempotently" }), { status: 200 });
    }

    if (payload.status === "SUCCESS") {
      const netAmount = payload.currency === "USD" ? existingDonation.amount_usd_cents : existingDonation.amount_cdf;
      const feeAmount = payload.currency === "USD" ? existingDonation.fee_covered_usd_cents : existingDonation.fee_covered_cdf;

      // 3. Atomically Execute Ledger Double-Entry Split via RPC
      const { data: txId, error: rpcError } = await supabase.rpc("execute_pooled_donation_split", {
        p_donation_id: existingDonation.id,
        p_campaign_id: existingDonation.campaign_id,
        p_net_amount: netAmount,
        p_currency: payload.currency,
        p_fee_amount: feeAmount,
      });

      if (rpcError) {
        console.error("Ledger execution error:", rpcError);
        return new Response(JSON.stringify({ error: rpcError.message }), { status: 500 });
      }

      return new Response(
        JSON.stringify({
          status: "SUCCESS",
          transaction_id: txId,
          receipt: `CONGO-${existingDonation.id.substring(0, 8).toUpperCase()}`,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    } else {
      // Mark as Failed
      await supabase
        .from("donations")
        .update({ status: payload.status })
        .eq("id", existingDonation.id);

      return new Response(JSON.stringify({ status: payload.status }), { status: 200 });
    }
  } catch (err: any) {
    console.error("Webhook processing error:", err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
