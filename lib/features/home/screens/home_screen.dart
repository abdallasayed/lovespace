import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../chat/screens/chat_screen.dart';
import '../../music/screens/music_screen.dart';
import '../../memories/screens/memories_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String coupleId;
  final DateTime linkedDate;

  const HomeScreen({super.key, required this.coupleId, required this.linkedDate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildModernDashboard(),
      ChatScreen(coupleId: widget.coupleId),
      MusicScreen(coupleId: widget.coupleId),
      MemoriesScreen(coupleId: widget.coupleId),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8), // خلفية رمادية فاتحة جداً وعصرية
      body: screens[_currentIndex],
      bottomNavigationBar: _buildModernNavBar(),
    );
  }

  Widget _buildModernNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.grid_view_rounded, 0),
          _navItem(Icons.chat_bubble_outline_rounded, 1),
          _navItem(Icons.music_note_rounded, 2),
          _navItem(Icons.image_outlined, 3),
          _navItem(Icons.settings_outlined, 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE11D48) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[400],
          size: 26,
        ),
      ),
    );
  }

  Widget _buildModernDashboard() {
    final days = DateTime.now().difference(widget.linkedDate).inDays;

    return SingleChildScrollView(
      child: Column(
        children: [
          // الهيدر الكبير
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFFF6B6B)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "قصة حبنا",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$days",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, right: 10),
                        child: Text(
                          "يوماً",
                          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("معاً إلى الأبد ∞", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),

          // زر النكز بتصميم جديد
          GestureDetector(
            onTap: _sendLovePing,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_rounded, size: 60, color: Color(0xFFE11D48)),
                  const SizedBox(height: 5),
                  Text("اشتقت لك", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendLovePing() {
    FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).collection('notifications').add({
      'text': "أنا مشتاق لك! 😍",
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("وصلت مشاعرك! ❤️")));
  }
}

