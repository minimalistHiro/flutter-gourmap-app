"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.redeemPoints = exports.issueUserQr = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("./utils");
// Firebase Admin初期化
admin.initializeApp();
// Firestoreインスタンス
const db = admin.firestore();
/**
 * ユーザーQRコードトークンを発行する関数
 * HS256の短命JWT（60秒、有効範囲aud=groumap:redeem、sub=userId、jti）を返す
 */
exports.issueUserQr = functions.https.onCall(async (data, context) => {
    try {
        // 認証チェック
        if (!context.auth) {
            return {
                success: false,
                error: '認証が必要です'
            };
        }
        const userId = context.auth.uid;
        // QRトークンを生成
        const qrToken = (0, utils_1.generateQrToken)(userId);
        const expiresAt = Date.now() + (60 * 1000); // 60秒後
        console.log(`QRトークン発行: userId=${userId}, expiresAt=${new Date(expiresAt)}`);
        return {
            success: true,
            qrToken,
            expiresAt
        };
    }
    catch (error) {
        console.error('QRトークン発行エラー:', error);
        return {
            success: false,
            error: 'QRトークンの発行に失敗しました'
        };
    }
});
/**
 * ポイント交換処理を行う関数
 * スタッフ権限を検証、JWT検証＋jtiのワンタイム消費、1日1スタンプ、ポイント計算、バッジ判定までをトランザクションで実装
 */
exports.redeemPoints = functions.https.onCall(async (data, context) => {
    try {
        // 認証チェック
        if (!context.auth) {
            return {
                success: false,
                error: '認証が必要です'
            };
        }
        const staffId = context.auth.uid;
        const { qrToken, storeId } = data;
        // スタッフ権限を検証
        const hasPermission = await (0, utils_1.verifyStaffPermission)(staffId, storeId);
        if (!hasPermission) {
            return {
                success: false,
                error: 'この店舗でのスタンプ発行権限がありません'
            };
        }
        // JWTトークンを検証
        const payload = (0, utils_1.verifyQrToken)(qrToken);
        if (!payload) {
            return {
                success: false,
                error: '無効なQRトークンです'
            };
        }
        const userId = payload.sub;
        const jti = payload.jti;
        // トランザクションでポイント交換処理を実行
        const result = await db.runTransaction(async (transaction) => {
            // ユーザーデータを取得
            const userRef = db.collection('users').doc(userId);
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new Error('ユーザーが見つかりません');
            }
            const userData = userDoc.data();
            const currentPoints = userData.points || 0;
            const currentGoldStamps = userData.goldStamps || 0;
            const lastStampDate = userData.lastStampDate;
            const today = (0, utils_1.getTodayString)();
            // 1日1スタンプ制限チェック
            if (lastStampDate === today) {
                throw new Error('今日は既にスタンプを獲得済みです');
            }
            // JTIの重複使用チェック
            const stampHistoryRef = db.collection('stamp_history');
            const existingStamp = await transaction.get(stampHistoryRef.where('jti', '==', jti).limit(1));
            if (!existingStamp.empty) {
                throw new Error('このQRコードは既に使用済みです');
            }
            // ポイント計算
            const pointsEarned = (0, utils_1.calculatePoints)();
            const newTotalPoints = currentPoints + pointsEarned;
            const newGoldStamps = currentGoldStamps + 1;
            // バッジ判定
            const newBadges = (0, utils_1.determineBadges)(newGoldStamps);
            const existingBadges = userData.badges || [];
            const earnedBadges = newBadges.filter(badge => !existingBadges.includes(badge));
            // ユーザーデータを更新
            transaction.update(userRef, {
                points: newTotalPoints,
                goldStamps: newGoldStamps,
                lastStampDate: today,
                badges: newBadges,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // 新しいuser_stamps構造にスタンプデータを保存
            const userStampRef = db.collection('user_stamps').doc(userId).collection('stores').doc(storeId);
            const userStampDoc = await transaction.get(userStampRef);
            if (userStampDoc.exists) {
                // 既存のスタンプデータを更新
                const existingData = userStampDoc.data();
                const currentStamps = existingData.stamps || 0;
                const newStamps = currentStamps + 1;
                transaction.update(userStampRef, {
                    stamps: newStamps,
                    lastStampDate: today,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            else {
                // 新しいスタンプデータを作成
                transaction.set(userStampRef, {
                    storeId,
                    userId,
                    stamps: 1,
                    firstStampDate: today,
                    lastStampDate: today,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            // スタンプ履歴を記録
            const stampHistoryRef2 = db.collection('stamp_history').doc();
            transaction.set(stampHistoryRef2, {
                id: stampHistoryRef2.id,
                userId,
                storeId,
                staffId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                pointsEarned,
                jti
            });
            return {
                pointsEarned,
                newTotalPoints,
                newGoldStamps,
                earnedBadges
            };
        });
        console.log(`ポイント交換完了: userId=${userId}, pointsEarned=${result.pointsEarned}, newTotalPoints=${result.newTotalPoints}`);
        return {
            success: true,
            pointsEarned: result.pointsEarned,
            newTotalPoints: result.newTotalPoints,
            goldStamps: result.newGoldStamps,
            badges: result.earnedBadges
        };
    }
    catch (error) {
        console.error('ポイント交換エラー:', error);
        let errorMessage = 'ポイント交換に失敗しました';
        if (error instanceof Error) {
            errorMessage = error.message;
        }
        return {
            success: false,
            error: errorMessage
        };
    }
});
//# sourceMappingURL=index.js.map