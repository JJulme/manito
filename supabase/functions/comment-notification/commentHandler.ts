// supabase/functions/friend-request-notification/friendRequestHandler.ts

import { SupabaseClient } from "npm:@supabase/supabase-js@2.49.1";
import { sendFCMNotification } from "../shared/fcmService.ts";
import { CommentWebhookPayload, FCMPayload } from "../shared/types.ts";

export async function handleComment(
  payload: CommentWebhookPayload,
  supabase: SupabaseClient,
) {
  const { mission_id, user_id, comment } = payload.record;

  // missions 데이터 가져오기
  const { data: missions } = await supabase
    .from("missions")
    .select("creator_id, manito_id")
    .eq("id", mission_id)
    .single();

  let receiver_id;
  if (missions?.creator_id === user_id) {
    receiver_id = missions.manito_id;
  } else if (missions?.manito_id === user_id) {
    receiver_id = missions.creator_id;
  } else {
    console.error("일치하는 사용자가 없습니다.");
    throw new Error("댓글 알릴 사용자 없음");
  }

  // 수신자 토큰 가져오기
  const { data: receiverData, error: receiverError } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", receiver_id)
    .single();

  if (receiverError || !receiverData) {
    throw new Error("수신자 FCM 토큰을 찾을 수 없습니다");
  }

  const fcmToken = receiverData.fcm_token as string;

  // 발신자 토큰 가져오기
  const { data: senderData, error: senderError } = await supabase
    .from("profiles")
    .select("nickname")
    .eq("id", user_id)
    .single();

  if (senderError || !senderData) {
    throw new Error("보낸 사람 정보를 찾을 수 없습니다");
  }

  // 푸시 알림 내용 설정
  const notificationPayload: FCMPayload = {
    title: senderData.nickname,
    body: comment,
    data: {
      type: "insert_comment",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      mission_id: mission_id,
      sender_id: user_id,
    },
  };

  // FCM 알림 전송
  return await sendFCMNotification(fcmToken, notificationPayload);
}
