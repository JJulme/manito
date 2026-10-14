import { JWT } from "npm:google-auth-library@9";

// 🔒 Firebase Service Account 정보를 Supabase Secrets 환경변수에서 읽습니다.
// Supabase Dashboard → Edge Functions → Secrets 에서 FIREBASE_SERVICE_ACCOUNT_JSON 등록 필요.
// 값은 service-account.json 파일의 전체 JSON 문자열입니다.
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
if (!serviceAccountJson) {
  throw new Error(
    "FIREBASE_SERVICE_ACCOUNT_JSON 환경변수가 설정되지 않았습니다. " +
    "Supabase Dashboard → Edge Functions → Secrets 에서 등록해 주세요."
  );
}
const serviceAccount = JSON.parse(serviceAccountJson);

async function getAccessToken(): Promise<string> {
  const jwtClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const tokens = await jwtClient.authorize();
  return tokens.access_token!;
}

async function sendFCM(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  imageUrl?: string,
) {
  const accessToken = await getAccessToken();

  const apnsPayload: Record<string, any> = {
    aps: {
      alert: {
        title: title,
        body: body,
      },
      sound: "default",
      badge: 1,
      "content-available": 1,
      "mutable-content": 1,
    },
  };
  if (imageUrl) {
    apnsPayload.fcm_options = {
      image: imageUrl,
    };
  }

  const messagePayload: Record<string, any> = {
    token: token,
    data: data,
    android: {
      priority: "HIGH",
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-push-type": "alert",
      },
      payload: apnsPayload,
    },
  };

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({ message: messagePayload }),
    },
  );

  const resData = await res.json();
  if (res.status < 200 || res.status > 299) {
    throw resData;
  }
  return resData;
}

Deno.serve(async (req) => {
  try {
    const { tokens, title, body, data, imageUrl } = await req.json();

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: false, message: "No tokens provided" }),
        { headers: { "Content-Type": "application/json" }, status: 400 },
      );
    }

    const notifTitle = title || "마니또 알림";
    const notifBody = body || "";
    const finalImageUrl = imageUrl || data?.sender_profile_url || data?.image_url;

    const stringData: Record<string, string> = {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      title: notifTitle,
      body: notifBody,
    };
    if (finalImageUrl) {
      stringData.image_url = finalImageUrl;
    }

    if (data && typeof data === "object") {
      for (const [key, value] of Object.entries(data)) {
        if (value !== null && value !== undefined) {
          stringData[key] = typeof value === "string" ? value : JSON.stringify(value);
        }
      }
    }

    const results = await Promise.allSettled(
      tokens.map((token: string) =>
        sendFCM(token, notifTitle, notifBody, stringData, finalImageUrl)
      ),
    );

    const successfulCount = results.filter((r) => r.status === "fulfilled").length;
    const failedCount = results.length - successfulCount;

    return new Response(
      JSON.stringify({
        success: true,
        sent: successfulCount,
        failed: failedCount,
        details: results,
      }),
      { headers: { "Content-Type": "application/json" }, status: 200 },
    );
  } catch (error) {
    console.error("Error sending push notification:", error);
    const errorMessage = (error as Error).message || String(error);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { headers: { "Content-Type": "application/json" }, status: 500 },
    );
  }
});
