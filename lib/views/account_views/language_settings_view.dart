 import 'package:flutter/material.dart';

 class LanguageSettingsView extends StatefulWidget {
   const LanguageSettingsView({super.key});

   @override
   State<LanguageSettingsView> createState() => _LanguageSettingsViewState();
 }

 enum AppLanguage { system, japanese, english, chinese, korean }

 class _LanguageSettingsViewState extends State<LanguageSettingsView> {
   AppLanguage selected = AppLanguage.system;

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           '言語設定',
           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
         ),
         centerTitle: true,
         backgroundColor: Colors.white,
         elevation: 0,
       ),
       body: SafeArea(
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Padding(
               padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
               child: Text(
                 '表示言語',
                 style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
               ),
             ),
             _buildRadioTile(AppLanguage.system, '端末の設定に合わせる'),
             _buildRadioTile(AppLanguage.japanese, '日本語'),
             _buildRadioTile(AppLanguage.english, 'English'),
             _buildRadioTile(AppLanguage.chinese, '中文'),
             _buildRadioTile(AppLanguage.korean, '한국어'),
             const Spacer(),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
               child: SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('言語設定を保存しました')),
                     );
                     Navigator.of(context).pop();
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF1E88E5),
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 14),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                 ),
               ),
             ),
           ],
         ),
       ),
     );
   }

   Widget _buildRadioTile(AppLanguage value, String label) {
     return RadioListTile<AppLanguage>(
       value: value,
       groupValue: selected,
       onChanged: (v) => setState(() => selected = v ?? selected),
       title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
       controlAffinity: ListTileControlAffinity.trailing,
     );
   }
 }

