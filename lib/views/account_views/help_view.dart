 import 'package:flutter/material.dart';

 class HelpView extends StatelessWidget {
   const HelpView({super.key});

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           'ヘルプ',
           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
         ),
         centerTitle: true,
         backgroundColor: Colors.white,
         elevation: 0,
       ),
       body: SafeArea(
         child: ListView(
           padding: const EdgeInsets.all(16),
           children: [
             _buildCard(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: const [
                   Text('よくある質問', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   SizedBox(height: 12),
                 ],
               ),
             ),
             _buildFaqItem('アカウントを作成するには？', 'ホーム画面から「新規会員登録」→メール/Apple/Google を選択して手順に従ってください。'),
             _buildFaqItem('パスワードを忘れた場合', 'ログイン画面の「パスワードをお忘れですか？」から再設定を行ってください。'),
             _buildFaqItem('ポイントはどこで確認できますか？', 'ホーム画面の「ポイント」メニュー、またはQRコード画面の「保有ポイント」から確認できます。'),
             _buildFaqItem('通知をオフにしたい', '「アカウント」→「通知設定」から各種通知のON/OFFを切り替えできます。'),
 
             const SizedBox(height: 20),
             _buildCard(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: const [
                   Text('お問い合わせ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   SizedBox(height: 8),
                   Text('サポートが必要な場合は、以下のいずれかの方法でご連絡ください。', style: TextStyle(color: Colors.grey)),
                 ],
               ),
             ),
             ListTile(
               leading: const Icon(Icons.email_outlined),
               title: const Text('メールで問い合わせる'),
               subtitle: const Text('support@gourmap.example'),
               onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('メールアプリを開きます（ダミー）')),
                 );
               },
             ),
             ListTile(
               leading: const Icon(Icons.article_outlined),
               title: const Text('利用規約 / プライバシー'),
               subtitle: const Text('規約ページを表示します（ダミー）'),
               onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('規約ページを開きます（ダミー）')),
                 );
               },
             ),
           ],
         ),
       ),
     );
   }

   Widget _buildCard({required Widget child}) {
     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         boxShadow: [
           BoxShadow(
             color: Colors.grey.withOpacity(0.08),
             blurRadius: 6,
             offset: const Offset(0, 2),
           ),
         ],
       ),
       child: child,
     );
   }

   Widget _buildFaqItem(String question, String answer) {
     return Container(
       margin: const EdgeInsets.only(bottom: 8),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         boxShadow: [
           BoxShadow(
             color: Colors.grey.withOpacity(0.06),
             blurRadius: 6,
             offset: const Offset(0, 2),
           ),
         ],
       ),
       child: ExpansionTile(
         title: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
         childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
         children: [
           Align(
             alignment: Alignment.centerLeft,
             child: Text(
               answer,
               style: const TextStyle(color: Colors.grey, height: 1.4),
             ),
           ),
         ],
       ),
     );
   }
 }

