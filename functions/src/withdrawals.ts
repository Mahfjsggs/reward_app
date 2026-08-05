import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

const db = admin.firestore();

const MIN_WITHDRAWAL_USD = 5;
const WITHDRAWAL_COOLDOWN_DAYS = 15;

export const requestWithdrawal = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const { method = "manual" } = request.data || {};
  const userRef = db.collection("users").doc(uid);

  const result = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const user = userSnap.data();

    const now = admin.firestore.Timestamp.now();

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

    const earningsBalance = (user?.earningsBalance ?? 0) as number;

    if (earningsBalance < MIN_WITHDRAWAL_USD) {
      throw new HttpsError(
        "failed-precondition",
        `رصيدك الحالي أقل من الحد الأدنى للسحب ($${MIN_WITHDRAWAL_USD})`
      );
    }

    const withdrawalRef = db.collection("withdrawals").doc();

    tx.set(withdrawalRef, {
      userId: uid,
      amount: earningsBalance,
      currency: "USD",
      status: "pending",
      method,
      requestedAt: now,
      processedAt: null,
      adminNote: "",
    });

    tx.update(userRef, {
      earningsBalance: 0,
      lastWithdrawalAt: now,
    });

    return { withdrawalId: withdrawalRef.id, amount: earningsBalance };
  });

  return { success: true, ...result };
});

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
