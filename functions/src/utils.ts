import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { QrTokenPayload } from './types';

// JWTシークレットキー（Firebase Functions configから取得）
import * as functions from 'firebase-functions';
const JWT_SECRET = functions.config().jwt?.secret || 'your-secret-key-change-in-production';

// ポイント計算ロジック
export const calculatePoints = (): number => {
  // 基本ポイント（1スタンプ = 10ポイント）
  return 10;
};

// バッジ判定ロジック
export const determineBadges = (goldStamps: number): string[] => {
  const badges: string[] = [];
  
  if (goldStamps >= 1) badges.push('初回スタンプ');
  if (goldStamps >= 5) badges.push('スタンプ5個達成');
  if (goldStamps >= 10) badges.push('スタンプ10個達成');
  if (goldStamps >= 20) badges.push('スタンプ20個達成');
  if (goldStamps >= 50) badges.push('スタンプ50個達成');
  if (goldStamps >= 100) badges.push('スタンプ100個達成');
  
  return badges;
};

// JWTトークン生成
export const generateQrToken = (userId: string): string => {
  const payload: QrTokenPayload = {
    aud: 'groumap:redeem',
    sub: userId,
    jti: uuidv4(), // ワンタイム用のユニークID
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 60, // 60秒有効
  };
  
  return jwt.sign(payload, JWT_SECRET, { algorithm: 'HS256' });
};

// JWTトークン検証
export const verifyQrToken = (token: string): QrTokenPayload | null => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET, { 
      algorithms: ['HS256'],
      audience: 'groumap:redeem'
    }) as QrTokenPayload;
    
    return decoded;
  } catch (error) {
    console.error('JWT検証エラー:', error);
    return null;
  }
};

// スタッフ権限検証
export const verifyStaffPermission = async (
  staffId: string, 
  storeId: string
): Promise<boolean> => {
  try {
    const storeDoc = await admin.firestore()
      .collection('stores')
      .doc(storeId)
      .get();
    
    if (!storeDoc.exists) {
      return false;
    }
    
    const storeData = storeDoc.data();
    return storeData?.staffIds?.includes(staffId) || false;
  } catch (error) {
    console.error('スタッフ権限検証エラー:', error);
    return false;
  }
};

// 日付フォーマット（YYYY-MM-DD）
export const formatDate = (date: Date): string => {
  return date.toISOString().split('T')[0];
};

// 今日の日付を取得
export const getTodayString = (): string => {
  return formatDate(new Date());
}; 