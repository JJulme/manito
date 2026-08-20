import { JWT } from "npm:google-auth-library@9";

const serviceAccount = {
  type: "service_account",
  project_id: "manito-e305a",
  private_key_id: "9a8276bfabe8f464083e25c95d76d0b802a643b9",
  private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCYw0inoQRWmsMo\nzEcBa5k2y0HuEsQsZU4tOQ3o9Ak/zo77d7V32rkWvPuQJ9J+/6gUnoinSrps8vJa\n32WkA2v4vN4xs5xLOAcEAkYo8u9sQ3CXBcwGxJ+7yYjl7uQdTZ0fgQMLAKMTue17\noklhHRwTvNIOXJKjElata1OXsklMR6VeFq3H7HM8bLJ8gLM8ZlLUYHHLC+cbKJPi\nFBL5EF9GckicVkkooQpABl9/3TXPb0uuzbrvj4vMiDu8Nmpff2+tJwVyJoXx12wf\nv6NMf/hTR1Jd2z5CbbMHmCRUG7Jc50LIobkiXxzrAs64rRGlAgv0wvGzgkcyomkl\nPSShnCSlAgMBAAECggEADzLq0SbPkDBQt4fvjqAee9moQyAh3YrsxsoU7LcPDoam\nKjXkW7rqzGzcGKElq9YS6o5FaWOhfcKEQ29TpQhkHzjnYImOxNsbs5XoVh2pnZtu\nIdCFVq0MeXoZQUtN7e5xchd7boZPM2C91J22cE+dogcY3S3vtwLVleaGSCMIcOrO\njw16YzugGctf7XZkn9VpPaw+xBcKzI+Bh/MFTNIDvI3PuOGNata3AlEmgoPRYUcd\nWlaBJEzq1v5lD34DuV//z7eY/wWvLq5nzBSTQA7405HHt2+HNTJyiUgQMXtqQ9EZ\nUoHPq6xL6FWGcS7UHQSO3TdMAqZWMtgLCPrmN/BHAQKBgQDPhuibbLMzwaoI1D4F\naiSD5Poy0bpclHzVBoe/IGZDxcFO5bKS3yUvMlZJ2c3ZStbDAITQwv7EtrwUbEkm\nLc09J66aMswTLK6sZDP6MsCORhYZw3NGn8KVj7iDgndTRPh5EZoe2pDlLX04K5nZ\nGm47p65SnkNbPKnXWiVQDaf3JQKBgQC8cb+ODw6jDE0WaoKhpD31Ngy72W05bcmF\ncMG7ZyYwXfuedrtV2ODwRc4MHxaR46V8HoR0XC/CPWwKf81q2chLOkASQhgwDT0R\nOAvpntVEdSuYeDNLGFOxGXeRhmoFLVrZCsmQSgtxGF+61un8QyzHQqaGd/QTtI2R\np66zqgS/gQKBgH3uVs6iCqiYl67d5HjyrQ/gbjdSb21oqcu3N76yUXxEz4Yp+tAH\nWxAl0pjj83ctY99XPEFWYrVKUh1ujID/gDDhGKH3u0DTd3ejIqtsCs8LFrQxl40+\nuxx45zXegLxl+QW2ubiJVy3LCdaBFs3YrRXELhNyeFswF7xXtpa6greFAoGAVw1p\nAzQbe+Db36YWcJuR76wnV8QKfAQmmxlKtcrhzmgsK7kHs5G73+MvW1QlNgHm2Z6z\na5mGioGbXoJJn7m5mF7xaD3WNKR4+HJetm6kcLp8CDRG5cL4LpDoNnbUlU2tcSRV\nlu1NudIbrxFHCDzz+5zjlqzlOREocQf4YZECHoECgYEAq8X4MRpnPwWJ61+neuHN\nrOKn5N/hpwVxR0LmfpknicYqBJ81A6ZpiAikpFbBr3s3p4B6oXE8UhbBXcS+4Vq2\nZOi2gtqarWcq9VySJtFwjx3kGcibWSF373zdI3WYtue57Favi485xv9+cqgkPmio\nzXHpCrVDG28FIMn4H0TD6UQ=\n-----END PRIVATE KEY-----\n",
  client_email: "firebase-adminsdk-w9gtb@manito-e305a.iam.gserviceaccount.com",
};

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
) {
  const accessToken = await getAccessToken();
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: data,
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "default_notification_channel",
              sound: "default",
              default_sound: true,
              default_vibrate_timings: true,
              notification_priority: "PRIORITY_MAX",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              icon: "ic_notification",
            },
          },
          apns: {
            headers: {
              "apns-priority": "10",
              "apns-push-type": "alert",
            },
            payload: {
              aps: {
                alert: {
                  title: title,
                  body: body,
                },
                sound: "default",
                badge: 1,
                "content-available": 1,
              },
            },
          },
        },
      }),
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
    const { tokens, title, body, data } = await req.json();

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: false, message: "No tokens provided" }),
        { headers: { "Content-Type": "application/json" }, status: 400 },
      );
    }

    const notifTitle = title || "마니또 알림";
    const notifBody = body || "";

    const stringData: Record<string, string> = {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      title: notifTitle,
      body: notifBody,
    };
    if (data && typeof data === "object") {
      for (const [key, value] of Object.entries(data)) {
        if (value !== null && value !== undefined) {
          stringData[key] = typeof value === "string" ? value : JSON.stringify(value);
        }
      }
    }

    const results = await Promise.allSettled(
      tokens.map((token: string) =>
        sendFCM(token, notifTitle, notifBody, stringData)
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
