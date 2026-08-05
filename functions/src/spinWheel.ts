import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = admin.firestore();

// جوائز عجلة الحظ بالدولار مباشرة - بونص إضافي فوق أرباح الإعلانات العادية
const WHEEL_PRIZES = [0.05, 0.10, 0.07, 0.05, 0.10, 0.07, 0.05, 0.10];

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
    const prizeAmount = WHEEL_PRIZES[prizeIndex];

    tx.update(userRef, {
      lastSpinDate: todayStr,
      earningsBalance: admin.firestore.FieldValue.increment(prizeAmount),
      totalEarned: admin.firestore.FieldValue.increment(prizeAmount),
      lastActiveAt: now,
    });

    const txRef = db.collection("earningsTransactions").doc();
    tx.set(txRef, {
      userId: uid,
      type: "wheel_spin",
      amount: prizeAmount,
      createdAt: now,
    });

    return { success: true, prizeIndex, prizeAmount };
  });
});
