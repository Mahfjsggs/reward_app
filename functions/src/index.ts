import * as admin from "firebase-admin";

admin.initializeApp();

export { startAdSession, grantAdReward } from "./rewards";
export { requestWithdrawal } from "./withdrawals";
