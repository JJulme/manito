// supabase/functions/friend-request-notification/friendRequestHandler.ts

import { SupabaseClient } from 'npm:@supabase/supabase-js@2.49.1'
import { sendFCMNotification } from '../shared/fcmService.ts'
import { FCMPayload, MissionsUpdateWebhookPayload } from '../shared/types.ts'

/// 수신자 FCM토큰 가져옴
async function getFCMToken(supabase: SupabaseClient, userId: string) {
  const { data: receiverData, error: receiverError } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', userId)
    .single();

  if (receiverError || !receiverData) {
    throw new Error(`수신자 FCM 토큰을 찾을 수 없습니다: ${userId}`);
  }

  return receiverData.fcm_token as string;
}

export async function handleMissionsUpdate(
  payload: MissionsUpdateWebhookPayload,
  supabase: SupabaseClient
) {
  const { id, creator_id, status, guess } = payload.record;

  let notificationPayload: FCMPayload;
  let fcmToken: string;

  try {
    if (guess !== null) {
      const { data: postData, error: postError } = await supabase
        .from('manito_posts')
        .select('manito_id')
        .eq('id', id)
        .single();

      if (postError || !postData) {
        throw new Error('미션 포스트 데이터를 찾을 수 없습니다');
      }

      fcmToken = await getFCMToken(supabase, postData.manito_id);

      notificationPayload = {
        title: '미션 종료!',
        body: `친구가 추리한 내용을 확인해보세요.`,
        data: {
          type: 'update_mission_guess',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          mission_id : id,
        }
      };
    } else if (status === '진행중') {
      fcmToken = await getFCMToken(supabase, creator_id);

      notificationPayload = {
        title: '마니또 미션 수락!',
        body: `마니또를 추측 해보세요.`,
        data: {
          type: 'update_mission_progress',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          mission_id : id,
        }
      };
    } else {
      fcmToken = await getFCMToken(supabase, creator_id);

      notificationPayload = {
        title: '마니또 미션 종료!',
        body: `마니또가 누구인지 추측해보고 확인하세요.`,
        data: {
          type: 'update_mission_done',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          mission_id : id,
        }
      };
    }

    // FCM 알림 전송
    await sendFCMNotification(fcmToken, notificationPayload);
    return new Response('FCM 알림 전송 완료', { status: 200 });

  } catch (error) {
    console.error(error);
    return new Response('알림 전송 실패', { status: 500 });
  }
}