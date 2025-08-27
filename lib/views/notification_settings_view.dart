 import 'package:flutter/material.dart';

 class NotificationSettingsView extends StatefulWidget {
   const NotificationSettingsView({super.key});

   @override
   State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
 }

 class _NotificationSettingsViewState extends State<NotificationSettingsView> {
   bool isNotificationsEnabled = true;
   bool isInAppEnabled = true;
   bool isPushEnabled = true;
   bool isEmailEnabled = false;

   bool isCategoryCampaign = true;
   bool isCategoryNews = true;
   bool isCategoryUpdates = true;

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           '通知設定',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
           ),
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
               _buildSectionHeader('全体'),
               _buildSwitchTile(
                 title: '通知を受け取る',
                 subtitle: 'アプリからの全ての通知を有効にします',
                 value: isNotificationsEnabled,
                 onChanged: (value) => setState(() {
                   isNotificationsEnabled = value ?? isNotificationsEnabled;
                 }),
               ),
               const Divider(height: 1),

               _buildSectionHeader('通知の種類'),
               _buildSwitchTile(
                 title: 'アプリ内通知',
                 value: isInAppEnabled,
                 onChanged: isNotificationsEnabled
                     ? (value) => setState(() => isInAppEnabled = value ?? isInAppEnabled)
                     : null,
               ),
               _buildSwitchTile(
                 title: 'プッシュ通知',
                 value: isPushEnabled,
                 onChanged: isNotificationsEnabled
                     ? (value) => setState(() => isPushEnabled = value ?? isPushEnabled)
                     : null,
               ),
               _buildSwitchTile(
                 title: 'メール通知',
                 value: isEmailEnabled,
                 onChanged: isNotificationsEnabled
                     ? (value) => setState(() => isEmailEnabled = value ?? isEmailEnabled)
                     : null,
               ),
               const Divider(height: 1),

               _buildSectionHeader('カテゴリ'),
               _buildCheckboxTile(
                 title: 'キャンペーン・クーポン',
                 value: isCategoryCampaign,
                 onChanged: isNotificationsEnabled
                     ? (value) => setState(() => isCategoryCampaign = value ?? isCategoryCampaign)
                     : null,
               ),
               _buildCheckboxTile(
                 title: 'お知らせ・ニュース',
                 value: isCategoryNews,
                 onChanged: isNotificationsEnabled
                     ? (value) => setState(() => isCategoryNews = value ?? isCategoryNews)
                     : null,
               ),
               _buildCheckboxTile(
                 title: 'アップデート情報',
                 value: isCategoryUpdates,
                 onChanged: isNotificationsEnabled
                     ? (value) => setState(() => isCategoryUpdates = value ?? isCategoryUpdates)
                     : null,
               ),

               const SizedBox(height: 16),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('通知設定を保存しました')),
                       );
                     },
                                         style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                     child: const Text(
                       '保存',
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                       ),
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
     required ValueChanged<bool?>? onChanged,
   }) {
     return ListTile(
       title: Text(
         title,
         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
       ),
       subtitle: subtitle != null ? Text(subtitle) : null,
             trailing: Switch(
        value: value,
        onChanged: onChanged == null ? null : (v) => onChanged(v),
        activeColor: const Color(0xFFFF6B35),
        activeTrackColor: const Color(0xFFFF6B35).withOpacity(0.5),
      ),
     );
   }

   Widget _buildCheckboxTile({
     required String title,
     required bool value,
     required ValueChanged<bool?>? onChanged,
   }) {
         return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      controlAffinity: ListTileControlAffinity.trailing,
      activeColor: const Color(0xFFFF6B35),
      checkColor: Colors.white,
    );
   }
 }
