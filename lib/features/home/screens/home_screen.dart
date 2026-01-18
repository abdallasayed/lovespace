import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// استدعاء الشاشات (تم التأكد من المسارات)
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
      body: Stack(
        children: [
          screens[_currentIndex],
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFbe123c)]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              children: [
                const Text("قصة حبنا ❤️", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [Text("$days", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), const Text("يوماً معاً", style: TextStyle(color: Colors.white70))]),
                      const Icon(Icons.favorite, color: Colors.white, size: 40),
                      Column(children: [const Text("∞", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), const Text("إلى الأبد", style: TextStyle(color: Colors.white70))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () {
               FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notifications').add({
                 'text': "أنا مشتاق لك! 😍", 'senderId': FirebaseAuth.instance.currentUser!.uid, 'timestamp': FieldValue.serverTimestamp()
               });
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال شوقك!")));
            },
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(color: Colors.pink[50], shape: BoxShape.circle),
              child: const Icon(Icons.touch_app_rounded, size: 60, color: Colors.pink),
            ),
          ),
        ],
      ),
    );
  }
}

