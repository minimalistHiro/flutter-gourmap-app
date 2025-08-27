 import 'package:flutter/material.dart';

 class PrivacyPolicyView extends StatelessWidget {
   const PrivacyPolicyView({super.key});

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           'プライバシーポリシー',
           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
         ),
         centerTitle: true,
         backgroundColor: Colors.white,
         elevation: 0,
       ),
       body: SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _buildHeader('1. 収集する情報'),
               _buildParagraph('当社は、アカウント作成やサービス利用時に、氏名、メールアドレス、利用履歴等を取得する場合があります。'),

               _buildHeader('2. 利用目的'),
               _buildList([
                 'サービス提供および改善のため',
                 'お知らせや重要な通知の配信のため',
                 '不正行為の防止および安全性の確保のため',
               ]),

               _buildHeader('3. 第三者提供'),
               _buildParagraph('法令に基づく場合を除き、本人の同意なしに第三者へ提供することはありません。'),

               _buildHeader('4. クッキー（Cookie）等の利用'),
               _buildParagraph('利便性向上のため、クッキー等を利用する場合があります。ブラウザ設定により無効化できます。'),

               _buildHeader('5. 開示・訂正・削除'),
               _buildParagraph('ご本人からのお問い合わせにより、保有個人データの開示・訂正・削除に対応します。'),

               const SizedBox(height: 24),
               const Text(
                 '最終更新日: 2025-04-01',
                 style: TextStyle(color: Colors.grey, fontSize: 12),
               ),
             ],
           ),
         ),
       ),
     );
   }

   Widget _buildHeader(String text) {
     return Padding(
       padding: const EdgeInsets.only(top: 12, bottom: 6),
       child: Text(
         text,
         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
       ),
     );
   }

   Widget _buildParagraph(String text) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 8),
       child: Text(
         text,
         style: const TextStyle(fontSize: 14, height: 1.6),
       ),
     );
   }

   Widget _buildList(List<String> items) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: items
           .map((e) => Padding(
                 padding: const EdgeInsets.only(bottom: 6),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('•  ', style: TextStyle(fontSize: 14)),
                     Expanded(
                       child: Text(
                         e,
                         style: const TextStyle(fontSize: 14, height: 1.6),
                       ),
                     ),
                   ],
                 ),
               ))
           .toList(),
     );
   }
 }

