import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../chat/screens/chat_screen.dart';
import '../../music/screens/music_screen.dart';
import '../../memories/screens/memories_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String coupleId;
  final DateTime linkedDate;

  const HomeScreen({
    super.key,
    required this.coupleId,
    required this.linkedDate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenForNotifications();
  }

  void _listenForNotifications() {
    FirebaseFirestore.instance
        .collection('couples')
        .doc(widget.coupleId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final currentUserId = FirebaseAuth.instance.currentUser!.uid;
        if (data['senderId'] != currentUserId) {
          final timeDiff = DateTime.now().difference((data['timestamp'] as Timestamp).toDate());
          if (timeDiff.inSeconds < 10) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("🔔 ${data['text']}"),
                backgroundColor: const Color(0xFFE11D48),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeTab(),
      ChatScreen(coupleId: widget.coupleId),
      MusicScreen(coupleId: widget.coupleId),
      MemoriesScreen(coupleId: widget.coupleId),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // لون خلفية هادئ
      body: Stack(
        children: [
          screens[_currentIndex],
          
          // الشريط السفلي
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(Icons.image_rounded, "ذكريات", 3),
                  _navItem(Icons.music_note_rounded, "موسيقى", 2),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFF9333EA)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.4), blurRadius: 15)],
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                  _navItem(Icons.chat_bubble_rounded, "محادثة", 1),
                  _navItem(Icons.settings_rounded, "إعدادات", 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFE11D48) : Colors.grey[400], size: 26),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFFE11D48) : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final days = DateTime.now().difference(widget.linkedDate).inDays;
    return SingleChildScrollView(
      // إضافة حشوة سفلية لكي لا يغطي الشريط المحتوى
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          // الهيدر الأحمر
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 50),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFbe123c)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              children: [
                const Text("قصة حبنا ❤️", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _counterItem("$days", "يوماً معاً"),
                    Container(height: 40, width: 1, color: Colors.white30),
                    _counterItem("∞", "إلى الأبد"),
                  ],
                ),
              ],
            ),
          ),
          
          // زر النكز (يظهر الآن بوضوح لأنه خارج الهيدر)
          Transform.translate(
            offset: const Offset(0, -30), // رفعه قليلاً ليتداخل مع الهيدر بشكل جميل
            child: GestureDetector(
              onTap: () {
                 FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notifications').add({
                   'text': "أنا مشتاق لك! 😍", 'senderId': FirebaseAuth.instance.currentUser!.uid, 'timestamp': FieldValue.serverTimestamp()
                 });
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال شوقك!")));
              },
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 50, color: Color(0xFFE11D48)),
                    SizedBox(height: 5),
                    Text("اشتقت لك", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          const Text("اضغط الزر لإرسال إشعار لحبيبك", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _counterItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}

