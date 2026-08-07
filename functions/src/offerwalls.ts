import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// استقبال أرباح العروض، الاستبيانات، وتنزيل التطبيقات (Postback Endpoint)
export const offerwallPostback = functions.https.onRequest(async (req, res) => {
  const { userId, points, secret } = req.query;

  // مفتاح أمان لمنع التلاعب (يمكنك تغييره لاحقاً)
  const MY_SECRET = "MY_APP_SECRET_KEY_123";

  if (secret !== MY_SECRET) {
    res.status(403).send("Unauthorized Request");
    return;
  }

  if (!userId || !points) {
    res.status(400).send("Missing parameters");
    return;
  }

  try {
    const userRef = db.collection("users").doc(userId as string);
    await userRef.update({
      points: admin.firestore.FieldValue.increment(parseInt(points as string)),
    });

    res.status(200).send("OK");
  } catch (error) {
    console.error("Error processing postback:", error);
    res.status(500).send("Error updating points");
  }
});
