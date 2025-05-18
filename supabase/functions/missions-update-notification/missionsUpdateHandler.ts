// supabase/functions/friend-request-notification/friendRequestHandler.ts

import { SupabaseClient } from "npm:@supabase/supabase-js@2.49.1";
import { sendFCMNotification } from "../shared/fcmService.ts";
import { FCMPayload, MissionsUpdateWebhookPayload } from "../shared/types.ts";

/// 수신자 FCM토큰 가져옴
async function getFCMToken(supabase: SupabaseClient, userId: string) {
  const { data: receiverData, error: receiverError } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", userId)
    .single();

  if (receiverError || !receiverData) {
    throw new Error(`수신자 FCM 토큰을 찾을 수 없습니다: ${userId}`);
  }

  return receiverData.fcm_token as string;
}

export async function handleMissionsUpdate(
  payload: MissionsUpdateWebhookPayload,
  supabase: SupabaseClient,
) {
  const { id, creator_id, manito_id, status, description } = payload.record;

  let notificationPayload: FCMPayload;
  let fcmToken: string;

  try {
    // 미션 수락
    if (status === "진행중" && description === null) {
      fcmToken = await getFCMToken(supabase, creator_id);

      notificationPayload = {
        title: "마니또 미션 수락!",
        body: `마니또를 추측 해보세요.`,
        data: {
          type: "update_mission_progress",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          mission_id: id,
        },
      };
    } // 미션 작성 완료
    else if (status === "추측중") {
      fcmToken = await getFCMToken(supabase, creator_id);
      notificationPayload = {
        title: "마니또 미션 완료!",
        body: `마니또를 추측 해보세요.`,
        data: {
          type: "update_mission_guess",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          mission_id: id,
        },
      };
    } // 미션 종료
    else if (status === "완료") {
      fcmToken = await getFCMToken(supabase, manito_id);

      notificationPayload = {
        title: "미션 종료!",
        body: `친구가 추리한 내용을 확인해보세요.`,
        data: {
          type: "update_mission_complete",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          mission_id: id,
        },
      };
    } // 미션 작성 업데이트 예외
    else {
      return new Response("알림 없음", { status: 200 });
    }

    // FCM 알림 전송
    await sendFCMNotification(fcmToken, notificationPayload);
    return new Response("FCM 알림 전송 완료", { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response("알림 전송 실패", { status: 500 });
  }
}
