 import 'package:flutter/material.dart';

 class TermsView extends StatelessWidget {
   const TermsView({super.key});

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           '利用規約',
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
               _buildHeader('第1条（適用）'),
               _buildParagraph('本規約は、ユーザーが本アプリを利用する際の一切の行為に適用されます。'),

               _buildHeader('第2条（禁止事項）'),
               _buildList([
                 '法令または公序良俗に違反する行為',
                 '第三者の権利を侵害する行為',
                 '本アプリの運営を妨害する行為',
               ]),

               _buildHeader('第3条（免責事項）'),
               _buildParagraph('本アプリの利用により生じた損害について、運営は一切の責任を負わないものとします。'),

               _buildHeader('第4条（規約の変更）'),
               _buildParagraph('当社は、必要と判断した場合、ユーザーに通知することなく本規約を変更できるものとします。'),

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

