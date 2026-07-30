import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = admin.firestore();

const MIN_WITHDRAWAL_USD = 5;

/**
 * السحب لا يُنشأ من التطبيق مباشرة في Firestore،
 * لأننا هنا نتحقق من:
 * - الحد الأدنى للسحب
 * - أن المبلغ المطلوب لا يتجاوز withdrawableBalance الفعلي في السيرفر
 * ثم نخصم المبلغ فورًا (حجز) لمنع طلب سحب مزدوج لنفس الرصيد.
 */
export const requestWithdrawal = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const { amount, method = "manual" } = request.data || {};

  if (typeof amount !== "number" || amount < MIN_WITHDRAWAL_USD) {
    throw new HttpsError(
      "invalid-argument",
      `الحد الأدنى للسحب هو $${MIN_WITHDRAWAL_USD}`
    );
  }

  const userRef = db.collection("users").doc(uid);

  const withdrawalId = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const user = userSnap.data();

    const balance = (user?.withdrawableBalance ?? 0) as number;

    if (amount > balance) {
      throw new HttpsError(
        "failed-precondition",
        "المبلغ المطلوب أكبر من رصيدك القابل للسحب"
      );
    }

    const now = admin.firestore.Timestamp.now();
    const withdrawalRef = db.collection("withdrawals").doc();

    tx.set(withdrawalRef, {
      userId: uid,
      amount,
      currency: "USD",
      status: "pending",
      method,
      requestedAt: now,
      processedAt: null,
      adminNote: "",
    });

    // نخصم فورًا حتى لا يقدر المستخدم يطلب نفس الرصيد مرتين
    tx.update(userRef, {
      withdrawableBalance: admin.firestore.FieldValue.increment(-amount),
    });

    return withdrawalRef.id;
  });

  return { success: true, withdrawalId };
});
