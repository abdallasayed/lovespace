import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LinkPartnerScreen extends StatefulWidget {
  const LinkPartnerScreen({super.key});

  @override
  State<LinkPartnerScreen> createState() => _LinkPartnerScreenState();
}

class _LinkPartnerScreenState extends State<LinkPartnerScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendRequest() async {
    final myUser = FirebaseAuth.instance.currentUser!;
    final targetEmail = _emailController.text.trim();

    if (targetEmail.isEmpty || targetEmail == myUser.email) return;

    setState(() => _isLoading = true);
    try {
      // 1. البحث عن المستخدم الآخر
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: targetEmail)
          .get();

      if (query.docs.isEmpty) throw "لم يتم العثور على هذا البريد الإلكتروني";

      final targetUser = query.docs.first;
      
      if (targetUser['status'] != 'single') throw "المستخدم مشغول أو لديه طلب معلق";

      // 2. إرسال الطلب (تحديث الطرفين)
      final batch = FirebaseFirestore.instance.batch();

      // تحديث بياناتي
      batch.update(FirebaseFirestore.instance.collection('users').doc(myUser.uid), {
        'status': 'sent_request',
        'targetEmail': targetEmail,
      });

      // تحديث بيانات المستقبل
      batch.update(FirebaseFirestore.instance.collection('users').doc(targetUser.id), {
        'status': 'received_request',
        'incomingRequest': {
          'fromUid': myUser.uid,
          'fromEmail': myUser.email,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      await batch.commit();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("البحث عن نصفك الآخر"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 100, color: Colors.pinkAccent),
            const SizedBox(height: 30),
            const Text(
              "أدخل البريد الإلكتروني لشريكك\nلإرسال طلب ارتباط",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "إيميل المحبوب/ة",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _sendRequest,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text("إرسال طلب حب"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

