import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

const db = admin.firestore();

const MIN_WITHDRAWAL_USD = 5;
const POINTS_PER_DOLLAR = 500; // 500 نقطة = 1 دولار
const WITHDRAWAL_COOLDOWN_DAYS = 15; // يقدر يسحب مرة كل 15 يوم فقط

/**
 * السحب لا يُنشأ من التطبيق مباشرة في Firestore،
 * لأننا هنا نتحقق من:
 * - الحد الأدنى للسحب
 * - أن المبلغ المطلوب لا يتجاوز الرصيد الفعلي المحوّل من النقاط
 * - أن 15 يومًا مرّت فعليًا (بوقت السيرفر) منذ آخر عملية سحب
 * ثم نخصم النقاط فورًا (حجز) لمنع طلب سحب مزدوج لنفس الرصيد.
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

    const now = admin.firestore.Timestamp.now();

    // تحقق من فترة الانتظار (15 يوم) بوقت السيرفر - غير قابل للتلاعب
    const lastWithdrawalAt = user?.lastWithdrawalAt as
      | admin.firestore.Timestamp
      | undefined;

    if (lastWithdrawalAt) {
      const daysSinceLast =
        (now.seconds - lastWithdrawalAt.seconds) / (60 * 60 * 24);

      if (daysSinceLast < WITHDRAWAL_COOLDOWN_DAYS) {
        const daysLeft = Math.ceil(WITHDRAWAL_COOLDOWN_DAYS - daysSinceLast);
        throw new HttpsError(
          "failed-precondition",
          `لا يمكنك السحب الآن، تبقى ${daysLeft} يوم قبل السحب التالي`
        );
      }
    }

    const pointsBalance = (user?.pointsBalance ?? 0) as number;
    const availableUSD = pointsBalance / POINTS_PER_DOLLAR;

    if (amount > availableUSD) {
      throw new HttpsError(
        "failed-precondition",
        "المبلغ المطلوب أكبر من رصيدك القابل للسحب"
      );
    }

    const pointsToDeduct = Math.round(amount * POINTS_PER_DOLLAR);
    const withdrawalRef = db.collection("withdrawals").doc();

    tx.set(withdrawalRef, {
      userId: uid,
      amount,
      currency: "USD",
      pointsDeducted: pointsToDeduct,
      status: "pending",
      method,
      requestedAt: now,
      processedAt: null,
      adminNote: "",
    });

    // نخصم النقاط فورًا حتى لا يقدر المستخدم يطلب نفس الرصيد مرتين
    tx.update(userRef, {
      pointsBalance: admin.firestore.FieldValue.increment(-pointsToDeduct),
      lastWithdrawalAt: now,
    });

    return withdrawalRef.id;
  });

  return { success: true, withdrawalId };
});

/**
 * عند تحديث حالة السحب إلى "مكتمل" من طرف الأدمن (يدويًا في الكونسول
 * أو عبر أداة إدارية لاحقًا)، ننشئ نسخة عامة آمنة تظهر في واجهة
 * "آخر السحوبات" للمستخدمين، دون كشف أي بيانات حساسة.
 */
export const onWithdrawalCompleted = onDocumentUpdated(
  "withdrawals/{withdrawalId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "completed") return;

    const userSnap = await db.collection("users").doc(after.userId).get();
    const userName = (userSnap.data()?.name as string) || "مستخدم";

    await db.collection("publicWithdrawals").add({
      displayName: userName,
      amount: after.amount,
      currency: after.currency,
      completedAt: admin.firestore.Timestamp.now(),
    });
  }
);
