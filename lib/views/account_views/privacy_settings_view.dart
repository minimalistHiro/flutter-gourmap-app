 import 'package:flutter/material.dart';

 class PrivacySettingsView extends StatefulWidget {
   const PrivacySettingsView({super.key});

   @override
   State<PrivacySettingsView> createState() => _PrivacySettingsViewState();
 }

 class _PrivacySettingsViewState extends State<PrivacySettingsView> {
   bool personalizedAds = false;
   bool analyticsSharing = true;
   bool crashReports = true;
   bool marketingEmails = false;

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           'プライバシー設定',
           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
         ),
         centerTitle: true,
         backgroundColor: Colors.white,
         elevation: 0,
       ),
       body: SafeArea(
         child: SingleChildScrollView(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _buildSectionHeader('データと分析'),
               _buildSwitchTile(
                 title: '匿名の使用状況データを共有',
                 subtitle: 'アプリ改善のための統計情報を匿名で送信します',
                 value: analyticsSharing,
                 onChanged: (v) => setState(() => analyticsSharing = v ?? analyticsSharing),
               ),
               _buildSwitchTile(
                 title: 'クラッシュレポートを送信',
                 subtitle: '問題発生時のレポートを送信し品質向上に協力します',
                 value: crashReports,
                 onChanged: (v) => setState(() => crashReports = v ?? crashReports),
               ),

               const Divider(height: 1),
               _buildSectionHeader('広告'),
               _buildSwitchTile(
                 title: 'パーソナライズド広告',
                 subtitle: '興味・関心に基づいた広告を表示します',
                 value: personalizedAds,
                 onChanged: (v) => setState(() => personalizedAds = v ?? personalizedAds),
               ),

               const Divider(height: 1),
               _buildSectionHeader('連絡設定'),
               _buildSwitchTile(
                 title: 'マーケティングメールを受け取る',
                 value: marketingEmails,
                 onChanged: (v) => setState(() => marketingEmails = v ?? marketingEmails),
               ),

               const SizedBox(height: 16),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('プライバシー設定を保存しました')),
                       );
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF1E88E5),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                     child: const Text(
                       '保存',
                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                     ),
                   ),
                 ),
               ),
               const SizedBox(height: 24),
             ],
           ),
         ),
       ),
     );
   }

   Widget _buildSectionHeader(String title) {
     return Padding(
       padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
       child: Text(
         title,
         style: const TextStyle(
           fontSize: 13,
           color: Colors.grey,
           fontWeight: FontWeight.w600,
         ),
       ),
     );
   }

   Widget _buildSwitchTile({
     required String title,
     String? subtitle,
     required bool value,
     required ValueChanged<bool?> onChanged,
   }) {
     return ListTile(
       title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
       subtitle: subtitle != null ? Text(subtitle) : null,
       trailing: Switch(
         value: value,
         onChanged: (v) => onChanged(v),
       ),
     );
   }
 }

