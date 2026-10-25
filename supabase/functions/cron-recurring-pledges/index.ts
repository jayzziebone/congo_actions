import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (_req: Request) => {
  try {
    const today = new Date().toISOString().split("T")[0];

    // Find all active Mobile Money pledges where next_billing_date <= today
    const { data: pledges, error } = await supabase
      .from("subscriptions")
      .select("id, donor_id, campaign_id, amount_usd_cents, amount_cdf, currency, phone_number, profiles(full_name, phone_number)")
      .eq("payment_rail", "MOBILE_MONEY_PLEDGE")
      .eq("status", "ACTIVE")
      .lte("next_billing_date", today);

    if (error) throw error;

    const updatedIds: string[] = [];

    for (const pledge of pledges || []) {
      // 1. Mark subscription as requiring action today
      await supabase
        .from("subscriptions")
        .update({ action_needed_today: true })
        .eq("id", pledge.id);

      updatedIds.push(pledge.id);

      // 2. Dispatch FCM Push Notification (In production, sends to user FCM device token)
      console.log(`Pledge renewal notification queued for pledge ${pledge.id} (${pledge.phone_number})`);
    }

    return new Response(
      JSON.stringify({
        status: "COMPLETED",
        pledges_flagged: updatedIds.length,
        processed_ids: updatedIds,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
