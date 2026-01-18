import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomingRequestScreen extends StatelessWidget {
  final Map<String, dynamic> senderData;
  
  const IncomingRequestScreen({super.key, required this.senderData});

  Future<void> _respond(bool accept) async {
    final myUser = FirebaseAuth.instance.currentUser!;
    final senderUid = senderData['fromUid'];
    final batch = FirebaseFirestore.instance.batch();

    if (accept) {
      // 1. إنشاء معرف موحد للكوبل (ترتيب الحروف أبجدياً)
      final List<String> ids = [myUser.uid, senderUid];
      ids.sort();
      final coupleId = "${ids[0]}_${ids[1]}";

      // 2. بيانات التحديث للطرفين
      final updateData = {
        'status': 'linked',
        'partnerId': coupleId,
        'linkedAt': FieldValue.serverTimestamp(),
        'incomingRequest': FieldValue.delete(),
        'targetEmail': FieldValue.delete(),
      };

      // تحديثي وتحديث الشريك
      batch.update(FirebaseFirestore.instance.collection('users').doc(myUser.uid), updateData);
      batch.update(FirebaseFirestore.instance.collection('users').doc(senderUid), updateData);
      
      // 3. إنشاء وثيقة الكوبل (الغرفة المشتركة)
      batch.set(FirebaseFirestore.instance.collection('couples').doc(coupleId), {
        'createdAt': FieldValue.serverTimestamp(),
        'users': ids,
      });

    } else {
      // الرفض: إعادة الطرفين لحالة single
      batch.update(FirebaseFirestore.instance.collection('users').doc(myUser.uid), {
        'status': 'single',
        'incomingRequest': FieldValue.delete()
      });
      batch.update(FirebaseFirestore.instance.collection('users').doc(senderUid), {
        'status': 'single',
        'targetEmail': FieldValue.delete() // نحذف التارجت من عند المرسل ليعلم أنه رُفض
      });
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE11D48), Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "لديك طلب ارتباط جديد! 💍",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "من: ${senderData['fromEmail']}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 50),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("موافقة 😍", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("رفض"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

