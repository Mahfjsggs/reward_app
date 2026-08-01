import * as admin from "firebase-admin";

admin.initializeApp();

export { startAdSession, grantAdReward } from "./rewards";
export { requestWithdrawal, onWithdrawalCompleted } from "./withdrawals";
export { updateWeeklyLeaderboard } from "./leaderboard";
