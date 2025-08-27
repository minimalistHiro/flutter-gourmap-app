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
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTodayString = exports.formatDate = exports.verifyStaffPermission = exports.verifyQrToken = exports.generateQrToken = exports.determineBadges = exports.calculatePoints = void 0;
const admin = __importStar(require("firebase-admin"));
const jwt = __importStar(require("jsonwebtoken"));
const uuid_1 = require("uuid");
// JWTシークレットキー（Firebase Functions configから取得）
const functions = __importStar(require("firebase-functions"));
const JWT_SECRET = ((_a = functions.config().jwt) === null || _a === void 0 ? void 0 : _a.secret) || 'your-secret-key-change-in-production';
// ポイント計算ロジック
const calculatePoints = () => {
    // 基本ポイント（1スタンプ = 10ポイント）
    return 10;
};
exports.calculatePoints = calculatePoints;
// バッジ判定ロジック
const determineBadges = (goldStamps) => {
    const badges = [];
    if (goldStamps >= 1)
        badges.push('初回スタンプ');
    if (goldStamps >= 5)
        badges.push('スタンプ5個達成');
    if (goldStamps >= 10)
        badges.push('スタンプ10個達成');
    if (goldStamps >= 20)
        badges.push('スタンプ20個達成');
    if (goldStamps >= 50)
        badges.push('スタンプ50個達成');
    if (goldStamps >= 100)
        badges.push('スタンプ100個達成');
    return badges;
};
exports.determineBadges = determineBadges;
// JWTトークン生成
const generateQrToken = (userId) => {
    const payload = {
        aud: 'groumap:redeem',
        sub: userId,
        jti: (0, uuid_1.v4)(), // ワンタイム用のユニークID
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 60, // 60秒有効
    };
    return jwt.sign(payload, JWT_SECRET, { algorithm: 'HS256' });
};
exports.generateQrToken = generateQrToken;
// JWTトークン検証
const verifyQrToken = (token) => {
    try {
        const decoded = jwt.verify(token, JWT_SECRET, {
            algorithms: ['HS256'],
            audience: 'groumap:redeem'
        });
        return decoded;
    }
    catch (error) {
        console.error('JWT検証エラー:', error);
        return null;
    }
};
exports.verifyQrToken = verifyQrToken;
// スタッフ権限検証
const verifyStaffPermission = async (staffId, storeId) => {
    var _a;
    try {
        const storeDoc = await admin.firestore()
            .collection('stores')
            .doc(storeId)
            .get();
        if (!storeDoc.exists) {
            return false;
        }
        const storeData = storeDoc.data();
        return ((_a = storeData === null || storeData === void 0 ? void 0 : storeData.staffIds) === null || _a === void 0 ? void 0 : _a.includes(staffId)) || false;
    }
    catch (error) {
        console.error('スタッフ権限検証エラー:', error);
        return false;
    }
};
exports.verifyStaffPermission = verifyStaffPermission;
// 日付フォーマット（YYYY-MM-DD）
const formatDate = (date) => {
    return date.toISOString().split('T')[0];
};
exports.formatDate = formatDate;
// 今日の日付を取得
const getTodayString = () => {
    return (0, exports.formatDate)(new Date());
};
exports.getTodayString = getTodayString;
//# sourceMappingURL=utils.js.map