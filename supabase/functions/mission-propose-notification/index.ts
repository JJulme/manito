// supabase/functions/friend-request-notification/index.ts

import { createClient } from 'npm:@supabase/supabase-js@2.49.1'
import { handleMissionPropose } from './missionProposeHandler.ts'
import { MissionProposeWebhookPayload } from '../shared/types.ts'

// supabase functions deploy mission-propose-notification --no-verify-jwt

// Supabase 클라이언트 생성
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

// Deno 서버 시작
Deno.serve(async (req) => {
  try {
    // 요청 본문을 JSON으로 파싱하여 페이로드 가져오기
    const payload: MissionProposeWebhookPayload = await req.json()

    // 친구 요청 처리 로직 호출
    const result = await handleMissionPropose(payload, supabase)
    
    // 성공적인 응답 반환
    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  }
  // 오류 반환
  catch (error) {
    console.error('Error processing webhook:', error)
    const errorMessage = (error as Error).message;
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400
    })
  }
})