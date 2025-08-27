// レスポンスの型定義
export interface IssueUserQrResponse {
  success: boolean;
  qrToken?: string;
  error?: string;
  expiresAt?: number;
}

export interface RedeemPointsResponse {
  success: boolean;
  pointsEarned?: number;
  newTotalPoints?: number;
  goldStamps?: number;
  badges?: string[];
  error?: string;
}

// JWTペイロードの型定義
export interface QrTokenPayload {
  aud: string; // 'groumap:redeem'
  sub: string; // userId
  jti: string; // JWT ID (ワンタイム用)
  iat: number; // 発行時刻
  exp: number; // 有効期限
}

// ポイント交換リクエストの型定義
export interface RedeemPointsRequest {
  qrToken: string;
  storeId: string;
  staffId: string;
}

// ユーザーデータの型定義
export interface UserData {
  uid: string;
  points: number;
  goldStamps: number;
  lastStampDate?: string;
  badges?: string[];
}

// 店舗データの型定義
export interface StoreData {
  storeId: string;
  name: string;
  staffIds: string[];
}

// スタンプ履歴の型定義
export interface StampHistory {
  id: string;
  userId: string;
  storeId: string;
  staffId: string;
  timestamp: FirebaseFirestore.Timestamp;
  pointsEarned: number;
  jti: string;
} 