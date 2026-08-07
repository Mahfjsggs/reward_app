import * as admin from "firebase-admin";

admin.initializeApp();

// الوظائف الموجودة سابقاً
export { startAdSession, grantAdReward } from "./rewards";
export { requestWithdrawal, onWithdrawalCompleted } from "./withdrawals";
export { updateWeeklyLeaderboard } from "./leaderboard";
export { spinWheel } from "./spinWheel";

// الوظائف الجديدة (المكافأة اليومية والإحالة والعروض)
export { claimDailyBonus, applyReferralCode } from "./dailyBonus";
export { offerwallPostback } from "./offerwalls";
