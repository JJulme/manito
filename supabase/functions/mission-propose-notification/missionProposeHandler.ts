// supabase/functions/friend-request-notification/friendRequestHandler.ts

import { SupabaseClient } from "npm:@supabase/supabase-js@2.49.1";
import { sendFCMNotification } from "../shared/fcmService.ts";
import { FCMPayload, MissionProposeWebhookPayload } from "../shared/types.ts";

export async function handleMissionPropose(
  payload: MissionProposeWebhookPayload,
  supabase: SupabaseClient,
) {
  const { mission_id, friend_id } = payload.record;

  // 수신자 토큰 가져오기
  const { data: receiverData, error: receiverError } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", friend_id)
    .single();

  if (receiverError || !receiverData) {
    throw new Error("수신자 FCM 토큰을 찾을 수 없습니다");
  }

  const fcmToken = receiverData.fcm_token as string;

  // 푸시 알림 내용 설정
  // const notificationPayload: FCMPayload = {
  //   title: '미션 도착!',
  //   body: `제한 시간안에 수락하세요.`,
  //   data: {
  //     type: 'mission_propose',
  //     click_action: 'FLUTTER_NOTIFICATION_CLICK',
  //     sender_id: mission_id
  //   }
  // }

  const notificationPayload: FCMPayload = {
    data: {
      type: "mission_propose",
      mission_id: mission_id,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      notification: {
        title_loc_key: "MISSION_PROPOSE_TITLE",
        body_loc_key: "MISSION_PROPOSE_BODY",
        icon: "ic_notification",
        image: "ic_notification_large",
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            "title-loc-key": "MISSION_PROPOSE_TITLE",
            "loc-key": "MISSION_PROPOSE_BODY",
          },
        },
      },
    },
  };

  // FCM 알림 전송
  return await sendFCMNotification(fcmToken, notificationPayload);
}
