 import 'package:flutter/material.dart';

 class ContactView extends StatefulWidget {
   const ContactView({super.key});

   @override
   State<ContactView> createState() => _ContactViewState();
 }

 class _ContactViewState extends State<ContactView> {
   final _formKey = GlobalKey<FormState>();
   final TextEditingController _nameController = TextEditingController();
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _subjectController = TextEditingController();
   final TextEditingController _messageController = TextEditingController();

   String _category = 'その他';
   final List<String> _categories = ['バグ報告', '機能要望', 'アカウント', 'その他'];

   @override
   void dispose() {
     _nameController.dispose();
     _emailController.dispose();
     _subjectController.dispose();
     _messageController.dispose();
     super.dispose();
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           'お問い合わせ',
           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
         ),
         centerTitle: true,
         backgroundColor: Colors.white,
         elevation: 0,
       ),
       body: SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(16),
           child: Form(
             key: _formKey,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildTextField(
                   controller: _nameController,
                   label: 'お名前（任意）',
                   hint: '山田 太郎',
                   validator: null,
                 ),
                 const SizedBox(height: 12),
                 _buildTextField(
                   controller: _emailController,
                   label: 'メールアドレス（任意）',
                   hint: 'example@domain.com',
                   keyboardType: TextInputType.emailAddress,
                 validator: (v) {
                   if (v == null || v.isEmpty) return null;
                   final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                   if (!emailRegex.hasMatch(v)) {
                     return '正しいメールアドレスを入力してください';
                   }
                   return null;
                 },
                 ),
                 const SizedBox(height: 12),
                 _buildTextField(
                   controller: _subjectController,
                   label: '件名',
                   hint: 'お問い合わせの件名',
                   validator: (v) => (v == null || v.trim().isEmpty) ? '件名を入力してください' : null,
                 ),
                 const SizedBox(height: 12),
                 _buildDropdown(),
                 const SizedBox(height: 12),
                 _buildTextField(
                   controller: _messageController,
                   label: 'お問い合わせ内容',
                   hint: 'できるだけ詳しくご記入ください',
                   maxLines: 8,
                   validator: (v) => (v == null || v.trim().isEmpty) ? 'お問い合わせ内容を入力してください' : null,
                 ),
                 const SizedBox(height: 20),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: _submit,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF1E88E5),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: const Text('送信', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }

   Widget _buildDropdown() {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey.shade300),
       ),
       child: DropdownButtonHideUnderline(
         child: DropdownButton<String>(
           isExpanded: true,
           value: _category,
           items: _categories
               .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
               .toList(),
           onChanged: (v) => setState(() => _category = v ?? _category),
         ),
       ),
     );
   }

   Widget _buildTextField({
     required TextEditingController controller,
     required String label,
     required String hint,
     int maxLines = 1,
     TextInputType keyboardType = TextInputType.text,
     String? Function(String?)? validator,
   }) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
         const SizedBox(height: 6),
         TextFormField(
           controller: controller,
           maxLines: maxLines,
           keyboardType: keyboardType,
           validator: validator,
           decoration: InputDecoration(
             hintText: hint,
             filled: true,
             fillColor: Colors.white,
             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
             border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide(color: Colors.grey.shade300),
             ),
             enabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide(color: Colors.grey.shade300),
             ),
           ),
         ),
       ],
     );
   }

   void _submit() {
     if (!(_formKey.currentState?.validate() ?? false)) return;
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('お問い合わせを送信しました')),
     );
     Navigator.of(context).pop();
   }
 }

