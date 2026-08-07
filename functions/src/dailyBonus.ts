import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// مكافأة الدخول اليومية
export const claimDailyBonus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  }

  const userId = context.auth.uid;
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    throw new functions.https.HttpsError("not-found", "المستخدم غير موجود.");
  }

  const userData = userDoc.data();
  const today = new Date().toISOString().split("T")[0];
  const lastCheckin = userData?.lastCheckin || "";

  if (lastCheckin === today) {
    throw new functions.https.HttpsError("already-exists", "لقد استلمت مكافأة اليوم بالفعل!");
  }

  const rewardPoints = 50;

  await userRef.update({
    points: admin.firestore.FieldValue.increment(rewardPoints),
    lastCheckin: today,
  });

  return {
    success: true,
    message: `تمت إضافة ${rewardPoints} نقطة إلى حسابك!`,
  };
});

// نظام الإحالة للأصدقاء
export const applyReferralCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً.");
  }

  const { referralCode } = data;
  const userId = context.auth.uid;

  if (!referralCode) {
    throw new functions.https.HttpsError("invalid-argument", "يرجى إدخال رمز الإحالة.");
  }

  const userRef = db.collection("users").doc(userId);
  const currentUserDoc = await userRef.get();

  if (currentUserDoc.data()?.usedReferral) {
    throw new functions.https.HttpsError("already-exists", "لقد استخدمت رمز إحالة من قبل.");
  }

  const referrerQuery = await db.collection("users").where("myReferralCode", "==", referralCode).limit(1).get();

  if (referrerQuery.empty) {
    throw new functions.https.HttpsError("not-found", "رمز الإحالة غير صحيح.");
  }

  const referrerDoc = referrerQuery.docs[0];
  if (referrerDoc.id === userId) {
    throw new functions.https.HttpsError("invalid-argument", "لا يمكنك استخدام رمز الإحالة الخاص بك.");
  }

  const bonusForUser = 100;
  const bonusForReferrer = 200;

  await userRef.update({
    points: admin.firestore.FieldValue.increment(bonusForUser),
    usedReferral: true,
  });

  await db.collection("users").doc(referrerDoc.id).update({
    points: admin.firestore.FieldValue.increment(bonusForReferrer),
    referralCount: admin.firestore.FieldValue.increment(1),
  });

  return {
    success: true,
    message: "تم تطبيق رمز الإحالة وإضافة النقاط!",
  };
});
