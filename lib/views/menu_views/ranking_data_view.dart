import 'package:flutter/material.dart';

class RankingDataView extends StatefulWidget {
  final String category;
  final String unit;

  const RankingDataView({
    super.key,
    required this.category,
    required this.unit,
  });

  @override
  State<RankingDataView> createState() => _RankingDataViewState();
}

class _RankingDataViewState extends State<RankingDataView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFACD),
      appBar: AppBar(
        title: Text(
          '${widget.category}ランキング',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFACD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ランキングリスト
            ...List.generate(10, (index) {
              return _buildRankingItem(
                rank: index + 1,
                name: 'ユーザー${index + 1}',
                value: (1000 - index * 50).toString(),
                isCurrentUser: index == 2, // 3位が現在のユーザー
              );
            }),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String name,
    required String value,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue[100] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isCurrentUser ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Row(
        children: [
          // 順位
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 15),
          
          // ユーザー名
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 値
          Text(
            '$value${widget.unit}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
} 