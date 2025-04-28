/// FCM 관련 타입 정의
export interface FCMPayload {
  title: string;
  body: string;
  data?: Record<string, string>;

  // 안드로이드 설정
  android?: {
    notification: {
      icon: string;
      image?: string;
    };
  };
}

/// 미션 제의 알림
export interface MissionPropose {
  id: string;
  mission_id: string;
  friend_id: string;
}
export interface MissionProposeWebhookPayload {
  type: "INSERT";
  table: "mission_propose";
  record: MissionPropose;
  schema: "public";
}

// /// 미션 생성자에게 마니또의 미션 수락 알림
// export interface MissionProgress {
//   id: string
// }
// export interface MissionProgressWebhookPayload {
//   type: 'INSERT'
//   table: 'manito_posts'
//   record: MissionProgress
//   schema: 'public'
// }

/// 미션 생성자에게 마니또의 미션 완료 알림
export interface MissionDone {
  id: string;
}
export interface MissionDoneWebhookPayload {
  type: "UPDATE";
  table: "missions";
  record: MissionDone;
  schema: "public";
}

/// 미션 진행중, 완료, 추리 완료
export interface MissionsUpdate {
  id: string;
  creator_id: string;
  status: string;
  guess: string;
}
export interface MissionsUpdateWebhookPayload {
  type: "UPDATE";
  table: "missions";
  record: MissionsUpdate;
  schema: "public";
}

/// 댓글 알림
export interface Comment {
  id: string;
  mission_id: string;
  user_id: string;
  comment: string;
}
export interface CommentWebhookPayload {
  type: "INSERT";
  table: "comments";
  record: Comment;
  schema: "public";
}

/// 친구 요청 인터페이스 정의
export interface FriendRequest {
  id: string;
  sender_id: string;
  receiver_id: string;
  created_at: string;
}
export interface FriendRequestWebhookPayload {
  type: "INSERT";
  table: "friend_requests";
  record: FriendRequest;
  schema: "public";
}
