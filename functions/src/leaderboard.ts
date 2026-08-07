import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = admin.firestore();

function getWeekId(date: Date): string {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
  const daysPassed = Math.floor(
    (date.getTime() - firstDayOfYear.getTime()) / (1000 * 60 * 60 * 24)
  );
  const weekNumber = Math.ceil((daysPassed + firstDayOfYear.getDay() + 1) / 7);
  return `${date.getFullYear()}-W${weekNumber}`;
}

function getStartOfWeek(date: Date): Date {
  const day = date.getDay();
  const start = new Date(date);
  start.setDate(date.getDate() - day);
  start.setHours(0, 0, 0, 0);
  return start;
}

export const updateWeeklyLeaderboard = onSchedule(
  { schedule: "every 60 minutes", timeZone: "Asia/Baghdad" },
  async () => {
    const now = new Date();
    const weekId = getWeekId(now);
    const startOfWeek = getStartOfWeek(now);

    const txSnap = await db
      .collection("pointTransactions")
      .where("type", "==", "ad_reward")
      .where(
        "createdAt",
        ">=",
        admin.firestore.Timestamp.fromDate(startOfWeek)
      )
      .get();

    const totals = new Map<string, { points: number; adsWatched: number }>();

    txSnap.forEach((doc) => {
      const data = doc.data();
      const uid = data.userId as string;
      const points = (data.points as number) || 0;

      const current = totals.get(uid) || { points: 0, adsWatched: 0 };
      current.points += points;
      current.adsWatched += 1;
      totals.set(uid, current);
    });

    const sorted = Array.from(totals.entries())
      .sort((a, b) => b[1].adsWatched - a[1].adsWatched)
      .slice(0, 50);

    const entries = await Promise.all(
      sorted.map(async ([uid, stats]) => {
        const userSnap = await db.collection("users").doc(uid).get();
        const name = (userSnap.data()?.name as string) || "مستخدم";
        return {
          userId: uid,
          displayName: name,
          points: stats.points,
          adsWatched: stats.adsWatched,
        };
      })
    );

    await db.collection("weeklyLeaderboards").doc(weekId).set({
      weekId,
      entries,
      updatedAt: admin.firestore.Timestamp.now(),
    });
  }
);
