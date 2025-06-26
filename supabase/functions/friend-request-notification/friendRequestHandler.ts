// supabase/functions/friend-request-notification/friendRequestHandler.ts

import { SupabaseClient } from "npm:@supabase/supabase-js@2.49.1";
import { sendFCMNotification } from "../shared/fcmService.ts";
import { FCMPayload, FriendRequestWebhookPayload } from "../shared/types.ts";

export async function handleFriendRequest(
  payload: FriendRequestWebhookPayload,
  supabase: SupabaseClient,
) {
  const { receiver_id, sender_id } = payload.record;

  // 수신자 FCM 토큰 가져오기
  const { data: receiverData, error: receiverError } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", receiver_id)
    .single();

  if (receiverError || !receiverData) {
    throw new Error("수신자 FCM 토큰을 찾을 수 없습니다");
  }

  const fcmToken = receiverData.fcm_token as string;

  // 보낸 사람 정보 가져오기 - 필요 없음
  const { data: senderData, error: senderError } = await supabase
    .from("profiles")
    .select("nickname")
    .eq("id", sender_id)
    .single();

  if (senderError || !senderData) {
    throw new Error("보낸 사람 정보를 찾을 수 없습니다");
  }

  // 푸시 알림 내용 설정
  // const notificationPayload: FCMPayload = {
  //   title: "새로운 친구 요청",
  //   body: `${senderData.nickname}님이 친구 요청을 보냈습니다.`,
  //   data: {
  //     type: "friend_request",
  //     click_action: "FLUTTER_NOTIFICATION_CLICK",
  //     sender_id: sender_id,
  //   },
  // };

  const notificationPayload: FCMPayload = {
    data: {
      type: "friend_request",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      sender_id: sender_id,
    },
    android: {
      notification: {
        title_loc_key: "FRIEND_REQUEST_TITLE",
        body_loc_key: "FRIEND_REQUEST_BODY",
        body_loc_args: [senderData.nickname],
        icon: "ic_notification",
        image: "ic_notification_large",
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            "title-loc-key": "FRIEND_REQUEST_TITLE",
            "loc-key": "FRIEND_REQUEST_BODY",
            "loc-args": [senderData.nickname],
          },
        },
      },
    },
  };

  // FCM 알림 전송
  return await sendFCMNotification(fcmToken, notificationPayload);
}
