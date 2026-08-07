import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = admin.firestore();

const POINTS_PER_AD = 7;
const MIN_WATCH_SECONDS = 15;
const MAX_ADS_PER_DAY = 40;
const MIN_SECONDS_BETWEEN_ADS = 20;

export const startAdSession = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const { adNetwork = "admob", adType = "rewarded" } = request.data || {};

  const now = admin.firestore.Timestamp.now();
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const todayEventsSnap = await db
    .collection("adEvents")
    .where("userId", "==", uid)
    .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
    .get();

  if (todayEventsSnap.size >= MAX_ADS_PER_DAY) {
    throw new HttpsError(
      "resource-exhausted",
      "لقد وصلت للحد الأقصى من الإعلانات المسموحة اليوم"
    );
  }

  const lastEvent = todayEventsSnap.docs
    .map((d) => d.data())
    .sort((a, b) => (b.createdAt?.toMillis() ?? 0) - (a.createdAt?.toMillis() ?? 0))[0];

  if (lastEvent?.createdAt) {
    const secondsSinceLast = now.seconds - lastEvent.createdAt.seconds;
    if (secondsSinceLast < MIN_SECONDS_BETWEEN_ADS) {
      throw new HttpsError(
        "resource-exhausted",
        "الرجاء الانتظار قليلاً قبل مشاهدة إعلان آخر"
      );
    }
  }

  const eventRef = db.collection("adEvents").doc();

  await eventRef.set({
    userId: uid,
    adNetwork,
    adType,
    status: "started",
    rewardPoints: 0,
    startedAt: now,
    completedAt: null,
    createdAt: now,
  });

  return { eventId: eventRef.id };
});

export const grantAdReward = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const { eventId } = request.data || {};
  if (!eventId) {
    throw new HttpsError("invalid-argument", "eventId مفقود");
  }

  const eventRef = db.collection("adEvents").doc(eventId);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const eventSnap = await tx.get(eventRef);

    if (!eventSnap.exists) {
      throw new HttpsError("not-found", "جلسة الإعلان غير موجودة");
    }

    const event = eventSnap.data()!;

    if (event.userId !== uid) {
      throw new HttpsError("permission-denied", "هذه الجلسة لا تخصك");
    }

    if (event.status !== "started") {
      throw new HttpsError(
        "failed-precondition",
        "تم التعامل مع هذه الجلسة مسبقًا"
      );
    }

    const now = admin.firestore.Timestamp.now();
    const startedAt = event.startedAt as admin.firestore.Timestamp;
    const elapsedSeconds = now.seconds - startedAt.seconds;

    if (elapsedSeconds < MIN_WATCH_SECONDS) {
      tx.update(eventRef, { status: "rejected", completedAt: now });
      throw new HttpsError(
        "failed-precondition",
        "لم تمر مدة كافية لاعتبار المشاهدة صالحة"
      );
    }

    tx.update(eventRef, {
      status: "verified",
      rewardPoints: POINTS_PER_AD,
      completedAt: now,
    });

    const txRef = db.collection("pointTransactions").doc();
    tx.set(txRef, {
      userId: uid,
      type: "ad_reward",
      points: POINTS_PER_AD,
      referenceId: eventId,
      createdAt: now,
    });

    tx.update(userRef, {
      pointsBalance: admin.firestore.FieldValue.increment(POINTS_PER_AD),
      totalPointsEarned: admin.firestore.FieldValue.increment(POINTS_PER_AD),
      lastActiveAt: now,
    });
  });

  return { success: true, points: POINTS_PER_AD };
});
