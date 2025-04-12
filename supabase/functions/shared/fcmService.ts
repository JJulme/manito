// supabase/functions/friend-request-notification/fcmService.ts

import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }
import { FCMPayload } from './types.ts'

// FCM 알림 전송 함수
export async function sendFCMNotification(
  token: string, 
  notification: FCMPayload
) {
  // Google 인증을 통해 액세스 토큰 가져오기
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // FCM을 통해 푸시 알림 전송
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: token,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: notification.data,
        },
      }),
    }
  )

  // 응답 데이터 파싱
  const resData = await res.json()
  if (res.status < 200 || 299 < res.status) {
    throw resData
  }

  return resData
}

// 액세스 토큰을 가져오는 함수
const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    // JWT 클라이언트 생성
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    // JWT 클라이언트 인증
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}