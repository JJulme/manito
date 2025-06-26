/// FCM 관련 타입 정의
export interface FCMPayload {
  title?: string;
  body?: string;
  // 다국어 지원을 위한 공식 필드들
  notification?: {
    title_loc_key?: string; // 제목의 다국어 키
    title_loc_args?: string[]; // 제목 플레이스홀더 값들
    body_loc_key?: string; // 내용의 다국어 키
    body_loc_args?: string[]; // 내용 플레이스홀더 값들
  };

  data?: Record<string, string>;

  // 안드로이드 설정
  android?: {
    notification: {
      title_loc_key?: string;
      body_loc_key?: string;
      body_loc_args?: string[];
      icon: string;
      image?: string;
    };
  };

  // iOS 설정
  apns?: {
    payload: {
      aps: {
        // "content-available"?: string;
        "mutable-content"?: string;

        alert: {
          "title-loc-key"?: string;
          "loc-key"?: string;
          "loc-args"?: string[];
        };
      };
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

/// 미션 진행중, 완료, 추리 완료
export interface MissionsUpdate {
  id: string;
  creator_id: string;
  manito_id: string;
  status: string;
  description: string;
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

/// 채팅 알림
export interface Chat {
  id: string;
  post_id: string;
  sender_id: string;
  content: string;
}
export interface ChatWebhookPayload {
  type: "INSERT";
  table: "chat_messages";
  record: Chat;
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
