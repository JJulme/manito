import { SupabaseClient } from "npm:@supabase/supabase-js@2.49.1";
import { sendFCMNotification } from "../shared/fcmService.ts";
import { FCMPayload } from "../shared/types.ts";

export async function handleComment(
  payload: any,
  supabase: SupabaseClient,
) {
  const { record_id, user_id: sender_id, content } = payload.record;

  // 1. Get record & room_id
  const { data: recordData, error: recordError } = await supabase
    .from("records")
    .select("room_id")
    .eq("record_id", record_id)
    .single();

  if (recordError || !recordData) {
    throw new Error(`Record ${record_id} not found: ${recordError?.message}`);
  }

  const roomId = recordData.room_id;

  // 2. Get sender info
  const { data: senderData } = await supabase
    .from("users")
    .select("name")
    .eq("user_id", sender_id)
    .single();

  const senderName = senderData?.name || "동료 요원";

  // 3. Get all room members except the sender
  const { data: members, error: membersError } = await supabase
    .from("room_members")
    .select("user_id, users!user_id(fcm_token)")
    .eq("room_id", roomId)
    .neq("user_id", sender_id);

  if (membersError) {
    throw new Error(`Failed to fetch room members: ${membersError.message}`);
  }

  const results = [];

  // 4. Send FCM push notification to each member
  for (const member of members || []) {
    const user = (member as any).users;
    const fcmToken = user?.fcm_token;

    if (fcmToken) {
      const notificationPayload: FCMPayload = {
        title: `[마니또 피드] ${senderName}님의 새로운 댓글`,
        body: content,
        data: {
          type: "new_comment",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          room_id: roomId,
          record_id: String(record_id),
          sender_id: sender_id,
        },
      };

      try {
        const res = await sendFCMNotification(fcmToken, notificationPayload);
        results.push(res);
      } catch (err) {
        console.error(`Failed to send FCM to user ${member.user_id}:`, err);
      }
    }
  }

  return { success: true, delivered_count: results.length };
}
