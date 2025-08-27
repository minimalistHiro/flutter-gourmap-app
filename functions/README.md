# GourMap Firebase Functions

## 概要
GourMapアプリのポイント交換システムを管理するFirebase Functionsです。

## 機能

### 1. issueUserQr
- **目的**: ユーザーQRコードトークンを発行
- **認証**: 必須（Firebase Auth）
- **戻り値**: HS256の短命JWT（60秒有効）
- **特徴**: 
  - `aud=groumap:redeem`
  - `sub=userId`
  - `jti`（ワンタイム用のユニークID）

### 2. redeemPoints
- **目的**: ポイント交換処理
- **認証**: 必須（スタッフ権限）
- **処理内容**:
  - スタッフ権限検証
  - JWT検証 + jtiのワンタイム消費
  - 1日1スタンプ制限
  - ポイント計算（1スタンプ = 10ポイント）
  - バッジ判定
  - トランザクション処理

## セキュリティ

### JWT設定
- アルゴリズム: HS256
- 有効期限: 60秒
- 対象: `groumap:redeem`
- ワンタイム: jtiによる重複使用防止

### 権限管理
- 書き込み: サーバーのみ
- 店舗スタッフ: 通知作成等の限定書き込みのみ
- スタッフ権限: 店舗ごとの権限検証

## データベース構造

### users コレクション
```typescript
{
  uid: string;
  points: number;
  goldStamps: number;
  lastStampDate?: string;
  badges?: string[];
  updatedAt: Timestamp;
}
```

### stamp_history コレクション
```typescript
{
  id: string;
  userId: string;
  storeId: string;
  staffId: string;
  timestamp: Timestamp;
  pointsEarned: number;
  jti: string;
}
```

### stores コレクション
```typescript
{
  storeId: string;
  name: string;
  staffIds: string[];
}
```

## バッジシステム

| スタンプ数 | バッジ名 |
|------------|----------|
| 1 | 初回スタンプ |
| 5 | スタンプ5個達成 |
| 10 | スタンプ10個達成 |
| 20 | スタンプ20個達成 |
| 50 | スタンプ50個達成 |
| 100 | スタンプ100個達成 |

## セットアップ

### 1. 依存関係のインストール
```bash
cd functions
npm install
```

### 2. 環境変数の設定
```bash
cp env.example .env
# .envファイルを編集してJWT_SECRETを設定
```

### 3. ビルド
```bash
npm run build
```

### 4. デプロイ
```bash
npm run deploy
```

## 使用方法

### Flutter側での呼び出し例

#### QRトークン発行
```dart
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('issueUserQr').call();
```

#### ポイント交換
```dart
final result = await functions.httpsCallable('redeemPoints').call({
  'qrToken': qrToken,
  'storeId': storeId,
  'staffId': staffId,
});
```

## エラーハンドリング

### 共通エラー
- `認証が必要です`: Firebase Authが未認証
- `無効なQRトークンです`: JWT検証失敗
- `このQRコードは既に使用済みです`: jti重複使用

### redeemPoints固有エラー
- `この店舗でのスタンプ発行権限がありません`: スタッフ権限不足
- `今日は既にスタンプを獲得済みです`: 1日1スタンプ制限
- `ユーザーが見つかりません`: ユーザーデータ不存在

## 注意事項

1. **JWT_SECRET**: 本番環境では必ず変更してください
2. **権限管理**: Firestoreルールで書き込みをサーバーのみに制限
3. **トランザクション**: データ整合性を保つため必須
4. **ログ**: 本番環境では適切なログレベルを設定 