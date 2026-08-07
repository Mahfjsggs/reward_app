import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = admin.firestore();

const WHEEL_PRIZES = [20, 50, 30, 20, 50, 30, 20, 50];

export const spinWheel = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const userRef = db.collection("users").doc(uid);

  return await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const userData = userSnap.data() || {};

    const now = admin.firestore.Timestamp.now();
    const todayStr = now.toDate().toISOString().slice(0, 10);

    if (userData.lastSpinDate === todayStr) {
      throw new HttpsError(
        "resource-exhausted",
        "لقد استخدمت عجلة الحظ اليوم بالفعل، حاول غدًا"
      );
    }

    const prizeIndex = Math.floor(Math.random() * WHEEL_PRIZES.length);
    const prizePoints = WHEEL_PRIZES[prizeIndex];

    tx.update(userRef, {
      lastSpinDate: todayStr,
      pointsBalance: admin.firestore.FieldValue.increment(prizePoints),
      totalPointsEarned: admin.firestore.FieldValue.increment(prizePoints),
      lastActiveAt: now,
    });

    const txRef = db.collection("pointTransactions").doc();
    tx.set(txRef, {
      userId: uid,
      type: "wheel_spin",
      points: prizePoints,
      createdAt: now,
    });

    return { success: true, prizeIndex, prizePoints };
  });
});
