import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = admin.firestore();

// ============================================================
// SETTINGS
// ============================================================

const POINTS_PER_AD = 7;

const MAX_ADS_PER_DAY = 40;

const MIN_SECONDS_BETWEEN_ADS = 20;

// مدة صلاحية جلسة الإعلان
const AD_SESSION_EXPIRY_SECONDS = 5 * 60;


// ============================================================
// START AD SESSION
// ============================================================

export const startAdSession = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول"
    );
  }

  const data = request.data ?? {};

  const adNetwork =
    typeof data.adNetwork === "string"
      ? data.adNetwork
      : "admob";

  const adType =
    typeof data.adType === "string"
      ? data.adType
      : "rewarded";

  // ----------------------------------------------------------
  // الوقت الحالي
  // ----------------------------------------------------------

  const now = admin.firestore.Timestamp.now();

  // ----------------------------------------------------------
  // بداية اليوم
  // ----------------------------------------------------------

  const startOfDayDate = new Date();

  startOfDayDate.setHours(0, 0, 0, 0);

  const startOfDay =
    admin.firestore.Timestamp.fromDate(startOfDayDate);

  // ----------------------------------------------------------
  // جلب جلسات اليوم
  // ----------------------------------------------------------

  const todayEventsSnap = await db
    .collection("adEvents")
    .where("userId", "==", uid)
    .where("createdAt", ">=", startOfDay)
    .get();

  // ----------------------------------------------------------
  // الحد اليومي
  // ----------------------------------------------------------

  if (todayEventsSnap.size >= MAX_ADS_PER_DAY) {
    throw new HttpsError(
      "resource-exhausted",
      "لقد وصلت للحد الأقصى من الإعلانات المسموحة اليوم"
    );
  }

  // ----------------------------------------------------------
  // منع إنشاء جلسات متتالية بسرعة
  // ----------------------------------------------------------

  let latestCreatedAt: admin.firestore.Timestamp | null = null;

  for (const doc of todayEventsSnap.docs) {
    const data = doc.data();

    const createdAt =
      data.createdAt as admin.firestore.Timestamp | undefined;

    if (!createdAt) {
      continue;
    }

    if (
      latestCreatedAt === null ||
      createdAt.toMillis() > latestCreatedAt.toMillis()
    ) {
      latestCreatedAt = createdAt;
    }
  }

  if (latestCreatedAt) {
    const secondsSinceLast =
      now.seconds - latestCreatedAt.seconds;

    if (secondsSinceLast < MIN_SECONDS_BETWEEN_ADS) {
      throw new HttpsError(
        "resource-exhausted",
        "الرجاء الانتظار قليلاً قبل مشاهدة إعلان آخر"
      );
    }
  }

  // ----------------------------------------------------------
  // إنشاء Event ID
  // ----------------------------------------------------------

  const eventRef =
    db.collection("adEvents").doc();

  // ----------------------------------------------------------
  // إنشاء جلسة الإعلان
  // ----------------------------------------------------------

  await eventRef.set({
    userId: uid,

    adNetwork,
    adType,

    status: "started",

    rewardPoints: 0,

    startedAt: now,
    completedAt: null,

    createdAt: now,

    // وقت انتهاء الجلسة
    expiresAt: admin.firestore.Timestamp.fromMillis(
      now.toMillis() +
        AD_SESSION_EXPIRY_SECONDS * 1000
    ),

    // معلومات إضافية للحماية
    ssvVerified: false,
    transactionId: null,
  });

  // ----------------------------------------------------------
  // يرجع Event ID للتطبيق
  // ----------------------------------------------------------

  return {
    success: true,
    eventId: eventRef.id,
    points: POINTS_PER_AD,
  };
});


// ============================================================
// GRANT AD REWARD
// ============================================================
//
// ملاحظة مهمة:
//
// هذه الوظيفة ليست إثباتًا نهائيًا لمشاهدة الإعلان.
//
// سيتم استخدام AdMob SSV لاحقًا للتأكد من أن Google نفسها
// أرسلت callback صحيح قبل اعتماد المكافأة.
//
// لذلك لا نعطي النقاط من هذه الوظيفة مباشرة.
//
// ============================================================

export const grantAdReward = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول"
    );
  }

  const data = request.data ?? {};

  const eventId =
    typeof data.eventId === "string"
      ? data.eventId.trim()
      : "";

  if (!eventId) {
    throw new HttpsError(
      "invalid-argument",
      "eventId مفقود"
    );
  }

  const eventRef =
    db.collection("adEvents").doc(eventId);

  const eventSnap =
    await eventRef.get();

  if (!eventSnap.exists) {
    throw new HttpsError(
      "not-found",
      "جلسة الإعلان غير موجودة"
    );
  }

  const event =
    eventSnap.data()!;

  // ----------------------------------------------------------
  // التأكد من صاحب الجلسة
  // ----------------------------------------------------------

  if (event.userId !== uid) {
    throw new HttpsError(
      "permission-denied",
      "هذه الجلسة لا تخصك"
    );
  }

  // ----------------------------------------------------------
  // إذا كانت الجلسة منتهية
  // ----------------------------------------------------------

  const now =
    admin.firestore.Timestamp.now();

  const expiresAt =
    event.expiresAt as
      | admin.firestore.Timestamp
      | undefined;

  if (
    expiresAt &&
    now.toMillis() > expiresAt.toMillis()
  ) {
    await eventRef.update({
      status: "expired",
      completedAt: now,
    });

    throw new HttpsError(
      "deadline-exceeded",
      "انتهت صلاحية جلسة الإعلان"
    );
  }

  // ----------------------------------------------------------
  // منع تكرار معالجة الجلسة
  // ----------------------------------------------------------

  if (event.status !== "started") {
    throw new HttpsError(
      "failed-precondition",
      "تم التعامل مع هذه الجلسة مسبقًا"
    );
  }

  // ----------------------------------------------------------
  // لا نعطي النقاط هنا
  // ----------------------------------------------------------
  //
  // السبب:
  //
  // استدعاء هذه الوظيفة من التطبيق وحده لا يثبت أن
  // AdMob أعطى المستخدم المكافأة.
  //
  // المكافأة النهائية ستكون من خلال SSV.
  //

  await eventRef.update({
    clientRewardCallbackReceived: true,
    clientRewardCallbackAt: now,
  });

  return {
    success: true,
    pending: true,
    points: 0,
    message:
      "تم تسجيل مشاهدة الإعلان، بانتظار التحقق من الخادم",
  };
});
