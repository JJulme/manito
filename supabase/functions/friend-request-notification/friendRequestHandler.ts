import { SupabaseClient } from "npm:@supabase/supabase-js@2.49.1";
import { sendFCMNotification } from "../shared/fcmService.ts";
import { FCMPayload } from "../shared/types.ts";

export async function handleFriendRequest(
  payload: any,
  supabase: SupabaseClient,
) {
  const { receiver_id, requester_id } = payload.record;

  // 1. Get receiver FCM token
  const { data: receiverData, error: receiverError } = await supabase
    .from("users")
    .select("fcm_token")
    .eq("user_id", receiver_id)
    .single();

  if (receiverError || !receiverData?.fcm_token) {
    console.log("No FCM token found for receiver:", receiver_id);
    return { success: false, reason: "No receiver FCM token" };
  }

  const fcmToken = receiverData.fcm_token as string;

  // 2. Get requester name
  const { data: requesterData } = await supabase
    .from("users")
    .select("name")
    .eq("user_id", requester_id)
    .single();

  const requesterName = requesterData?.name || "새로운 요원";

  const notificationPayload: FCMPayload = {
    title: "새로운 비밀 친구 요청",
    body: `${requesterName}님이 친구 요청을 보냈습니다.`,
    data: {
      type: "friend_request",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      sender_id: requester_id,
    },
  };

  return await sendFCMNotification(fcmToken, notificationPayload);
}
